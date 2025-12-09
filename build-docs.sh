#!/bin/sh

set -e

# Export README so it shows up on GitHub reasonably well.
./export-readme.py docs/index.md ./README.md