#!/bin/bash
REALME=$(readlink -f "$0")
MYDIR=$(dirname "$REALME")
source "$MYDIR/common.sh"

draft=$1
[ -n "$draft" ] || DIE "please provide a draft to turn into a post"
[ -w "$draft" ] || DIE "draft '$draft' does not exist or is not writeable"

realdraft=$(readlink -f "$draft")
basedraft=$(basename "$realdraft")
realdrafts=$(readlink -f "$MYDIR/../_drafts")
expecteddraft="$realdrafts/$basedraft"
[ "$expecteddraft" == "$realdraft" ] \
   || DIE "'$draft' not inside '$realdrafts' as expected"

fullname=$(date "+%Y-%m-%d-$basedraft")
prepath=$(readlink -f "$MYDIR/../_posts")
fullpath="$prepath/$fullname"
mv "$draft" "$fullpath"

echo "moved as $fullpath"
