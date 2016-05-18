#!/bin/bash
MYDIR=$(dirname "$0")
source "$MYDIR/common.sh"

title=$1
[ -n "$title" ] || DIE "please provide a title for the post"

name=$(sed 's/[^a-zA-Z0-9_]\+/-/g' <<<"$title" | tr A-Z a-z)

if [ "$(basename "$0")" == "newpost.sh" ] ; then
   subpath="_posts"
   fullname=$(date "+%Y-%m-%d-$name.md")
else
   subpath="_drafts"
   fullname="$name.md"
fi

prepath=$(readlink -f "$MYDIR/../$subpath")
fullpath="$prepath/$fullname"

cat >"$fullpath" <<END
---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: $title
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

END

echo "created: $fullpath"
