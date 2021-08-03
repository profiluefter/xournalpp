#!/bin/bash

####################
# Check preconditions
####################

# Make sure we are on a release branch
# Branch name may either start with release or with hotfix
BRANCH=$(git branch --show-current)
if [ $? -ne 0 ]; then
    echo "Could not determine the current branch"
    exit 1
fi

if ! [[ $BRANCH =~ (release|hotfix)-[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9\.+:-]*)?$ ]]; then
    echo "You are not on a release or hotfix branch. Are you on the right branch?"
    exit 1
fi

# Check for a clean git working space - otherwise this script will commit whatever is there
if ! git diff --quiet --cached --exit-code > /dev/null; then
    echo "Your working tree is not clean. Please commit or stash all staged changes before running this script."
    exit 1
fi

####################
# Publish release
####################

if ! [[ $(read -e -p 'Are you sure you want to publish this release? [y/N] '; echo $REPLY) =~ ^[Yy]+$ ]]; then
    exit 0
fi

# Merge the release branch to releases
git checkout --quiet releases
if [ $? -ne 0 ]; then
    echo "Ooops the branch for releases does not exist..."
    exit 1
fi

echo "Merging $BRANCH into releases..."
git merge --no-ff -m "Release $RELEASE" $BRANCH
if [ $? -ne 0 ]; then
    echo "Merge of release failed. Did you rebase commits that were already released priorly!?"
    exit 1
fi

# Tag the release
echo "Tagging the release"
RELEASE=$(echo $BRANCH | sed -n 's/^\(release\|hotfix\)-\(.*\)$/\2/p')
git tag -a $RELEASE -m "Release $RELEASE"
if [ $? -ne 0 ]; then
    echo "Could not tag release"
    exit 1
fi

echo "SUCCESS: Release was published locally!"
echo "To publish the release globally push your changes with:"
echo ""
echo "    git push --follow-tags origin releases"
echo ""

if ! [[ $(read -e -p 'Do you want to merge back to the development branch now? [Y/n] '; echo $REPLY) =~ ^[Nn]+$ ]]; then
    echo "Once the merge is successfully finished, you may delete the release branch with:"
    echo ""
    echo "    git branch -d $BRANCH"
    echo ""

    # Merge the release branch back to master
    git checkout --quiet master
    git merge --no-ff -m "Release $RELEASE" $BRANCH
fi

