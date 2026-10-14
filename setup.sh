#!/bin/sh
set -e
cd "$(dirname "$0")"

if [ ! -d .git ]; then
  git init -q -b main
fi

if [ ! -f .clash/owners ]; then
  mkdir -p .clash src/server/core src/server/progression src/client src/shared
  for d in src/server/core src/server/progression src/client src/shared; do
    touch "$d/.gitkeep"
  done

  cat > .clash/owners <<'OWNERS'
A src/server/core/
B src/server/progression/
C src/client/
A src/shared/
OWNERS

  cat > default.project.json <<'ROJO'
{
  "name": "GrowASynagogue",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "Shared": { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "Client": { "$path": "src/client" }
      }
    }
  }
}
ROJO

  cat > .gitignore <<'IGNORE'
.DS_Store
sourcemap.json
*.rbxl.lock
.env
IGNORE

  cat > CLAUDE.md <<'RULES'
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
- The currency is community points, never money.
- Treat religious items and holidays with respect. No caricatures and no jokes built on stereotypes.
- Run bash claim.sh followed by a short description before starting a big task so the team sees it in Discord.
RULES

  cat > claim.sh <<'CLAIM'
#!/bin/sh
url=$(git config --local clash.webhook)
role=$(git config --local clash.role)
name=$(git config user.name)
text=$(echo "$*" | tr -d '"\\')
if [ -z "$text" ]; then
  echo "Usage: bash claim.sh what you are working on"
  exit 1
fi
if [ -z "$url" ]; then
  echo "No webhook set. Run: bash setup.sh"
  exit 1
fi
curl -s -m 5 -H "Content-Type: application/json" -d "{\"content\":\"[$role] $name is taking: $text\"}" "$url" >/dev/null 2>&1
echo "Posted to Discord."
CLAIM

  echo "Project layout created. Commit and push it so teammates can clone it."
fi

printf "Your role (A, B or C): "
read -r role
role=$(echo "$role" | tr 'a-z' 'A-Z')
case "$role" in
  A|B|C) ;;
  *) echo "Pick A, B or C."; exit 1 ;;
esac
git config --local clash.role "$role"
git config --local pull.rebase true

printf "Discord webhook URL (paste it, or press enter to skip): "
read -r url
if [ -n "$url" ]; then
  git config --local clash.webhook "$url"
fi

hooks=$(git rev-parse --git-path hooks)
mkdir -p "$hooks"

cat > "$hooks/pre-commit" <<'PRECOMMIT'
#!/bin/sh
root=$(git rev-parse --show-toplevel)
owners="$root/.clash/owners"
role=$(git config --local clash.role)
if [ -z "$role" ]; then
  echo "No role set. Run: bash setup.sh"
  exit 1
fi
if [ ! -f "$owners" ]; then
  exit 0
fi
bad=$(git diff --cached --name-only --diff-filter=ACMRD | while IFS= read -r f; do
  case "$f" in
    (*/.gitkeep|.gitkeep) continue ;;
  esac
  matched=0
  allowed=0
  while read -r r p; do
    if [ -z "$r" ]; then
      continue
    fi
    case "$f" in
      ("$p"*)
        matched=1
        if [ "$r" = "$role" ]; then
          allowed=1
        fi
        ;;
    esac
  done < "$owners"
  if [ "$matched" = 0 ] && [ "$role" = "A" ]; then
    allowed=1
  fi
  if [ "$allowed" = 0 ]; then
    echo "$f"
  fi
done)
if [ -n "$bad" ]; then
  echo "Commit blocked. Role $role does not own these files:"
  echo "$bad"
  echo "Ask the owner in Discord. Do not bypass this hook."
  exit 1
fi
exit 0
PRECOMMIT

cat > "$hooks/post-commit" <<'POSTCOMMIT'
#!/bin/sh
url=$(git config --local clash.webhook)
role=$(git config --local clash.role)
name=$(git config user.name | tr -d '"\\')
if [ -z "$url" ]; then
  exit 0
fi
branch=$(git rev-parse --abbrev-ref HEAD)
msg=$(git log -1 --pretty=%s | tr -d '"\\')
curl -s -m 5 -H "Content-Type: application/json" -d "{\"content\":\"[$role] $name committed on $branch: $msg\"}" "$url" >/dev/null 2>&1 &
exit 0
POSTCOMMIT

cat > "$hooks/pre-push" <<'PREPUSH'
#!/bin/sh
while read -r lref lsha rref rsha; do
  case "$rref" in
    refs/heads/main|refs/heads/master)
      echo "Pushing to main is blocked. Push your branch and open a pull request."
      exit 1
      ;;
  esac
done
exit 0
PREPUSH

chmod +x "$hooks/pre-commit" "$hooks/post-commit" "$hooks/pre-push"

if ! command -v rojo >/dev/null 2>&1; then
  echo "Rojo is not installed. Get the CLI and the Studio plugin from rojo.space, then run: rojo serve"
fi

echo "Done. You are role $role."
