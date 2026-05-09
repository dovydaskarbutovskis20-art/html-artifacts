#!/usr/bin/env bash
# setup.sh — one-time push of html-artifacts to GitHub.
#
# What this does:
#   1. Initializes a git repo in this folder (if not already)
#   2. Stages everything, commits with a sensible message
#   3. (Optional) creates the repo on GitHub via `gh` CLI
#   4. Adds the remote and pushes main
#   5. (Optional) cuts a v0.1.0 release and uploads html-artifacts.skill as the asset
#
# Prerequisites:
#   - git installed
#   - For the optional repo-create + release steps: `gh` CLI installed and authenticated
#     (`brew install gh && gh auth login` on macOS)
#
# Usage:
#   chmod +x setup.sh
#   ./setup.sh
#
# Assumes your GitHub username is 'dogum'. Edit the GH_USER variable below if not.

set -euo pipefail

GH_USER="dogum"
REPO_NAME="html-artifacts"
RELEASE_TAG="v0.1.0"
RELEASE_TITLE="v0.1.0 — initial release"

cd "$(dirname "$0")"

echo "→ Initializing git (if needed)"
if [ ! -d .git ]; then
  git init -b main
fi

echo "→ Staging files"
git add .

if git diff --cached --quiet; then
  echo "  (nothing to commit — repo already in sync)"
else
  echo "→ Committing"
  git commit -m "Initial commit: html-artifacts skill + examples + GitHub Pages site

Operationalizes Thariq Shihipar's 'The Unreasonable Effectiveness of HTML'
as a Claude skill. Includes:
- skill/ folder with SKILL.md and 8 reference files
- html-artifacts.skill (packaged for upload to claude.ai)
- docs/ folder with GitHub Pages site and 6 live examples"
fi

if command -v gh >/dev/null 2>&1; then
  echo "→ Creating repo on GitHub (via gh CLI)"
  if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
    echo "  (repo already exists at github.com/$GH_USER/$REPO_NAME — skipping create)"
  else
    gh repo create "$GH_USER/$REPO_NAME" --public --source=. --remote=origin --push \
      --description "A Claude skill for producing self-contained HTML artifacts instead of markdown when the task warrants it."
  fi

  # If the remote wasn't added by `gh repo create` (e.g. repo already existed), add it now
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "git@github.com:$GH_USER/$REPO_NAME.git"
  fi

  echo "→ Pushing main"
  git push -u origin main || echo "  (push failed or already up to date)"

  echo "→ Cutting release $RELEASE_TAG with html-artifacts.skill as the asset"
  if gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
    echo "  (release $RELEASE_TAG already exists — skipping)"
  else
    gh release create "$RELEASE_TAG" \
      --title "$RELEASE_TITLE" \
      --notes "Initial release. Download \`html-artifacts.skill\` and upload it via Claude.ai → Settings → Capabilities → Skills." \
      html-artifacts.skill
  fi
else
  echo "→ \`gh\` CLI not found. Falling back to manual remote setup."
  echo
  echo "  Run these commands yourself:"
  echo "    1. Create the repo on GitHub: https://github.com/new (name it '$REPO_NAME')"
  echo "    2. git remote add origin git@github.com:$GH_USER/$REPO_NAME.git"
  echo "    3. git push -u origin main"
  echo "    4. (optional) Create a release on GitHub and attach html-artifacts.skill"
fi

echo
echo "→ Enable GitHub Pages so the live examples site works:"
echo "    Settings → Pages → Source: Deploy from a branch"
echo "    Branch: main · Folder: /docs · Save"
echo "  Site will be at: https://$GH_USER.github.io/$REPO_NAME/"
echo
echo "✓ Done."
