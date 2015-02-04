#!/bin/bash
MYDIR=$(dirname "$0")
FULLME=$(readlink -f "$0")
BAREME=$(basename "$0")

die() {
   echo "$*" >&2
   exit 1
}

outer_main() {
   git checkout master

   cd "$MYDIR" || die "unable to go in $MYDIR"
   cd .. || die "unable to go in parent directory of $MYDIR"
   echo "in $PWD now"

   bundle exec jekyll build || die "unable to update contents"

   cp "$FULLME" _site || die "cannot handover to myself"
   _site/"$BAREME" inner || die 'errors in handover'
}

inner_main() {
   git checkout gh-pages
   tar cf - -C _site . | tar xvf -
   rm "$BAREME"
   git add .
   now=$(date '+%Y%m%d-%H%M%S')
   git commit -m "update at $now"
   git push origin gh-pages
   git checkout master
}

if [ "$1" == "inner" ]; then
   inner_main
else
   outer_main
fi
