#!/bin/bash
MYDIR=$(dirname "$0")
FULLME=$(readlink -f "$0")
BAREME=$(basename "$0")

die() {
   echo "$*" >&2
   exit 1
}

main() {
   cd "$MYDIR" || die "unable to go in $MYDIR"
   cd .. || die "unable to go in parent directory of $MYDIR"
   echo "in $PWD now"

   git checkout master || die 'unable to switch to master'
   bundle exec jekyll build || die "unable to update contents"
   git checkout gh-pages || die 'unable to switch to gh-pages'
   tar cf - -C _site . | tar xvf - \
   && git add . \
   && git commit -m "$(date '+update at %Y%m%d-%H%M%S')" \
   && git push origin gh-pages
   git checkout master || die 'unable to switch to master'
}

main
