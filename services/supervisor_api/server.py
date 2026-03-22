#!/usr/bin/env python3
import hashlib
import hmac
import json
import os
import secrets
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
import sys

import psycopg

DATABASE_URL = os.environ.get("DATABASE_URL", "")
if not DATABASE_URL:
    raise SystemExit("DATABASE_URL is required")

TEST_MODE = os.environ.get("SUPERVISOR_API_TEST_MODE", "") == "1"
ADMIN_API_KEY = (os.environ.get("ADMIN_API_KEY") or "").strip()
if not TEST_MODE and not ADMIN_API_KEY:
    raise SystemExit("ADMIN_API_KEY is required (set SUPERVISOR_API_TEST_MODE=1 for test environments)")


def fetch_one(query: str, params=()):
    with psycopg.connect(DATABASE_URL, autocommit=True) as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            return cur.fetchone()


def fetch_value(query: str, params=()):
    row = fetch_one(query, params)
    if row is None:
        return None
    return row[0]


class Handler(BaseHTTPRequestHandler):
    def _json(self, code: int, payload: dict):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        length = int(self.headers.get('Content-Length', 0))
        if length == 0:
            return {}
        try:
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except json.JSONDecodeError:
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "error": "MALFORMED_JSON",
                "detail": "Request body must be valid JSON."
            }).encode('utf-8'))
            return None
        except UnicodeDecodeError: # Keep original UnicodeDecodeError handling
            self.send_response(400)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "error": "MALFORMED_JSON",
                "detail": "Request body must be valid UTF-8."
            }).encode('utf-8'))
            return None

    def _check_admin_auth(self) -> bool:
        """Verify admin API key, required headers, and emit structured audit log."""
        tenant_id = (self.headers.get("X-Tenant-Id") or "").strip()
        role = (self.headers.get("X-Supervisor-Role") or "").strip()
        
        # Enforce presence of headers even in test mode
        if not tenant_id or role != "admin":
            return False

        # Check API key unless in test mode
        if not TEST_MODE:
            auth_header = (self.headers.get("Authorization") or "").strip()
            if not auth_header.startswith("Bearer "):
                return False
            provided = auth_header[7:]
            if not hmac.compare_digest(provided.encode("utf-8"), ADMIN_API_KEY.encode("utf-8")):
                return False

        # Emit structured audit log
        audit_entry = {
            "event": "SUPERVISOR_API_ACCESS",
            "timestamp_utc": datetime.now(timezone.utc).isoformat().replace('+00:00','Z'),
            "tenant_id": tenant_id,
            "role": role,
            "path": self.path,
            "method": self.command,
            "actor": self.headers.get("X-Supervisor-Actor", "unknown")
        }
        print(json.dumps(audit_entry), flush=True)
        return True


    def do_POST(self):
        if self.path == "/v1/admin/supervisor/audit-token":
            if not self._check_admin_auth():
                return self._json(401, {"error": "UNAUTHORIZED"})
            self.handle_create_audit_token()
            return

        if self.path.startswith("/v1/admin/supervisor/approve/"):
            if not self._check_admin_auth():
                return self._json(401, {"error": "UNAUTHORIZED"})
            instruction_id = self.path.split("/approve/", 1)[1]
            self.handle_approve(instruction_id)
            return

        self._json(404, {"error": "NOT_FOUND"})

    def do_DELETE(self):
        if self.path.startswith("/v1/admin/supervisor/audit-token/"):
            if not self._check_admin_auth():
                return self._json(401, {"error": "UNAUTHORIZED"})
            token_id = self.path.split("/audit-token/", 1)[1]
            return self.handle_revoke_audit_token(token_id)
        self._json(404, {"error": "NOT_FOUND"})

    def do_GET(self):
        if self.path.startswith("/v1/admin/supervisor/audit-records"):
            if not self._check_admin_auth():
                return self._json(401, {"error": "UNAUTHORIZED"})
            return self.handle_audit_records()
        self._json(404, {"error": "NOT_FOUND"})

    def handle_create_audit_token(self):
        # The instruction implies _check_admin_auth should handle its own response,
        # but the current _check_admin_auth returns a bool.
        # Keeping the original _json(401, ...) call for consistency with _check_admin_auth's current behavior.
        # The provided snippet for handle_create_audit_token also had a conflicting `if not self._check_admin_auth('POST', '/audit-token'): return`
        # which is not compatible with the current _check_admin_auth signature.
        # I will assume the `do_POST` check is sufficient for admin auth.

        body = self._read_json()
        if body is None: # _read_json now sends the error response if malformed
            return
        program_id = body.get("program_id")
        issued_by = (body.get("issued_by") or "system").strip() or "system"
        
        try:
            ttl_seconds = int(body.get("ttl_seconds") or 86400)
        except ValueError:
            return self._json(400, {"error": "INVALID_TTL", "detail": "ttl_seconds must be an integer"})

        if not program_id:
            return self._json(400, {"error": "PROGRAM_ID_REQUIRED"})
        if ttl_seconds <= 0:
            return self._json(400, {"error": "INVALID_TTL"})

        token_plain = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token_plain.encode("utf-8")).hexdigest()

        row = fetch_value(
            """
            WITH ins AS (
              INSERT INTO public.supervisor_audit_tokens(program_id, token_hash, issued_by, expires_at)
              VALUES (%s::uuid, %s, %s, NOW() + make_interval(secs => %s))
              RETURNING token_id::text, expires_at
            )
            SELECT row_to_json(ins)::text FROM ins;
            """,
            (program_id, token_hash, issued_by, ttl_seconds),
        )
        if not row:
            return self._json(500, {"error": "TOKEN_CREATE_FAILED"})
        token_row = json.loads(row)
        token_row["token"] = token_plain
        return self._json(201, token_row)

    def handle_revoke_audit_token(self, token_id: str):
        affected = fetch_value(
            """
            WITH upd AS (
              UPDATE public.supervisor_audit_tokens
                 SET revoked_at = COALESCE(revoked_at, NOW())
               WHERE token_id = %s::uuid
               RETURNING 1
            )
            SELECT count(*)::text FROM upd;
            """,
            (token_id,),
        )
        if affected == "0":
            return self._json(404, {"error": "TOKEN_NOT_FOUND"})
        return self._json(200, {"status": "revoked", "token_id": token_id})

    def handle_audit_records(self):
        auth_header = (self.headers.get("Authorization") or "").strip()
        if not auth_header.startswith("Bearer "):
            return self._json(401, {"error": "TOKEN_REQUIRED"})
        token = auth_header[7:]
        if not token:
            return self._json(401, {"error": "TOKEN_REQUIRED"})

        token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
        row = fetch_value(
            """
            SELECT row_to_json(t)::text
              FROM (
                    SELECT token_id::text, program_id::text, expires_at, revoked_at
                      FROM public.supervisor_audit_tokens
                     WHERE token_hash = %s
                   ) t;
            """,
            (token_hash,),
        )
        if not row:
            return self._json(401, {"error": "TOKEN_INVALID"})
        token_row = json.loads(row)
        if token_row.get("revoked_at") is not None:
            return self._json(401, {"error": "TOKEN_REVOKED"})

        expires_at = datetime.fromisoformat(token_row["expires_at"].replace("Z", "+00:00"))
        if expires_at <= datetime.now(timezone.utc):
            return self._json(401, {"error": "TOKEN_EXPIRED"})

        program_id = token_row["program_id"]
        records_raw = fetch_value(
            """
            WITH src AS (
              SELECT tenant_id::text, member_id::text, instruction_id, event_type, observed_at
                FROM public.supervisor_audit_member_device_events
               WHERE program_id = %s::uuid
            ), anon AS (
              SELECT tenant_id,
                     encode(digest(member_id, 'sha256'),'hex') AS anonymized_member_id,
                     instruction_id,
                     event_type,
                     observed_at
                FROM src
            )
            SELECT COALESCE(json_agg(row_to_json(anon)), '[]'::json)::text FROM anon;
            """,
            (program_id,),
        )
        records = json.loads(records_raw or "[]")

        return self._json(200, {"program_id": program_id, "records": records})

    def handle_approve(self, instruction_id: str):
        # Similar to handle_create_audit_token, assuming do_POST handles admin auth.
        body = self._read_json()
        if body is None: # _read_json now sends the error response if malformed
            return
        actor = (body.get("approved_by") or self.headers.get("X-Supervisor-Actor") or "").strip()
        reason = body.get("reason")
        if not actor:
            return self._json(400, {"error": "APPROVER_REQUIRED"})

        try:
            with psycopg.connect(DATABASE_URL) as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "SELECT public.decide_supervisor_approval(%s, 'APPROVED', %s, %s);",
                        (instruction_id, actor, reason)
                    )
                    conn.commit()
            return self._json(200, {"success": True})
        except psycopg.Error as e:
            print(f"DB Error in handle_approve: {e}", file=sys.stderr)
            if "self approval is not permitted" in str(e):
                return self._json(403, {"error": "SELF_APPROVAL_FORBIDDEN"})
            # The original code had a check for "not pending supervisor approval"
            # This needs to be re-added if the new SQL function can return such an error.
            # For now, assuming it's covered by a generic error or needs explicit handling.
            if "not pending supervisor approval" in str(e): # Re-adding specific check
                return self._json(409, {"error": "NOT_PENDING"})
            return self._json(500, {"error": "INTERNAL_SERVER_ERROR", "detail": "Database operation failed."})
        except Exception as e:
            print(f"Unexpected Error in handle_approve: {e}", file=sys.stderr)
            return self._json(500, {"error": "INTERNAL_SERVER_ERROR", "detail": "An unexpected error occurred."})


def main():
    port = int(os.environ.get("SUPERVISOR_API_PORT", "18080"))
    server = HTTPServer(("127.0.0.1", port), Handler)
    print(f"supervisor_api_listening:{port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
