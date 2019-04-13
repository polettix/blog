---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Dibs - Envars Envisaged As Enviles
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

In a previous post ([meet the packs][dibs-3]) we saw that there's more
than one way to make your packs generic and avoid the dreaded
copy-and-paste syndrome. In particular, environment variables can come to
the rescue, but this comes at a cost: whenever you define an environment
variable when calling Docker, and save the container, it's there to remain
(unless overridden, of course). Do we really need this?


## Table of Contents

- TOC
{:toc}



## Environment Over Arguments

The simple answer might just be that if we don't want to pollute the
environment, we just don't do it. This was probably a bad joke, I promise
that I didn't mean that.

Sometimes environment variables are superior to command line arguments
because they can be draw directly from the calling environment itself. As
an example, consider the following fragment:

{% highlight yaml %}
packs:
  example:
    run: |
      #!/bin/sh
      exec >&2
      printf '%s\n' "Hello $WORLD! Happy $HOLIDAY!"
actions:
  # ...
  override:
    name: call scripts with overridden environment
    pack: example
    env:
      - WORLD: You
      - HOLIDAY: Easter

  get-from-outside:
    name: call scripts with overridden environment
    pack: example
    env:
      - WORLD
      - HOLIDAY
{% endhighlight %}

When `override` is called, it's just like we say in the previous article:
environment variables are set and the string `Hello You! Happy Easter!` is
printed out.

On the other hand, when `get-from-outside` is executed, the `WORLD` and
`HOLIDAY` values are taken from the environment as seen by the process
that is running `dibs` itself, so you can put whatever you want:

{% highlight bash %}
$ WORLD=Everyone HOLIDAY='New Year' dibs ...
{% endhighlight %}


## So How To Avoid Pollution?

There are a host ways to avoid polluting the container's environment, and
we will discover them in due time: functions to put environment variables
in the argument list, saving stuff in files, etc.

BUT.

If you think that taking stuff from the environment calling `dibs` is too
neat to ditch away, you're in good company because I do as well. This is
why *enviles* exist: the ease of *env*ironment variables, but bottled into
f*iles* that are 100% biodegradable and leave no trace in the environment.
In the definition of the stroke, just change `env` into `envile` and
you're done:

{% highlight yaml %}

packs:
    # ... stay tuned for how to use enviles! ...

actions:
  # ...
  override:
    name: call scripts with overridden environment
    pack: example
    envile:
      - WORLD: You
      - HOLIDAY: Easter

  get-from-outside:
    name: call scripts with overridden environment
    pack: example
    envile:
      - WORLD
      - HOLIDAY
{% endhighlight %}

It works exactly as before: defines a **key**-**value** pair, optionally
taking it from the calling environment (in the case of
`get-from-outside`). The result is that a file named after the **key** is
saved, holding the **value** as the file's content.

This means, of course, changing a bit our script to take this into
account, but let's proceed with order.

### Where Are My Enviles?

First of all: where does the container find the enviles? Turns out they
are in the simplest place possible: the current working directory. In
other terms, when `dibs` calls the container, it creates a directory with
all the enviles inside, mounts it inside the container and then runs it
setting that directory as the working directory.

Hence, for example, the script to print out the message might be changed
as follows:

{% highlight yaml %}
packs:
  example:
    run: |
      #!/bin/sh
      exec >&2
      WORLD="$(cat WORLD)"
      HOLIDAY="$(cat HOLIDAY)"
      printf '%s\n' "Hello $WORLD! Happy $HOLIDAY!"
{% endhighlight %}

At this point, if you think it's important, it's safe to also export those
variables in the environment: they will not be written in the stone of the
new container image layer.

### Wasn't Lazyness A Virtue?

If you're lazy - or you're in the mood for it - you can export all enviles
in the environment using the provided shell script `export-enviles.sh`,
again in the current directory. So our example turns to this:

{% highlight yaml %}
packs:
  example:
    run: |
      #!/bin/sh
      exec >&2
      . export-enviles.sh
      printf '%s\n' "Hello $WORLD! Happy $HOLIDAY!"
{% endhighlight %}

It's important that you *source* the script and don't execute it...
otherwise you'll be exporting in a sub-process and will not get the
variables!

The trick above works for any number of enviles, so it's a reasonable
addition to your shell scripts if you want to go the envile route.


## Notable Enviles

It turns out that Dibs itself uses enviles to provide some dibs-specific
information to the programs that run in containers, should they need it.
Hopefully the list is going to grow, but as of this post you should at
least find the following:

- **running info**: some info about the current run, like:
  - `DIBS_ID`: and identifier for the run of dibs;
  - `DIBS_STROKE_NAME`: the name assigned to the stroke that is running;
  - `DIBS_DATE`: the date of execution of this run of dibs;
  - `DIBS_TIME`: the time of executiom of this run of dibs;
  - `DIBS_EPOCH`: the Unix epoch of execution of this run of dibs.

- **directories**: as we will see, Dibs relies on a few directories that
  are mounted from the host filesystem into the container's filesystem to
  bridge the two worlds. The exact position of each of these directories
  is available in the associated envile:
  - `DIBS_DIR_SRC`
  - `DIBS_DIR_CACHE`
  - `DIBS_DIR_ENVILE`
  - `DIBS_DIR_ENVIRON`
  - `DIBS_DIR_PACK_DYNAMIC`
  - `DIBS_DIR_PACK_STATIC`

## Wrap Up

This should be all you need to know about enviles, let's recap:

- Dibs provides an easy way to set environment variables passed in
  a *stroke*, either setting them directly in the configuration file
  `dibs.yaml` or getting from the surrounding environment (i.e. the
  environment as seen by the `dibs` process);
- passing environment variables in a Docker container's execution is going
  to permanently write that environment variable in the container image
  layer, which might not always be what you want/need;
- enviles provide a way around this, allowing you to effortlessly pass
  environment variables as files which can be later read in your program;
- as an added bonus, if your program is a shell script there's even a way
  to export all enviles in the environment, requiring a single line
  addition to a script that would normally work with environment
  varieables;
- Dibs also sets some enviles to provide information that your programs
  might find useful, e.g. a run identifier (which you might include in
  a version tag, for example) or the position of different directories in
  the container's filesystem.

Comments below, until next time have fun!


[dibs]: https://github.com/polettix/dibs
[dibs-1]: /hi-from-dibs
[dibs-2]: /dibs-yaml-reuse
[dibs-3]: /dibs-meet-the-packs
[dibs-4]: /dibs-remote-packs
