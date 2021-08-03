#!/bin/bash

# Get the path of the script
SCRIPT_PATH=$(dirname $(realpath -s $0))

####################
# Check preconditions
####################

# Check for a version number passed by argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 version-number"
    exit 1
fi

# Validate version
${SCRIPT_PATH}/validate_version.sh "$1"
if [ $? -ne 0 ]; then
    exit 1
fi

# Make sure we are on a release branch
# Branch name may either start with release or with hotfix
BRANCH=$(git branch --show-current)
if [ $? -ne 0 ]; then
    echo "Could not determine the current branch"
    exit 1
fi

if ! [[ $BRANCH == "master" ]]; then
    echo "You must be on \`master\` to prepare a release"
    exit 1
fi

# Check for a clean git working space - otherwise this script will commit whatever is there
if ! git diff --quiet --cached --exit-code > /dev/null; then
    echo "Your working tree is not clean. Please commit or stash all staged changes before running this script."
    exit 1
fi

# Check if branch already exists
if git rev-parse --quiet --verify release-$1 > /dev/null; then
    echo "ABORT: Release branch \`release-$1\` already exists"
fi

if git tag | grep -Fxq "$1"; then
    echo "This version was already released"
    exit 1
fi

####################
# Prepare release
####################

echo "Creating release branch..."

# Check out new release-branch 
git checkout --quiet -b release-$1
if [ $? -ne 0 ]; then
    echo "ABORT: Could not check out new release-branch"
    exit 1
fi

# Bump version
${SCRIPT_PATH}/bump_version.sh "$1"
if [ $? -ne 0 ]; then
    echo "ABORT: Could not set version of release"
    exit 1
fi

echo "SUCCESS: New release $1 was successfully prepared"
echo "You are now on the release branch (release-$1)."
echo "The version strings were automatically updated. Please update the changelog in:"
echo " - CHANGELOG.md"
echo " - debian/changelog"
echo "Once the changelog is updated, please commit the changes and push them to upstream."
