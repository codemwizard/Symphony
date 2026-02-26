# TSK-P1-LED-002 Plan

failure_signature: P1.LED.002.RETENTION_ARCHIVE_RESTORE
origin_task_id: TSK-P1-LED-002

## repro_command
- bash scripts/audit/verify_led_002_retention_archive_restore.sh

## scope
- Implement retention archive and restore scripts for regulated classes.
- Add sandbox WORM posture declaration.
- Emit verifier-backed evidence for archive run, signature verification, and restore drill.

## implementation_steps
1. Add archive script that filters retention classes, writes signed JSONL, and records archive runs.
2. Add restore script that validates signature and restores to staging output.
3. Add sandbox object-lock config declaration for WORM enforcement posture.
4. Add task verifier and evidence generation/validation flow.

## verification_commands_run
- bash scripts/audit/verify_led_002_retention_archive_restore.sh
- python3 scripts/audit/validate_evidence.py --task TSK-P1-LED-002 --evidence evidence/phase1/led_002_retention_archive_restore.json
