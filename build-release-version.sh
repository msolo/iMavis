#!/bin/bash

set -eu


function fatal {
  echo "$@" >&2
  exit 1
}

# Set the version and build numbers
VERSION_NUMBER="1.0.11"
BUILD_NUMBER="11"
GIT_TAG="release-$VERSION_NUMBER"

# Set the Xcode project file path
PROJECT_FILE="Mavis.xcodeproj/project.pbxproj"
RELEASE_DIR="Build/Products/Release"

# Update the MARKETING_VERSION and CURRENT_PROJECT_VERSION values in the project file. This will adjust the version of tests as well, that's fine.
sed -i "" "s/MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION_NUMBER;/g" "$PROJECT_FILE"
sed -i "" "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" "$PROJECT_FILE"

dirty=$(git status --porcelain)
if [[ "$dirty" != "" ]]; then
  fatal "ERROR: dirty workdir"
fi

# Make sure we made some effort to label our releases.
git rev-parse -q --verify $GIT_TAG >/dev/null || fatal "Run git tag $GIT_TAG"

if [[ $(git rev-parse -q --verify $GIT_TAG) != $(git rev-parse -q HEAD) ]]; then
  fatal "Run git checkout $GIT_TAG - current workdir revision does not match."
fi
