# LAYER 2: verify_agent_conformance.sh ΓÇö Hash validation patch
# TARGET: scripts/audit/verify_agent_conformance.sh
# STATUS: NOT YET APPLIED. Apply this manually.
#
# INSTRUCTION:
# In the check_approval_metadata() function, find the block below
# labeled FIND THIS and replace it with the block labeled REPLACE WITH.
# Also ensure `import re` is present at the top of the embedded Python block.

# ΓöÇΓöÇ FIND THIS (exact text to locate) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

#     for field in ["ai_prompt_hash", "model_id"]:
#         if not data.get("ai", {}).get(field):
#             fail("CONFORMANCE_008_APPROVAL_METADATA_INVALID", f"Approval metadata missing ai.{field}")

# ΓöÇΓöÇ REPLACE WITH ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

#     ai = data.get("ai", {})
#
#     prompt_hash = ai.get("ai_prompt_hash", "").strip()
#     model_id = ai.get("model_id", "").strip()
#
#     if not prompt_hash:
#         fail("CONFORMANCE_008_APPROVAL_METADATA_INVALID",
#              "Missing ai.ai_prompt_hash")
#     elif not re.fullmatch(r"[a-f0-9]{64}", prompt_hash):
#         fail("CONFORMANCE_018_PROMPT_HASH_INVALID",
#              f"ai_prompt_hash must be a SHA256 hex string (64 lowercase hex chars). "
#              f"Got: '{prompt_hash}' (len={len(prompt_hash)}). "
#              f"Branch names and session IDs are not valid hashes.")
#
#     if not model_id:
#         fail("CONFORMANCE_008_APPROVAL_METADATA_INVALID",
#              "Missing ai.model_id")
#
#     branch = subprocess.check_output(
#         ["git", "rev-parse", "--abbrev-ref", "HEAD"], text=True
#     ).strip()
#     if branch == "main":
#         fail("CONFORMANCE_020_BRANCH_MAIN_FORBIDDEN",
#              "Agent conformance check run on 'main' branch is forbidden.")

# ΓöÇΓöÇ ALSO ENSURE ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
# At the top of the embedded Python block (near other imports), add:
#     import re
# if it is not already present.

# ΓöÇΓöÇ WHY THIS MATTERS ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
# Current state: ai_prompt_hash accepts any non-empty string.
# This allowed Gemini to submit "security-wave-1-runtime-integrity-children"
# (a branch name) as a hash, which passed conformance checks.
# After this patch: only valid 64-char lowercase SHA256 hex strings pass.
# New failure codes introduced:
#   CONFORMANCE_018_PROMPT_HASH_INVALID  ΓÇö format validation
#   CONFORMANCE_020_BRANCH_MAIN_FORBIDDEN ΓÇö branch guard
