#!/bin/bash
MYDIR=$(dirname "$0")
cd "$MYDIR" &&
cd .. &&
bundle exec jekyll serve --drafts --watch -H 0.0.0.0
