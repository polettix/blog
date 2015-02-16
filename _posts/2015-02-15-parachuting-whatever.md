---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: Parachuting Whatever
image:
   feature: kakadu-volo-insieme.jpg
   credit: Uccelli al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
   comments: true
---

Many times I craft things that have to be installed in some place,
which means that an installer is a nice thing to have. Here's one,
Perl-based.

The basic idea that probably anyone has for a poor man's deployment
system is to pack stuff in a tarball, together with a deployment
script inside that has to be executed in the target machine. Without
too much fantasy, I figured that I could walk the extra mile and
make a package that behaves like a tarball with a twist - i.e. it
is capable of executing things after unpacking.

## TL;DR

Download [*self-contained bundled version*][deployable-bundle] and save
it as `deployable` in some directory in your `PATH`. Make sure it's
executable too.

Put your stuff in a directory. The current directory is fine. Assume
it is exactly as you want it to appear when you unpack in the
destination. Include a deployment script, i.e. the one that you usually
include for starting the real deployment after unpacking --we'll call
it `deploy.sh`-- and make sure it's executable. You should have
something like this in the directory:

    deploy.sh
    file1.foo
    file2.bar
    somedir/
    ...

To generate `package.pl` ready for deployment, run:

    deployable -o package.pl -d deploy.sh \
        file1.foo file2.bar somedir ...

Ship `package.pl`, execute in place and you're done.

## Enter [deployable]

[deployable] is a handful of tools to help you with remote management
of multiple servers. It was born when there was no Puppet or Chef in
town - not that I know of, at least - and worked pretty well for me.

In this post we'll concentrate on the main script --named after the
bunch of tools-- i.e. the one that allows you to generate smart
packages.

Before continuing, if you find it interesting, please note that you
will need to carry also the `remote` script with you, together with
installing dependencies. If you like compact packages - and you
probably do if you're interested in packing thing smartly - you
can download the [*bundled* version][deployable-bundle]. Ensure to
put it in some place in `PATH` and to set its execution bits, this
is what we will assume in the rest of this post.

So what was your workflow before [deployable]? Let's assume it was
something like this:

1. place all relevant files in a directory (possibly in a subdirectory)
2. add a deployment script to the directory
3. create a tarball of that directory
4. write instructions to unpack the tarball and execute the
   deployment script inside the directory that is created
5. ship the tarball and the instructions

Something along the following line:

    mkdir foobar
    cp /lots/of/stuff/* foobar
    vi foobar/deploy.sh # and put what's needed
    chmod +x foobar/deploy.sh
    tar cvzf package.tar.gz foobar

You actually don't have to change your workflow that much. If you
want to stick to it, you can *still* put all your stuff in a directory,
like the first bullet above, and create a package with the whole
contents of that directory via [deployable] instead of the last step
in the example above:

    # preparation goes exactly like before, but packaging is:
    deployable -o /path/to/package.pl -H foobar -d deploy.sh

You end up with `/path/to/package.pl` (you can omit the path to create it
in the current directory of course). At this point, you hardly have to
write any instructions: just tell your recipients to put the script in
the destination server with the execution bits turned on, and execute it.

So what does that command do? Easy:

* option `-o` sets the output. If not set, the resulting script will
  be printed on standard output, but if you provide a filename
  [deployable] will make it executable
* option `-H` (alias `--heredir`) tells [deployable] where your stuff
  is (in terms of a directory). The contents of the directory will
  be included in the package, but the initial path set with `-H` will
  be stripped away. In the example above, file `foobar/deploy.sh` will
  be included simply as `deploy.sh` (actually, as `./deploy.sh`). This
  is useful if you want to store all files/directories to be shipped
  in one single place, but you don't care about the containing
  directory
* option `-d` tells [deployable] that the specified file (i.e.
  `deploy.sh` in our example) has to be executed. You can specify
  whatever file you include, even multiple ones; only remember that
  the path to the files that you include will be referred to their
  position in the package, so in our example you have to specify it
  as `deploy.sh` instead of `foobar/deploy.sh` because `foobar` is
  stripped away.

[deployable]: http://repo.or.cz/w/deployable.git
[deployable-bundle]: {{ site.url }}/assets/files/deployable

## Shortcuts?

Here are some shortcuts that [deployable] provides.

### Stuff in current directory

If you just want to ship some files in the current directory, you're not
obliged to use `-H` at all, just tell [deployable] which files you want
to include. Remember that they will be recorded with the path you provide.

    deployable -o p.pl file1 file2 ...

### Execute multiple deployment programs

If you want to execute multiple programs, make sure they are all
executable and pass them with multiple `-d` options:

    deployable -o p.pl -d exec1 -d exec2 exec1 exec2 file1 ...

If you want to execute all executable files inside the default *current*
directory, you can just pass the `-X` command line parameter. Beware that
it will execute whatever it finds, so make sure that this is what you
actually want:

    deployable -o p.pl -X exec1 exec2 file1 ...

### Install stuff in place

At the time that I needed it, chances where that I had to update
some system files in multiple machines at once. This meant that I
wanted the tarball to *optionally* extract things based on the
root directory (i.e. `/`) so that the files go in place.

While this is not hard to do with what explained above --it's a
matter of crafting the `deploy.sh` script for this-- it was too
handy to leave outside. You have two ways:

* create a directory `target-root` and put all the stuff you want
  to install like `target-root` were the root directory `/` of the
  target system, or
* include files/directories (presumably inside the current directory)
  to be directly extracted in the root directory `/` of the target
  system.

If you go the first way, this is how you call [deployable]:

    deployable -o p.pl -r target-root

You can of course add scripts to call within the same command line. If
you're more into the second, this is how you do it:

    deployable -o p.pl -R etc

## The surface is scratched now...

[deployable] has plenty of documentation. After installing it, you can
run either of these commands, in increasing level of verbosity:

    deployable --usage
    deployable --help
    deployable --man

and read it. Have fun!
