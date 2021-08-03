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

# Validate version - source this so we get the version information
source ${SCRIPT_PATH}/validate_version.sh $1
if [ $? -ne 0 ]; then
    exit 1
fi

####################
# Bump version
####################

# Update version in the CMakeLists.txt
sed -i "s/set (CPACK_PACKAGE_VERSION_MAJOR \"[0-9]\+\")/set (CPACK_PACKAGE_VERSION_MAJOR \"$MAJOR_VERSION\")/g" $SCRIPT_PATH/../CMakeLists.txt
sed -i "s/set (CPACK_PACKAGE_VERSION_MINOR \"[0-9]\+\")/set (CPACK_PACKAGE_VERSION_MINOR \"$MINOR_VERSION\")/g" $SCRIPT_PATH/../CMakeLists.txt
sed -i "s/set (CPACK_PACKAGE_VERSION_PATCH \"[0-9]\+\")/set (CPACK_PACKAGE_VERSION_PATCH \"$PATCH_VERSION\")/g" $SCRIPT_PATH/../CMakeLists.txt
sed -i "s/set (VERSION_SUFFIX \"[^\"]*\")/set (VERSION_SUFFIX \"$VERSION_SUFFIX\")/g" ${SCRIPT_PATH}/../CMakeLists.txt

# Update Changelog
if ! grep -Fxq "## $1" $SCRIPT_PATH/../CHANGELOG.md; then
    sed -i "N;N;s/# Changelog\n\n## Nightly (Unreleased)/# Changelog\n\n## Nightly (Unreleased)\n\n## $VERSION\n\nTODO/g" $SCRIPT_PATH/../CHANGELOG.md
    echo "WARNING: Please make sure to update CHANGELOG.md"
else
    echo "ERROR: CHANGELOG.md already contains this version number"
fi

# Update Debian Changelog
if ! grep -Fwq "xournalpp ($VERSION-1)" $SCRIPT_PATH/../debian/changelog; then
    GIT_USER=$(git config --get user.name)
    GIT_MAIL=$(git config --get user.email)
    DATE=$(date --rfc-2822)
    
    sed -i "1i xournalpp ($VERSION-0) UNRELEASED; urgency=low\n\n  * TODO\n\n -- ${GIT_USER} <${GIT_MAIL}>  ${DATE}\n" $SCRIPT_PATH/../debian/changelog
    echo "WARNING: Please make sure to update debian/changelog"
else
    echo "ERROR: debian/changelog already contains this version number"
fi

# Update PPA Recipe
if ! grep -Exq "    <release date=\"[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}\" version=\"$VERSION\" />" ${SCRIPT_PATH}/../desktop/com.github.xournalpp.xournalpp.appdata.xml; then
    DATE=$(date +%Y-%m-%d)
    
    sed -i "1,/^    <release .*$/ {/^    <release .*$/i\
    \ \ \ \ <release date=\"$DATE\" version=\"$VERSION\" />
    }" $SCRIPT_PATH/../desktop/com.github.xournalpp.xournalpp.appdata.xml
else
    echo "ERROR: desktop/com.github.xournalpp.xournalpp.appdata.xml already contains this version number"
fi

echo "Bumped version from $CURRENT_VERSION to $VERSION"
