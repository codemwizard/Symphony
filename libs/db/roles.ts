export const DB_ROLES = [
    'symphony_control',
    'symphony_ingest',
    'symphony_executor',
    'symphony_readonly',
    'symphony_auditor',
    'symphony_auth'
] as const;

export type DbRole = typeof DB_ROLES[number];

export function assertDbRole(role: string): DbRole {
    if ((DB_ROLES as readonly string[]).includes(role)) {
        return role as DbRole;
    }

    throw new Error(`Invalid DbRole: ${role}`);
}
