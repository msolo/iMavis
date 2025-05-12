#!/bin/bash

# Reformat README to work better on GitHub Pages, which is annoyingly
# different than the inline rendering.

cp README.md docs/index.md

# Remove docs/ prefix in links.
sed -i "" -e 's|"docs/|"|g' docs/index.md
# Remove docs/ prefix in links.
sed -i "" -e 's|[\(]docs/|(|g' docs/index.md

# Remove superfluous header.
sed -i "" -e "/# iMavis/d" docs/index.md
