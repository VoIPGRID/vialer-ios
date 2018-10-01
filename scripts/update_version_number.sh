#!/bin/bash

#  update_version_number.sh
#  Usage: `update_version_number [branch]`
#
#  Based on:
#    http://zargony.com/2014/08/10/automatic-versioning-in-xcode-with-git-describe

#  Consider using https://github.com/Autorevision/autorevision for both Verion and Build number

GIT=`sh /etc/profile; which git`
PLISTBUDDY=/usr/libexec/PlistBuddy

#Use the argument supplied branch or otherwise the current branch
BRANCH=${1:-`${GIT} rev-parse --abbrev-ref HEAD`}
echo "Using tag from branch '${BRANCH}' for versioning"

VERSION_NUMBER=`${GIT} describe ${BRANCH} --tags --abbrev=0`

#LetS have a look at the version number, does it only include numbers and dots (the way apple likes it) or do we have something like 1.0.2.Beta.50
REGEX="([0-9\.]*)(.*)"
if [[ $VERSION_NUMBER =~ $REGEX ]]; then
    VERSION_NUMBER=${BASH_REMATCH[1]}
    POSSIBLE_REST=${BASH_REMATCH[2]}
fi

if [ -z $POSSIBLE_REST ]; then
#rest was empty, a "clean" version string like 2.0.0 or 1.0
	echo "Version number: ${VERSION_NUMBER}"
else
#rest was found, the vesion string included characters like. 2.0.beta
	VERSION_NUMBER=${VERSION_NUMBER%?}
	echo "Version number: ${VERSION_NUMBER}"
	echo "Additional Version String: ${POSSIBLE_REST}"
fi

plist="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

${PLISTBUDDY} -c "Set :CFBundleShortVersionString ${VERSION_NUMBER}" "${plist}"
if [ -f "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist" ]; then
	${PLISTBUDDY} -c "Set :CFBundleShortVersionString ${VERSION_NUMBER}" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"
fi

#Store the possible string found behind the "clean" version string
# ${PLISTBUDDY} -c "Set :Additional_Version_String ${POSSIBLE_REST}" "${plist}"