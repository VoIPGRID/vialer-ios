#!/bin/bash
 
#  nth-commit.sh
#  Usage: 'buildnr_to_commit_hash.sh [buildnumber] [branch]'
#  Based on: http://tgoode.com/2014/06/05/sensible-way-increment-bundle-version-cfbundleversion-xcode/#code
 
GIT=`sh /etc/profile; which git`
BUILDNUMBER=${1}
BRANCH=${2}

if [ -z $BRANCH ]; then
  echo "Usage:"
  echo "  buildnr_to_commit_hash.sh [buildnumber] [branch]"
else
  echo "Using branch '${BRANCH}' for counting"

  SHA1=$(${GIT} rev-list ${BRANCH} | tail -n ${BUILDNUMBER} | head -n 1)
  echo "use: 'git checkout $SHA1' to get the commit for buildnumber: ${BUILDNUMBER}"
fi
