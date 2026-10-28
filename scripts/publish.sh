#!/usr/bin/env bash
# Publish the RelProof idea scaffold as a new private GitHub repository and create its issues.
# Requires git + GitHub CLI authenticated with `gh auth login`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
REPO="${REPO:-gqgs/relproof}"
VISIBILITY="${VISIBILITY:-private}"

command -v git >/dev/null || { echo 'Please install git.' >&2; exit 1; }
command -v gh >/dev/null || { echo 'Please install GitHub CLI (Arch: sudo pacman -S github-cli).' >&2; exit 1; }
gh auth status >/dev/null

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git init -b main
fi
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    git add README.md docs examples issues scripts .gitignore
    git commit -m "docs: capture RelProof MVP research plan"
fi

if ! gh repo view "$REPO" >/dev/null 2>&1; then
    echo "Creating $VISIBILITY repository $REPO"
    gh repo create "$REPO" "--$VISIBILITY" --source . --remote origin --push \
      --description "Python-like relational specifications with portable, verifiable implementations"
else
    echo "Repository $REPO already exists. Checking remote."
    if ! git remote get-url origin >/dev/null 2>&1; then
        git remote add origin "https://github.com/${REPO}.git"
    fi
    git push -u origin HEAD:main
fi

for label in "mvp:1F883D" "research:8957E5" "later:57606A"; do
    name="${label%:*}"
    color="${label#*:}"
    gh label create "$name" --repo "$REPO" --color "$color" --force >/dev/null
 done

for issue in issues/*.md; do
    title="$(head -n 1 "$issue" | sed 's/^# //')"
    case "$title" in
        \[MVP\]*) label=mvp ;;
        \[Research\]*) label=research ;;
        \[Later\]*) label=later ;;
        *) label=mvp ;;
    esac
    if gh issue list --repo "$REPO" --state all --limit 200 --json title --jq '.[].title' | grep -Fxq "$title"; then
        echo "Already exists: $title"
    else
        gh issue create --repo "$REPO" --title "$title" --body-file "$issue" --label "$label"
    fi
 done

echo "Published https://github.com/$REPO"
