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
