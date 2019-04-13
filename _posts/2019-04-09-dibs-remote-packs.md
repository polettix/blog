---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Dibs - Remote Packs
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

Did you think that [the previous post on Dibs packs][dibs-3] had all there
is to know about packs? Surely not!

> Curious about the whole Dibs Saga? See a [list of all posts on dibs](/dibs-saga).

## Table of Contents

- TOC
{:toc}


## Where Is My Pack?

We already know that packs are very useful to collect programs that will be
executed within containers and eventually shape the container image that we aim
to. As a matter of fact, packs are a little more generic than that, allowing to
store *something* that can become useful at a later point - but we will not
talk about this here.

We also know that there is *natural* place where we can place packs, i.e. the
`pack` sub-directory. But it's not the only place, as you might already have
guessed.

We already saw how to define a pack in the `packs` section of the
configuration file:

{% highlight yaml %}
packs:
   kickoff: # we choose the "explicit" way, it's the same as above
      type: project
      path: kickoff.sh
{% endhighlight %}

The `type` can be any of...

- `project`, to indicate that the `path` is relative to the `pack`
  sub-directory of the project;
- `inside`, to indicate that `path` refers to the inside of the container
  (i.e. it's already in the base container image, somewhere in the file
  system)
- `src`, to indicate that the `path` refers to the `src` sub-directory. We
  still have to talk about this sub-directory, but suffices to say that
  it's meant to contain the code that you want to package in the container
  image.

Still not the whole story, but it's a good start.

## A Pack Can Contain Things

It might seem at this point that sharing packs across different projects
would involve a lot of copying scripts around: still better than lenghty
`RUN` sections, but probably not that much.

A pack, anyway, need not be a single file and can be a whole directory. As
an example, you might put a few (possibly related) scripts and files in a
sub-sub-directory `pack/my-scripts` of the project directory, and define
the associated pack as follows:

{% highlight yaml %}
packs:
   my_scripts:
      type: project
      base: my-scripts
{% endhighlight %}

Note that we're using `base` now. Then, suppose we have two scripts
`first.sh` and `second.sh` inside, and we want to call them in two
strokes:

{% highlight yaml %}
actions:
    # ...
    - name: call first
      pack: my_scripts
      path: first.sh
      # ...
    - name: call second
      pack: my_scripts
      path: second.sh
      # ...
{% endhighlight %}

This makes very easy to group common programs/scripts e.g. in a `git`
repository and then reuse it easily across different projects:

{% highlight bash %}
$ cd "$MY_PROJECT/pack"
$ git clone "$URL_OF_GIT_REPO" my-scripts
{% endhighlight %}

## Remote Packs: Git

It turned out that sharing pack programs in a git repository was too
useful to be left to manual intervention, which is why there are
additional ways to define a pack, among which the `type: git`:

{% highlight yaml %}
packs:
   basic:
      type:   git
      origin: https://github.com/polettix/dibspack-basic.git
{% endhighlight %}

The above repository contains a few useful scripts that will hopefully
help you shape your containers for a Perl program (there is a program
inside that leverages either `cpanm` or `carton` to do the heavylifting).

If you want, you can also be very precise as to what you want to checkout
from the git repository, by specifying an explicit `ref` or putting it as
a URI fragment:

{% highlight yaml %}
packs:
   # The following packs are equivalent!
   basic1:
      type:   git
      origin: https://github.com/polettix/dibspack-basic.git#746699a

   basic2:
      type:   git
      origin: https://github.com/polettix/dibspack-basic.git
      ref:    746699a
{% endhighlight %}

The repository will be cloned/fetched/checked out as requested and then
any `path` will be relative to its base directory. So the following
stroke:

{% highlight yaml %}
actions:
    # ...
    - name: install Perl stuff
      pack: basic
      path: perl/build
      # ...
{% endhighlight %}

will end up calling [this build program][perl-build].

If you're wondering... yes, the idea came from [the buildpack for
heroku][bph].

## Which Way Should I Use?

Both techniques are fine for sharing programs across different projects.
The automatic clone/checkout has simplicity and ease of reproduction as
a pro, allowing to use `dibs.yaml` to define what's needed and letting
`dibs` figure out the rest; on the other hand, using explicit checkouts in
the `pack` directory gives you full control, which is probably very useful
while you're developing and/or debugging a pack.

You might even want to go both ways, e.g. using a YAML alias:

{% highlight yaml %}
packs:
   # This a local clone of the remote git repo, managed manually
   local:
      type: project
      base: dibspacks-basic

   # Same repo, but managed by dibs automatically
   remote: &basic
      type:   git
      origin: https://github.com/polettix/dibspack-basic.git

actions:
    # ...
    - name: install Perl stuff
      pack: *basic
      path: perl/build
      # ...
{% endhighlight %}

In the example above, `basic` is an alias for the hash associated to
`remote`, but the alias definition can be easily moved up to `local` and
the strokes pointing to it would start using the local checkout, where you
might be messing around to do troubleshooting and/or enhancements.

## That's All For Now!

Again, we're at the end of the short story. Today we learned that:

- packs can represent directories where we can then choose a program using
  the `path` key in the stroke definition
- the pack `type: git` can come very handy to centralize a set of common
  packs and streamline reuse across different projects
- you should definitely check out [dibspack-basic][] because it can come
  handy to build your Perl-based (and more!) containers.

Comment below!

[dibs-3]: /dibs-meet-the-packs
[perl-build]: https://github.com/polettix/dibspack-basic/blob/master/perl/build
[bph]: https://github.com/polettix/heroku-buildpack-perl-procfile
[dibspack-basic]: https://github.com/polettix/dibspack-basic
