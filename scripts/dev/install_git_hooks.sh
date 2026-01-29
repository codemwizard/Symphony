#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

mkdir -p .git/hooks

cat > .git/hooks/pre-commit <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

scripts/audit/preflight_structural_staged.sh
HOOK

chmod +x .git/hooks/pre-commit
echo "✅ Installed pre-commit hook: scripts/audit/preflight_structural_staged.sh"

cat > .git/hooks/pre-push <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail

scripts/dev/pre_ci.sh
HOOK

chmod +x .git/hooks/pre-push
echo "✅ Installed pre-push hook: scripts/dev/pre_ci.sh"
