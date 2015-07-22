#!/bin/bash

#  update_version_number.sh
#  Usage: `update_version_number [branch]`
#
#  Based on:
#    http://zargony.com/2014/08/10/automatic-versioning-in-xcode-with-git-describe

#  Consider using https://github.com/Autorevision/autorevision for both Verion and Build number

GIT=`sh /etc/profile; which git`
PLISTBUDDY=/usr/libexec/PlistBuddy
BRANCH=${1}

VERSION_NUMBER=`${GIT} describe ${BRANCH}`
echo "Version number: ${VERSION_NUMBER}"

${PLISTBUDDY} -c "Set :CFBundleShortVersionString ${VERSION_NUMBER}" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
#Also update dSYM file
${PLISTBUDDY} -c "Set :CFBundleShortVersionString ${VERSION_NUMBER}" "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}.dSYM/Contents/Info.plist"
