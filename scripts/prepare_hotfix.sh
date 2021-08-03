#!/bin/bash

# Get the path of the script
SCRIPT_PATH=$(dirname $(realpath -s $0))
HOME_PATH=$(realpath -s ${SCRIPT_PATH}/..)

# The release may be prior to adding the scripts. Copy the scripts to a temporary directory
TEMP_PATH=$(mktemp -d)
cp -r $SCRIPT_PATH/* $TEMP_PATH/

####################
# Check preconditions
####################

# Check for a version number passed by argument
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <published version> <new version>"
    exit 1
fi

# Check if the version was published before
if ! git tag | grep -Fxq "$1"; then
    echo "ABORT: The supplied version does not exist"
    exit 1
fi

# Check if branch already exists
if git rev-parse --quiet --verify hotfix-$2 > /dev/null; then
    echo "ABORT: Hotfix branch \`hotfix-$2\` already exists"
fi

git checkout --quiet $1
if [ $? -ne 0 ]; then
    echo "ABORT: Could not check out release"
    exit 1
fi

git checkout --quiet -b hotfix-$2
if [ $? -ne 0 ]; then
    echo "ABORT: Could not create hotfix branch"
    exit 1
fi

# Bump version
if [[ -d "${SCRIPT_PATH}/" ]]; then
    ${SCRIPT_PATH}/bump_version.sh "$2"
    if [ $? -ne 0 ]; then
        echo "ABORT: Could not set version of hotfix"
        exit 1
    fi
else
    mv ${TEMP_PATH} ${HOME_PATH}/.temp-scripts
    ${HOME_PATH}/.temp-scripts/bump_version.sh "$2"
    if [ $? -ne 0 ]; then
        rm -r ${HOME_PATH}/.temp-scripts
        echo "ABORT: Could not set version of hotfix"
        exit 1
    fi
    rm -r ${HOME_PATH}/.temp-scripts
fi

echo "SUCCESS: New hotfix ($2) was successfully prepared"
echo "You are now on the hotfix branch (hotfix-$2)."
echo "The version strings were automatically updated. Please update the changelog in:"
echo " - CHANGELOG.md"
echo " - debian/changelog"
echo "Once the changelog is updated, please commit the changes and push them to upstream."



