---
name: rollout
description: Deploy the current work.
---

Shepherd the current change through to production using the context of the session. If there is no PR or it is unclear which PR we're working with, stop and explain.

Investigate unaddressed PR comments, get approval for fixing the ones that matter, and resolve all of them appropriately (fixed or dismissed).

Merge the PR if needed, but first confirm that all required checks have passed on the latest PR head and that there aren't unresolved inline review comments. Recheck after any fixes or updates; wait for pending checks and approvals, and address failing checks before merging. Do not bypass merge requirements.

Use the repository's deployment documentation and established procedure to deploy the change. Wait for the deployment to finish, then run the documented production health or smoke checks. If none are documented, use checks appropriate to the affected service or feature. If deployment or validation fails, investigate the root cause, take note of it somewhere durable, and follow the documented recovery procedure; if recovery is unclear, stop and report the failure and current production state.

Report success only after deployment and production validation pass. Summarize what was deployed and the evidence that it is healthy; if validation is unavailable, report that deployment remains unverified.
