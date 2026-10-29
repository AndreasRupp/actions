#!/usr/bin/env bash

####################################################################################################
# Deploys a PDF to a repository serving GitHub pages. The pages repository keeps a single commit on
# top of its initial commit, so PDFs of other projects stay in place while the history stays small.
#
# The original script is signed by Jeroen de Bruijn. A later version is signed by Francesco Romano.
# This script is a further adaption of the script of Francesco Romano, which can be found under
# https://gist.github.com/francesco-romano/351a6ae457860c14ee7e907f2b0fc1a5 (date: Dec. 20, 2020)
#
# Author: Andreas Rupp, Heidelberg University, 2021.
####################################################################################################

# Exit with nonzero exit code if anything fails.
set -euo pipefail

# Check that all required variables are set.
for var in REPO_TOKEN GH_REPO_ORG GH_REPO_NAME GH_USER_NAME GH_USER_MAIL PDF_FILE; do
  if [ -z "${!var:-}" ]; then
    echo "::error::Deploying the PDF requires '$var' to be set (see action inputs)."
    exit 1
  fi
done

# Only deploy if the PDF has successfully been created.
SOURCE_DIR="${SOURCE_DIR:-$PWD}"
PDF_NAME="$(basename "$PDF_FILE")"
PDF_PATH="$SOURCE_DIR/$PDF_NAME"
if [ ! -f "$PDF_PATH" ]; then
  echo "::error::PDF '$PDF_PATH' has not been found. Not going to deploy it!"
  exit 1
fi

REPO_URL="https://$GH_USER_NAME:$REPO_TOKEN@github.com/$GH_REPO_ORG/$GH_REPO_NAME.git"
WORK_DIR="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/deploy_pdf.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

deploy() {
  local repo_dir="$WORK_DIR/pages"
  rm -rf "$repo_dir"

  # Retrieve the default branch of the repository containing the GitHub pages.
  git clone --quiet --filter=blob:none "$REPO_URL" "$repo_dir"
  cd "$repo_dir"
  git config user.name "$GH_USER_NAME"
  git config user.email "$GH_USER_MAIL"

  # Create .nojekyll file, overwrite index.html file, and copy PDF.
  echo "" > .nojekyll
  echo "Not to be displayed." > index.html
  cp "$PDF_PATH" .
  git add --all

  if git rev-parse --quiet --verify HEAD > /dev/null; then
    if git diff --cached --quiet; then
      echo "PDF is unchanged. Nothing to deploy."
      return 0
    fi
    # Go back to first commit, but keep all files (also the PDFs of other projects).
    git reset --soft "$(git rev-list --max-parents=0 HEAD)"
  fi

  local sha="${GITHUB_SHA:-unknown}"
  git commit --quiet -m "Deploy $PDF_NAME from ${GITHUB_REPOSITORY:-unknown repository}" \
    -m "Build: ${GITHUB_RUN_NUMBER:-?}, commit: ${sha:0:7}"

  # Rewrite the remote branch, but fail if somebody else pushed in the meantime.
  git push --quiet --force-with-lease origin HEAD
}

echo "Deploying $PDF_NAME to $GH_REPO_ORG/$GH_REPO_NAME ..."
for attempt in 1 2 3; do
  # Run in a subshell outside of an if-condition, so that 'set -e' stays effective in deploy.
  set +e
  ( set -e; deploy )
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    echo "Done."
    exit 0
  fi
  echo "::warning::Deploying the PDF failed (attempt $attempt of 3)."
  sleep $((attempt * 10))
done

echo "::error::Deploying the PDF to $GH_REPO_ORG/$GH_REPO_NAME failed."
exit 1
