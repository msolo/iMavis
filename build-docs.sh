#!/bin/sh

set -e

# Allow README.md to serve in two place.

cp README.md docs/index.md

# Remove docs/ prefix in HTML links.
sed -i "" -e 's|"docs/|"|g' docs/index.md
# Remove docs/ prefix in Markdown links.
sed -i "" -e 's|[\(]docs/|(|g' docs/index.md
