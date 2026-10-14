Project: Grow a Synagogue (Roblox, Luau, Rojo and Git)

Ownership is defined in .clash/owners. Role A owns src/server/core/ and src/shared/. Role B owns src/server/progression/. Role C owns src/client/. Only the lead (role A) edits files outside those folders.

Rules for every agent:
- Only edit files inside the folder owned by your human. Never touch another role's folder.
- If you need a change in someone else's folder, stop and tell the human to ask for it in Discord.
- Run git pull --rebase origin main before starting any task.
- Work on a branch, commit small, never push to main, open a pull request instead.
- If a commit is blocked by the pre-commit hook, do not use --no-verify. Tell the human instead.
- Never edit scripts inside Roblox Studio. Scripts live in this repo and sync through Rojo.
- All money and inventory logic runs on the server.
- No free text input from players anywhere.
- The currency is money.
- Treat religious items and holidays with respect. No caricatures and no jokes built on stereotypes.
- Run bash claim.sh followed by a short description before starting a big task so the team sees it in Discord.
