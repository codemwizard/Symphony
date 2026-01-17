INSERT INTO policy_versions (id, description, active)
VALUES ('v1.0.0', 'Initial Policy Version', true)
ON CONFLICT (id) DO UPDATE SET active = true;
