#!/bin/bash
MYDIR=$(dirname "$0")
source "$MYDIR/common.sh"

title=$1
[ -n "$title" ] || DIE "please provide a title for the post"

name=$(sed 's/[^a-zA-Z0-9_]\+/-/g' <<<"$title" | tr A-Z a-z)
fullname=$(date "+%Y-%m-%d-$name.md")

subpath="_drafts"
[ "$(basename "$0")" == "newpost.sh" ] && subpath="_posts"
fullpath=$(readlink -f "$MYDIR/../$subpath/$fullname")

cat >"$fullpath" <<END
---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: $title
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
---

END

echo "created: $fullpath"
