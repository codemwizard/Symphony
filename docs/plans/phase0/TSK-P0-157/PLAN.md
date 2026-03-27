# TSK-P0-157 PLAN

failure_signature: PRECI.SCOPE.FILTERING.NOT_IMPLEMENTED
origin_task_id: TSK-P0-157
repro_command: bash scripts/dev/pre_ci.sh

## Problem Statement

The `scripts/audit/verify_task_meta_schema.sh` script accepts a `--scope` parameter but never implements the filtering logic. When `pre_ci.sh` runs with `--scope changed`, it processes ALL tasks in the repository, including legacy tasks that don't meet v2 meta schema standards, causing CI failures.

## Root Cause Analysis

1. **Parameter parsed but unused**: Line 40 in verify_task_meta_schema.sh parses `--scope` but the `$SCOPE` variable is never referenced
2. **Always processes all tasks**: Line 63 uses `find "$TASK_ROOT" -name "meta.yml"` which gets all tasks regardless of scope
3. **CI failure cascade**: pre_ci.sh fails because legacy tasks (TSK-HARD-*, TSK-P0-*) have v1 schema violations

## Solution Design

### Scope: `--scope planned`

**Why `planned` instead of `changed`:**
- Symphony uses status-based workflow, not git-based workflow
- Completed tasks are immutable and never edited
- Bug fixes create new tasks, don't mutate existing ones
- Only `status: planned` tasks need active verification

### Implementation Strategy

1. **Add scope filtering logic** before the existing task discovery loop
2. **Preserve single-task mode** (`--task` flag takes precedence)
3. **Use Python YAML parsing** to read task status efficiently
4. **Fail fast on invalid scopes** with clear error messages

## Implementation Steps

### Step 1: Add scope filtering function
```bash
filter_tasks_by_scope() {
  local scope="$1"
  shift
  local all_files=("$@")
  local filtered_files=()
  
  if [[ "$scope" == "planned" ]]; then
    for file in "${all_files[@]}"; do
      local status
      status=$(python3 -c "
import yaml
with open('$file') as f:
    d = yaml.safe_load(f)
print(d.get('status', ''))
" 2>/dev/null || echo "")
      
      if [[ "$status" == "planned" ]]; then
        filtered_files+=("$file")
      fi
    done
  else
    echo "ERROR: Unsupported scope '$scope'. Supported scopes: planned" >&2
    exit 1
  fi
  
  printf '%s\n' "${filtered_files[@]}"
}
```

### Step 2: Integrate into main logic
Replace the existing file discovery with scope-aware filtering:
```bash
if [[ -n "$TARGET_TASK" ]]; then
  FILES=("$TASK_ROOT/$TARGET_TASK/meta.yml")
else
  mapfile -t ALL_FILES < <(find "$TASK_ROOT" -name "meta.yml" | grep -v "_template" | sort)
  
  if [[ -n "$SCOPE" ]]; then
    mapfile -t FILES < <(filter_tasks_by_scope "$SCOPE" "${ALL_FILES[@]}")
  else
    FILES=("${ALL_FILES[@]}")
  fi
fi
```

### Step 3: Update help text and error handling
- Add `--scope SCOPE` to usage documentation
- Document supported scopes: `planned`
- Add examples for common usage patterns

## Verification Commands

1. **Test scope filtering works**:
   ```bash
   bash scripts/audit/verify_task_meta_schema.sh --scope planned --mode basic
   ```

2. **Test single-task mode preserved**:
   ```bash
   bash scripts/audit/verify_task_meta_schema.sh --task GF-W1-FRZ-001 --mode strict
   ```

3. **Test invalid scope handling**:
   ```bash
   bash scripts/audit/verify_task_meta_schema.sh --scope invalid
   ```

4. **Test pre_ci integration**:
   ```bash
   bash scripts/dev/pre_ci.sh
   ```

## Expected Outcomes

- ✅ `pre_ci.sh` runs successfully without legacy task failures
- ✅ Only `status: planned` tasks are verified when using `--scope planned`
- ✅ Single-task verification (`--task`) continues to work unchanged
- ✅ Clear error messages for invalid scope values
- ✅ Wave 1 implementation can proceed without CI blocking

## Risk Mitigation

- **Backward compatibility**: Single-task mode takes precedence over scope
- **Clear error handling**: Invalid scopes fail fast with helpful messages
- **Comprehensive testing**: Verify all modes work before integration

## Success Criteria

1. pre_ci.sh exits 0 with no legacy task violations
2. All 31 GF-W1 tasks pass verification when using --scope planned
3. Existing single-task workflows continue to work
4. Invalid scope values produce clear error messages
