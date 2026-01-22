-- Seed initial policy version (ACTIVE status)
INSERT INTO policy_versions (id, description, status, activated_at)
VALUES ('v1.0.0', 'Initial Policy Version', 'ACTIVE', NOW())
ON CONFLICT (id) DO UPDATE SET status = 'ACTIVE', activated_at = NOW();

