#!/bin/bash
 
#  update_build_number.sh
#  Usage: `update_build_number.sha [branch]`
#  Run this script after the 'Copy Bundle Resources' build phase
#  Based on:
#    http://tgoode.com/2014/06/05/sensible-way-increment-bundle-version-cfbundleversion-xcode/#code
#    http://blog.jaredsinclair.com/post/97193356620/the-best-of-all-possible-xcode-automated-build
#    http://www.egeek.me/2013/02/09/xcode-insert-git-build-info-into-ios-app/

#  Consider using https://github.com/Autorevision/autorevision for both Verion and Build number  
 
GIT=`sh /etc/profile; which git`
PLISTBUDDY=/usr/libexec/PlistBuddy

#Use the argument supplied branch or otherwise the current branch
BRANCH=${1:-`${GIT} rev-parse --abbrev-ref HEAD`}
echo "Using branch '${BRANCH}' for counting"

#  git rev-list ${BRANCH} --count is used to get the number of commits on ${BRANCH}, 
#  BUT it subtracts out the number of commits that you are currently behind said branch 
#  (with git rev-list HEAD..${BRANCH} --count). 
#  This is done so that if you aren’t at the tip of the branch (e.g. you’re checked out 
#  a few commits behind to find a problem), the build number will still be accurate to 
#  what you’re currently running.
BUILDNUMBER=$(expr $(${GIT} rev-list ${BRANCH} --count) - $(${GIT} rev-list HEAD..${BRANCH} --count))
echo "Updating build number to ${BUILDNUMBER} using branch '${BRANCH}'."

COMMIT_SHORT_HASH=$(${GIT} rev-list ${BRANCH} --abbrev-commit | tail -n ${BUILDNUMBER} | head -n 1)
echo "Commit short hash:${COMMIT_SHORT_HASH}"

#  Instead of updating the info.plist file in the source directory, the script modifies 
#  the info.plist in the target build directory. This way, you don’t have to check-in a 
#  constantly-modifying info.plist.
${PLISTBUDDY} -c "Set :CFBundleVersion ${BUILDNUMBER}" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
#Also update dSYM file
${PLISTBUDDY} -c "Set :CFBundleVersion ${BUILDNUMBER}" "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist"
${PLISTBUDDY} -c "Set :Commit_Short_Hash ${COMMIT_SHORT_HASH}" "${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"
