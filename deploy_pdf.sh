#!/bin/sh

####################################################################################################
# The original script is signed by Jeroen de Bruijn. A later version is signed by Francesco Romano.
# This script is a further adaption of the script of Francesco Romano, which can be found under
# https://gist.github.com/francesco-romano/351a6ae457860c14ee7e907f2b0fc1a5 (date: Dec. 20, 2020)
#
# Author: Andreas Rupp, Heidelberg University, 2021.
####################################################################################################

# Setup this script and get the current gh-pages branch.
echo 'Setting up the script...'

# Exit with nonzero exit code if anything fails.
set -e

# Pretend to be user GH_USER_NAME.
git config --global user.name $GH_USER_NAME
git config --global user.email $GH_USER_MAIL

# Retrieve master branch of the repositoy containing the GitHub pages.
rm -rf $GH_AUX_REP
git clone https://$GH_USER_NAME:$REPO_TOKEN@github.com/$GH_REPO_ORG/$GH_REPO_NAME.git $GH_AUX_REP
cd $GH_AUX_REP

# Set the push default to simple i.e. push only the current branch.
git config --global push.default simple

# Go back to first commit.
git reset `git rev-list --max-parents=0 --abbrev-commit HEAD`

# Create .nojekyll file.
echo "" > .nojekyll

# Overwrite index.html file.
echo "Not to be displayed." > index.html

# Copy doxygen into current branch.
cp -r ../$PDF_FILE .

# Only upload if Doxygen successfully created the documentation.
if [ -f $PDF_FILE ]; then
  echo 'Uploading documentation to the HyperHDG_pages repository...'
  # Add everything in this directory (the Doxygen code documentation) to the gh-pages branch.
  git add --all

  # Commit the added files with a title and description containing the GitHub actions build number
  # and the GitHub commit reference that issued this build.
  git commit -m "Deploy PDF to GitHub master build: ${GITHUB_RUN_NUMBER}" \
    -m "Commit: $(git rev-parse --short "$GITHUB_SHA")"

  # Force push to the remote GitHub pages branch.
  git push --force https://$GH_USER_NAME:$REPO_TOKEN@github.com/$GH_REPO_ORG/$GH_REPO_NAME.git
else
  echo '' >&2
  echo 'Warning: No documentation (html) files have been found!' >&2
  echo 'Warning: Not going to push the documentation to GitHub!' >&2
  exit 1
fi
