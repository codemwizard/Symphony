#!/usr/bin/env python3
import hashlib
import json
import os
import secrets
import subprocess
import urllib.parse
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer

DATABASE_URL = os.environ.get("DATABASE_URL", "")
if not DATABASE_URL:
    raise SystemExit("DATABASE_URL is required")


def psql_scalar(sql: str) -> str:
    out = subprocess.check_output(
        ["psql", DATABASE_URL, "-X", "-A", "-t", "-v", "ON_ERROR_STOP=1", "-c", sql],
        text=True,
        stderr=subprocess.STDOUT,
    )
    return out.strip()


def psql_json_array(sql: str):
    out = psql_scalar(sql)
    if not out:
        return []
    return json.loads(out)


class Handler(BaseHTTPRequestHandler):
    def _json(self, code: int, payload: dict):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json(self):
        n = int(self.headers.get("Content-Length", "0"))
        if n <= 0:
            return {}
        return json.loads(self.rfile.read(n).decode("utf-8"))

    def do_POST(self):
        if self.path == "/v1/admin/supervisor/audit-token":
            self.handle_create_audit_token()
            return

        if self.path.startswith("/v1/admin/supervisor/approve/"):
            instruction_id = self.path.split("/approve/", 1)[1]
            self.handle_approve(instruction_id)
            return

        self._json(404, {"error": "NOT_FOUND"})

    def do_DELETE(self):
        if self.path.startswith("/v1/admin/supervisor/audit-token/"):
            token_id = self.path.split("/audit-token/", 1)[1]
            return self.handle_revoke_audit_token(token_id)
        self._json(404, {"error": "NOT_FOUND"})

    def do_GET(self):
        if self.path.startswith("/v1/admin/supervisor/audit-records"):
            return self.handle_audit_records()
        self._json(404, {"error": "NOT_FOUND"})

    def handle_create_audit_token(self):
        body = self._read_json()
        program_id = body.get("program_id")
        issued_by = (body.get("issued_by") or "system").strip() or "system"
        ttl_seconds = int(body.get("ttl_seconds") or 86400)
        if not program_id:
            return self._json(400, {"error": "PROGRAM_ID_REQUIRED"})
        if ttl_seconds <= 0:
            return self._json(400, {"error": "INVALID_TTL"})

        token_plain = secrets.token_urlsafe(32)
        token_hash = hashlib.sha256(token_plain.encode("utf-8")).hexdigest()

        row = psql_scalar(
            "WITH ins AS ("
            "INSERT INTO public.supervisor_audit_tokens(program_id, token_hash, issued_by, expires_at) "
            f"VALUES ('{program_id}'::uuid, '{token_hash}', '{issued_by}', NOW() + make_interval(secs => {ttl_seconds})) "
            "RETURNING token_id::text, expires_at"
            ") "
            "SELECT row_to_json(ins)::text FROM ins;"
        )
        token_row = json.loads(row)
        token_row["token"] = token_plain
        return self._json(201, token_row)

    def handle_revoke_audit_token(self, token_id: str):
        affected = psql_scalar(
            "WITH upd AS ("
            "UPDATE public.supervisor_audit_tokens SET revoked_at = COALESCE(revoked_at, NOW()) "
            f"WHERE token_id = '{token_id}'::uuid RETURNING 1"
            ") SELECT count(*)::text FROM upd;"
        )
        if affected == "0":
            return self._json(404, {"error": "TOKEN_NOT_FOUND"})
        return self._json(200, {"status": "revoked", "token_id": token_id})

    def handle_audit_records(self):
        q = urllib.parse.urlparse(self.path)
        params = urllib.parse.parse_qs(q.query)
        token = (params.get("token") or [""])[0]
        if not token:
            return self._json(401, {"error": "TOKEN_REQUIRED"})

        token_hash = hashlib.sha256(token.encode("utf-8")).hexdigest()
        row = psql_scalar(
            "SELECT row_to_json(t)::text FROM ("
            "SELECT token_id::text, program_id::text, expires_at, revoked_at "
            "FROM public.supervisor_audit_tokens "
            f"WHERE token_hash = '{token_hash}'"
            ") t;"
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
        records = psql_json_array(
            "WITH src AS ("
            "SELECT tenant_id::text, member_id::text, instruction_id, event_type, observed_at "
            "FROM public.supervisor_audit_member_device_events "
            f"WHERE program_id = '{program_id}'::uuid"
            "), anon AS ("
            "SELECT tenant_id, encode(digest(member_id, 'sha256'),'hex') AS anonymized_member_id, "
            "instruction_id, event_type, observed_at "
            "FROM src"
            ") "
            "SELECT COALESCE(json_agg(row_to_json(anon)), '[]'::json)::text FROM anon;"
        )

        return self._json(200, {"program_id": program_id, "records": records})

    def handle_approve(self, instruction_id: str):
        body = self._read_json()
        actor = (body.get("approved_by") or self.headers.get("X-Supervisor-Actor") or "").strip()
        reason = body.get("reason")
        if not actor:
            return self._json(400, {"error": "APPROVER_REQUIRED"})

        try:
            psql_scalar(
                "SELECT public.decide_supervisor_approval("
                f"'{instruction_id}', 'APPROVED', '{actor}', "
                + ("NULL" if reason is None else f"'{reason}'")
                + ");"
            )
        except subprocess.CalledProcessError as exc:
            msg = (exc.output or "").strip()
            if "self approval is not permitted" in msg:
                return self._json(403, {"error": "SELF_APPROVAL_FORBIDDEN"})
            if "not pending supervisor approval" in msg:
                return self._json(409, {"error": "NOT_PENDING"})
            return self._json(500, {"error": "APPROVAL_FAILED", "detail": msg})

        return self._json(200, {"instruction_id": instruction_id, "status": "APPROVED", "approved_by": actor})


def main():
    port = int(os.environ.get("SUPERVISOR_API_PORT", "18080"))
    server = HTTPServer(("127.0.0.1", port), Handler)
    print(f"supervisor_api_listening:{port}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
