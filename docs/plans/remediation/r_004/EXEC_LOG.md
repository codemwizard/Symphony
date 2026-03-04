# R-004 EXEC_LOG

## actions_taken
- Rejected querystring `token` transport in API auth paths.
- Added bearer-token extraction and acceptance in auth checks.

## verification_commands_run
- bash scripts/audit/test_token_querystring_rejected.sh
- bash scripts/audit/test_authorization_bearer_accepted.sh

## final_status
- completed
