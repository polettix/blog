---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Dibs - YAML Reuse
image:
   feature: romeo-stirato.jpg
   credit: Romeo
comments: true
---

In our [first post][dibs-1] about [dibs][] we saw how to use it as
a different kind of multistage Dockerfile. While I already prefer it this
way (all the `&&`s quickly annoy me), a lot revolves around reuse.

If you're a programmer, you probably don't need to be told why reuse is
important. If you're not, you probably don't care!

There Is More Than One Way To Reuse It, anyway! In this post we will start
from YAML, with more to come in future posts.

> Curious about the whole Dibs Saga? See a [list of all posts on dibs](/dibs-saga).

## Table of Contents

- TOC
{:toc}

## The YAML Way

[dibs][]'s format of election for the configuration file is [YAML][]. In
particular, [dibs][] relies upon [YAML::XS][], which ultimately supports
version 1.1 of YAML.

OK, why YAML then? Simply put, it is readable, sufficiently concise,
normally easy to use too, and allows describing complex data structures
that can contain cross-references around (i.e. a directed graph as opposed
to a simpler tree, like JSON).

This is the first space for reuse available, and you are encouraged to
leverage it liberally.

## Constants

Let's start from an example coming from the [first post][dibs-1]:

{% highlight yaml %}
actions:
    # ...

    bundle-base:
      - from: alpine 3.6
      # ...
      - name: save base image for bundle
        tags: sample-mojo-alien01-bundlebase:latest

    bundle:
      - from: sample-mojo-alien01-bundlebase:latest
      # ...

    # ...

{% endhighlight %}

Here, we moved part of the activities from the previous `bundle` action on
to a `bundle-base` sketch, whose goal is to produce a base image named
`sample-mojo-alien01-bundlebase:latest`. This base image is then used as
the starting point in the *new* `bundle` sketch.

Fact is, there are a couple of issues with this:

- `sample-mojo-alien01-bundlebase:latest` is indeed very long to write and
  proportionally (exponentially?) easy to get wrong
- the time we need to change this name, it must happen in at least two
  places in the configuration file.

YAML aliases to the rescue then:

{% highlight yaml %}
actions:
    # ...

    bundle-base:
      - from: alpine 3.6
      # ...
      - name: save base image for bundle
        tags: &bundlebase sample-mojo-alien01-bundlebase:latest

    bundle:
      - from: *bundlebase
      # ...

    # ...
    
{% endhighlight %}

At least, now we can be sure of a few things:

- getting an alias wrong will make parsing complain loudly, so we're
  protected from typos. This is pretty much what would happen with using
  constants in a program, instead of *magic values*;
- changing the name of the base image is now a piece of cake: just do it
  in one place and you're all set.

You don't necessarily have to stop here anyway. [dibs][]'s configuration
file is not picky about the keys you use (hopefully this will not bite in
the medium-long term), so why not place constants at the beginning?

{% highlight yaml %}
constants:
    - &buildbase  sample-mojo-alien01-buildbase:latest
    - &bundlebase sample-mojo-alien01-bundlebase:latest

actions:
    # ...

    build-base:
      # ...
      - name: save base image for build
        tags: *buildbase

    build:
      - from: *buildbase
      # ...

    bundle-base:
      # ...
      - name: save base image for bundle
        tags: *bundlebase

    bundle:
      - from: *bundlebase
      # ...

    # ...
{% endhighlight %}

All in all, we're just reusing some programming wisdom in structuring the
names of our artifacts.

## Almost Anything, Actually

Nothing stops us from reusing other parts too, which leads us to yet
another way to factor user creation out (in addition to what we saw last
time):

{% highlight yaml %}
constants:
    - &createuserscript |
        #!/bin/sh
        set -e
        exec >&2
        adduser -D -h /app ada
    # ...

actions:
    # ...

    build-base:
      - from: alpine 3.6
      - pack: {run: *createuserscript}
      # ...

    bundle-base:
      - from: alpine 3.6
      - pack: {run: *createuserscript}
      # ...

    # ...
{% endhighlight %}

So, anywhere you see space for factoring things out of the box, just do
it!

## Enough YAML'ing

Well, we're at the end of this post. Release early, release often! Let me
know in the comments what's not clear, or pretty much anything else that
makes sense for this article!


[dibs-1]: /hi-from-dibs
[dibs]: https://github.com/polettix/dibs
[YAML]: https://yaml.org/
[YAML::XS]: https://metacpan.org/pod/distribution/YAML-LibYAML/lib/YAML/XS.pod
