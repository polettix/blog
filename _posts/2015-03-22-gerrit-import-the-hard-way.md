---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: Gerrit import - the hard way
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

What if you started developing a tool using [git], and after 400+
commits someone tells you to import it into a [Gerrit]-based
central repository where you barely have a bit for pushing
proposed changes? Well... it's possible!

## Assumptions

Let's give things names:

* *git-repo* is the original repo you used so far. It might even be your
  local copy of the code in your computer, this does not affect the test;
* *gerrit-origin* is the Fort-Knox central repository where you can push
  proposed changes
* *gerrit-local* is your humble local copy of *gerrit-origin*

There are few assumptions that will make you decide whether it's
worth reading on or not:

1. you have *git-repo* with a branch `source` containing the commits you
   want to push into *gerrit-origin*;
2. you are provided with means to access *gerrit-origin* (i.e. clone it
   and eventually push to it) and a branch `destination` to push your
   commits;
3. you want to preserve history, so each commit in the branch of *git-repo*
   will have to end up in a commit in *gerrit-origin*;
4. you only have a commit bit in *gerrit-origin*, i.e. you have the right
   to do a `git push origin HEAD:refs/for/master` (see
   [Gerrit documentation][GerritDocs]) and hope that someone will
   be so kind as to accept those changes, but nothing fancier.
5. this will be your first import of some consistent history, from that
   point in time on you will use *gerrit-local* and forget about
   *git-repo* (i.e. you will definitely jump on the [Gerrit] carriage for
   this development).

We'll see later what you can do if some of the above do not apply... you
lucky!

## Assumptions Are Right!

So the assumptions are right... let's proceed in order. This is what we
are going to do (you'll notice that [Gerrit] is somehow very fussy and
you will have to do a lot of work to make it happy):

* clone the *gerrit-origin* into a local copy *gerrit-local*;
* get the commits from branch `source` in *git-repo* into branch
  `intermediate` in *gerrit-local*;
* adjust the imported commits in *gerrit-local* to match the rules
  set in *gerrit-origin*. E.g. you might want to modify the committer's
  name or email to match what is set in *gerrit-origin* in case you
  saved your commits with an email address and you want to push
  commits with another email;
* add a 'Commit-Id` to each commit message (or *gerrit-origin* will
  complain);
* rebase `intermediate` to `destination`, so that *gerrit-origin* will
  see them as acceptable;
* push to *gerrit-origin* and cross fingers.

### Cloning the repository

First thing to do is to create *gerrit-local* cloning *gerrit-origin*.
We will assume that *gerrit-origin* is at:

    ssh://gerrithost:29418/GerritRepo.git

and that you want to clone it into `/path/to/GerritRepo` so the clone
will be:

    cd /path/to
    git clone ssh://gerrithost:29418/GerritRepo.git GerritRepo
    cd GerritRepo

This will provide you a fresh copy of the repository, but it's still
not sufficient for setting up your [Gerrit] clone properly. Every time
you have to do a push, in fact, you will have to include a `Commit-Id`
inside the commit message, and doing this manually is cumbersome. So
most probably you will do something like this:

    scp -p -P 29418 john.doe@gerrithost:hooks/commit-msg .git/hooks/

This will install a *hook* that will be called every time a commit
message is created, including the `Commit-Id` inside the last paragraph
of the message itself and making Gerrit happy.

Instructions for cloning and getting the hook script should be also
available in the [Gerrit] GUI - if you have access to it. See
[cloning][GerritCloning] and [commit-msg creation][GerritCommitCreation]
for details and possible variants that might apply to your case.

Last thing, we ensure that the `destination` branch is available as
a branch in *gerrit-local* too:

    git checkout -b development origin/development

### Getting your commits in *gerrit-local*

We will do most of the work in *gerrit-local* so we want to acquire the
relevant commits there. We will assume that *git-repo* is at:

    ssh://githost/GitRepo.git

so we move into *gerrit-local*'s directory and do this:

    git remote add git-repo ssh://githost/GitRepo.git
    git fetch git-repo

and the checkout its `source` branch into the local `intermediate`
for doing transformations:

    git checkout -b intermediate git-repo/source

### Transforming the commits

Time for some commits mangling now. Your friend is `filter-branch`, so
you might want to see some additional [documentation][GitFilterBranch]
if you want to do different changes.

> The changes in this section will change the SHA1 identifiers for all
  the commits. This should not be a problem because you are probably
  doing a transition towards [Gerrit] and will use *gerrit-origin*
  after importing all commits as described in this article.

One problem that I had was about the commiter's email address. This might
differ between *git-repo* (e.g. it might be your personal email address)
and *gerrit-origin* (e.g. for your work address, or another address that
you are using to contribute to the project in [Gerrit]). If this is
yours too, the following command (found [here][ChangingAuthorInfo]) can be
useful:

    git filter-branch --env-filter '
        OLD_EMAIL="your-old-email@example.com"
        CORRECT_NAME="Your Correct Name"
        CORRECT_EMAIL="your-correct-email@example.com"
        if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]; then
            export GIT_COMMITTER_NAME="$CORRECT_NAME"
            export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
        fi
        if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]; then
            export GIT_AUTHOR_NAME="$CORRECT_NAME"
            export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
        fi
    ' --tag-name-filter cat -- --branches --tags

Then, you will surely need to ensure that each commit has a `Commit-Id`
inside. The hook you installed will be useful to do this, but it expects
to take its input from a file and not from the standard input so we will
use a pivot file `/tmp/mymessage` for exchanging data:

    HOOK="$PWD/.git/hooks/commit-msg"
    git filter-branch --force --msg-filter "
        cat - >/tmp/mymessage &&
        '$HOOK' /tmp/mymessage &&
        cat /tmp/mymessage
    "

### Rebasing and pushing

We are now ready to do the rebase. This is needed because there is
currently no link between your new commits and whatever was in
*gerrit-origin*, so you have to make sure this link is there.

Rebase will be very simple - although the results will vary depending
on the contents of branch `destination` in *gerrit-origin*:

    git checkout intermediate
    git rebase destination

At this point it should be easy:

    git push origin HEAD:refs/for/destination

If you get errors, you might want to push only part of the commits and
then repeat - whatever is fine for you!

## What if...

You might be in the situation in which some of the assumptions do not
really apply... the following hints might help.

### Assumption 1 or 2 do not apply?

Well, this article is probably not for you at all! Did you read it up
to here? Wow, you're really curious!

### Assumption 3 does not apply?

If you're not interested into preserving all intermediate commits, you
can just squash the whole thing into one single commit and then
push it. At this point you will not need to do any transformation,
because the commit hook will take care of setting the `Change-Id` and
you will surely have updated your email at this point - right?!?

### Assumption 4 does not apply?

If you have wider powers on the Gerrit side, and this is an initial
import, then you probably can just work behind the scenes and set a
copy of *git-repo* to what's behind *gerrit-origin*.

Another alternative is to temporarily disable `Change-Id`s in the
Gerrit repo to simplify the import.

### Assumption 5 does not apply?

Well, your situation seems to be quite peculiar... good luck!


[git]: http://www.git-scm.com/
[Gerrit]: https://code.google.com/p/gerrit/
[GerritDocs]: https://gerrit-documentation.storage.googleapis.com/Documentation/2.11/intro-quick.html#_creating_the_review
[GerritCloning]: https://gerrit-documentation.storage.googleapis.com/Documentation/2.11/intro-quick.html#_cloning_the_repository
[GerritCommitCreation]: https://gerrit-documentation.storage.googleapis.com/Documentation/2.11/user-changeid.html#creation
[GitFilterBranch]: http://www.git-scm.com/docs/git-filter-branch
[ChangingAuthorInfo]: https://help.github.com/articles/changing-author-info/
