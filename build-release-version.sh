#!/bin/bash

set -eu

# Handle site and documentation.
# ./build-site.sh

# Conflict in the AppStore
APP_NAME="Mavis"
# Set the version and build numbers
VERSION_NUMBER="1.0.7"
BUILD_NUMBER="7"
GIT_TAG="release-$VERSION_NUMBER"

# Set the Xcode project file path
PROJECT_FILE="$APP_NAME.xcodeproj/project.pbxproj"
RELEASE_DIR="Build/Products/Release"

# Update the MARKETING_VERSION and CURRENT_PROJECT_VERSION values in the project file. This will adjust the version of tests as well, that's fine.
sed -i "" "s/MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION_NUMBER;/g" "$PROJECT_FILE"
sed -i "" "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" "$PROJECT_FILE"

# Make sure we made some effort to label our releases.
git rev-parse -q --verify $GIT_TAG >/dev/null || echo "Run git tag $GIT_TAG" >&2
