---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Hi from dibs!
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

So... here's [dibs][], which stands for Docker Image Build System. Put it
very, very bluntly... it is what I use instead of `docker build` lately.
It already comes with documentation and many frills, but we will start
very slow and explore features in a series of posts. Buckle up!

> Curious about the whole Dibs Saga? See a [list of all posts on dibs](/dibs-saga).

## Table of Contents

- TOC
{:toc}

## Quick "why dibs"

Why did I start working on [dibs][]? Part is due to my ignorance: I
honestly didn't know about [multistage][] Dockerfiles, and I quickly got
bored of managing it myself.

This is not the whole story though. Another aspect of the Dockerfile
system that is a bit too... *raw* in my opinion is how to execute things.
As far as I know, you either use the `RUN` directive providing a usually
growing list of commands all stitched together with `&&`s, or you put
those commands in a script, `COPY` it into the container, then `RUN` it.
I'd say this is basically what's needed, but not the best from the
usability point of view.

Last, I also grew a bit tired of the caching mechanism provided by Docker
when building images via Dockerfile. Don't get me wrong, it's really neat;
my only concern is that sometimes it led to situations that required some
debugging before figuring out what was going wrong, especially when
building images from a remote repository dynamically cloned via `git`. I
felt that having direct and explicit control over the caching mechanism
would help in a lot of my use cases.

## Example?

In this series of posts I'll be showing examples of growing complexity. In
this starting one there will be actually nothing (I guess) that cannot be
done more or less directly with a Dockerfile, but it's helpful to set the
stage.

The main goal is to generate a Docker image for [sample-mojo][]. This
project is somehow *purely* focused on providing a simple web endpoint,
without wasting too much time on how it will be deployed, apart providing
an [Heroku][]-compatible `Procfile`:

{% highlight text %}
    web: perl ./app.pl daemon --listen "http://*:$PORT"
{% endhighlight %}

and declaring the Perl's dependencies in a `cpanfile`:

{% highlight text %}
    requires 'Mojolicious', '7.08';
{% endhighlight %}

So, we will have to do the heavy lifting:

- install the modules based on the `cpanfile`
- provide a wrapper that uses `Procfile`

This is not all though, we also want:

- avoid bloating the target image, i.e. we don't want any build tools
  inside it
- compile and run under an unprivileged user `ada`, to avoid `root` as
  much as possible`

Hence, the sequence of operations will be like this:

- build the modules in a container were we install all needed building
  tools
- copy the final *complete* application in a temporary cache
- create another container with only the tools needed at runtime, namely
  Perl
- copy the application artifacts from the temporary cache into their final
  position in this container
- put a wrapper script to interpret and execute the `Procfile` in the
  container
- set the proper `ENTRYPOINT`, `CMD` and `USER` on the container
- save the container as image.

## Installing dibs

[dibs][] needs Docker to do anything interesting, so chances are that you
already have Docker. In this case, installing [dibs][] is as simple as
creating the following `dibs` script somewhere in the `PATH`, like this:

{% highlight bash %}
$ cat >dibs <<'END'
#!/bin/sh
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PWD:/mnt" -w /mnt -e "DIBS_HOST_REMAP_DIR=/mnt:$PWD" \
    -- polettix/dibs:0.5 "$@"
END
$ chmod +x dibs
{% endhighlight %}

## Getting The Target Software

In this example, we will work in the so-called *alien mode*, i.e. a mode
where the software to be packaged is not *aware* of [dibs][].

First of all, we will create a directory that will be the base of our
operations. We will call it `alien01`:

{% highlight bash %}
~$ mkdir alien01
~$ cd alien01
{% endhighlight %}

Next, we will get the software, which [dibs][] expects to find in the
`src` sub-directory:

{% highlight bash %}
alien01$ git clone https://gitlab.com/polettix/sample-mojo.git src
{% endhighlight %}

## The Configuration File

[dibs][] works based on a configuration file. In our case, the
configuration is the following YAML file:

{% highlight yaml %}
---
name: dibs-example-sample-mojo

actions:
   default: [build, bundle]

   build:
      - from: 'alpine:3.6'
      - name: build
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add build-base wget perl perl-dev
              adduser -D -h /app ada
              wget -O /bin/cpanm --no-check-certificate https://cpanmin.us/
              chmod +x /bin/cpanm
              cat >/tmp/as-ada.sh <<'END'
              cd /app
              cp -R /tmp/src/* .
              cpanm -l local --notest --installdeps .
              END
              chmod +x /tmp/as-ada.sh
              su - ada /tmp/as-ada.sh
              cp -a /app /tmp/cache

   bundle:
      - from: 'alpine:3.6'
      - name: install
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add perl
              adduser -D -h /app ada
              cp -a /tmp/cache/app /
              cat >/procfilerun <<'END'
              #!/bin/sh
              set -e
              PROCFILE_TYPE="${1:-"web"}"
              export PERL5LIB='/app/local/lib/perl5'
              cd /app
              while read -r type command ; do
                 [ -n "$type" ] || continue
                 [ "x${type%${type#?}}" != 'x#' ] || continue
                 [ "x$type" = "x$PROCFILE_TYPE:" ] || continue
                 exec /bin/sh -c "exec $command"
                 printf >&2 'could not execute command "%s"\n' "$command"
                 exit 1
              done <Procfile
              printf >&2 'invalid process type %s, not in Procfile\n' "$PROCFILE_TYPE"
              exit 1
              END
              chmod +x /procfilerun
        commit:
           entrypoint: [/procfilerun]
           cmd: [web]
           user: ada
      - name: save bundled image
        tags: sample-mojo-alien01:latest
{% endhighlight %}

This file can also be [downloaded here][download-dibs-yml] has to be saved
as `dibs.yml` in the project directory `alien01`.

## Generate The Image

Up to now, the layout of our `alien01` directory should be the following:

{% highlight bash %}
alien01$ ls -l
total 8
-rw-r--r-- 1 poletti poletti 2073 Feb 24 18:18 dibs.yml
drwxr-xr-x 3 poletti poletti 4096 Feb 24 17:18 src
alien01$ ls -l src
total 16
-rwxr-xr-x 1 poletti poletti 234 Feb 24 17:18 app.pl
-rw-r--r-- 1 poletti poletti  32 Feb 24 17:18 cpanfile
-rw-r--r-- 1 poletti poletti  52 Feb 24 17:18 Procfile
-rw-r--r-- 1 poletti poletti 326 Feb 24 17:18 README.md
{% endhighlight %}

If not... look again at the previous sections! Otherwise, let's start
[dibs][]:

{% highlight bash %}
alien01$ dibs --alien
       base configuration from: /mnt/dibs.yml
=====> sketch default
=====> sketch build
-----> prepare (from: alpine:3.6)
       remove tag dibs-example-sample-mojo:20190224-192933-1 if exists
       tag alpine:3.6 to dibs-example-sample-mojo:20190224-192933-1
       tagging alpine:3.6 as dibs-example-sample-mojo:20190224-192933-1
-----> stroke build
       fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
       fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/APKINDEX.tar.gz
       (1/23) Installing binutils-libs (2.30-r1)
       [...]
       (23/23) Installing wget (1.20.1-r0)
       Executing busybox-1.26.2-r11.trigger
       OK: 200 MiB in 36 packages
       --2019-02-24 19:29:39--  https://cpanmin.us/
       Resolving cpanmin.us... 151.101.130.217, 151.101.66.217, 151.101.2.217, ...
       Connecting to cpanmin.us|151.101.130.217|:443... connected.
       [...]
       --> Working on .
       Configuring /app ... OK
       ==> Found dependencies: Mojolicious
       --> Working on Mojolicious
       Fetching http://www.cpan.org/authors/id/S/SR/SRI/Mojolicious-8.12.tar.gz ... OK
       Configuring Mojolicious-8.12 ... OK
       Building Mojolicious-8.12 ... OK
       Successfully installed Mojolicious-8.12
       <== Installed dependencies for .. Finishing.
       1 distribution installed
       committing working container to dibs-example-sample-mojo:20190224-192933-1
       sha256:f4cbc0ec9fa94937ab15ff1c4481edcf9bd5248bc5c687d3801dbadb44cacee7
       removing working container
       2dd042ebc612a352328316b624edeffaf008cce7cd495b01bb860ef6a62867a6
=====> sketch bundle
-----> prepare (from: alpine:3.6)
       remove tag dibs-example-sample-mojo:20190224-192933-1 if exists
       tag alpine:3.6 to dibs-example-sample-mojo:20190224-192933-1
       tagging alpine:3.6 as dibs-example-sample-mojo:20190224-192933-1
-----> stroke install
       fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/main/x86_64/APKINDEX.tar.gz
       fetch http://dl-cdn.alpinelinux.org/alpine/v3.6/community/x86_64/APKINDEX.tar.gz
       (1/2) Installing libbz2 (1.0.6-r5)
       (2/2) Installing perl (5.24.4-r2)
       Executing busybox-1.26.2-r11.trigger
       OK: 40 MiB in 15 packages
       committing working container to dibs-example-sample-mojo:20190224-192933-1
       sha256:fb1aa5f8843953381d7e8608e4bbf956f06ce38d6f39c2fd4604d3244813e871
       removing working container
       e41fcfc70ab2b0d60c9a51624ccd51e0eff877cd397e0f35f6cbaa8504690009
+++++> frame save bundled image
       tagging dibs-example-sample-mojo:20190224-192933-1 as sample-mojo-alien01:latest
       removing tag dibs-example-sample-mojo:20190224-192933-1
       Untagged: dibs-example-sample-mojo:20190224-192933-1
sample-mojo-alien01:latest
{% endhighlight %}

A bit too much to digest? Let's take a look!

### Actions

[dibs][] executes actions, which can be of differen types. You can specify
the type explicitly, but it's normally not needed as it's clear what an
action is about.

At the top level, it always executes a *sketch*, that is a sequence of
other actions (including other sketches). In our case, we didn't specify
any explicit action to be run on the command line, so the `default` sketch
has been selected:

{% highlight yaml %}
actions:
   default: [build, bundle]
{% endhighlight %}

i.e. the actions `build` and `bundle` (which are other sketches
themselves, being lists) have to be executed. This accounts for the
"external" structure of the output:

{% highlight bash %}
alien01$ dibs --alien
       base configuration from: /mnt/dibs.yml
=====> sketch default
=====> sketch build
       [...]
=====> sketch bundle
       [...]
{% endhighlight %}

The two sketches `build` and `bundle` have a similar structure: they
contain a list of actions (they're sketches, after all!) that will result
in something done:

{% highlight yaml %}
actions:
    # ...

   build:
      - from: 'alpine:3.6'
      - name: build
        pack:
           run: |
              #!/bin/sh
              # ...

   bundle:
      - from: 'alpine:3.6'
      - name: install
        pack:
           run: |
              #!/bin/sh
              # ...
        commit:
           entrypoint: [/procfilerun]
           cmd: [web]
           user: ada
      - name: save bundled image
        tags: sample-mojo-alien01:latest
{% endhighlight %}

Actions that contain a `from` should sound familiar to anyone used to
Dockerfiles: its goal is exactly the same, i.e. define the starting point
of a *sequence of container layers*. This action has type *preparation*.

After it, both have an action of type *stroke*, i.e. something that is
executed *inside* the container. This action is characterized by having
a `pack` field inside, which in our case specifies an "immediate program"
that will be executed in the container. There are many other ways of
providing what has to be executed in the container, as we will see in the
future.

Last, the `bundle` sketch also contains a closing action setting the tag
name for the image. This action is of type *frame*. Notice that `build`
does not have a corresponding one: we're simply not interested in the
byproduct of that chain of action, or better we are not interested in
saving the resulting container as an image.

These action types should ring a bell about the metaphor that [dibs][]
adopts: as our goal is to generate an *image*, we assemble one or more
*sketches*, in each of which we first *prepare*, then draw some *strokes*,
then *frame* the result if we are happy with it.

## What Happened?

TL;DR each of the sketches `build` and `bundle` started from the same
image `alpine:3.6` and executed a sequence of commands inside a container.
The program for `build` eventually saved the application with the compiled
modules in a cache staging area; the `bundle` sketch eventually resulted
in saving a container image that contains only the strict necessary for
running the program, without building tools.

If you look carefully at all operations, you will see that we indeed stick
to all requirements: the final image is not bloated with unnecessary
tools, compilation is done under user `ada`, as well as packing and
execution, the `ENTRYPOINT` and `CMD` are set right, ...

As it is now, though, there's little advantage over using a Dockerfile to
give to `docker build`:

- it's easier to provide the sequence of commands to be executed, because
  you pass the text of a proper shell script instead of a single, long
  escaped line to be fed to `/bin/sh -c`
- the process is much heavier though, each run of the whole sequence
  starts from scratch and does not reuse anything already done.

## Make `build` More Efficient

[dibs][] allows you to have direct control over caching, so there's some
more work to do but it allows us to always keep control of things.

The build process can be divided into a few phases:

- creation of user `ada`
- installation of build tools
- installation of pre-requisites specific to the program (which amounts to
  nothing in our case)
- compilation of modules

Our strategy will be to divide the `build` sketch into phases, and save
the places that we find interesting for reuse.

{% highlight yaml %}
actions:
    # ...

    build-base: # new sketch for preparing a cached base image
      - from: alpine 3.6
      - name: base image preparation
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add build-base wget perl perl-dev
              adduser -D -h /app ada
              wget -O /bin/cpanm --no-check-certificate https://cpanmin.us/
              chmod +x /bin/cpanm
              #
              # WE STOP HERE, no compilation at this stage!
              #
      - name: save base image for build
        tags: sample-mojo-alien01-buildbase:latest

    build:
      - from: sample-mojo-alien01-buildbase:latest
      - name: build user: ada pack: run: | #!/bin/sh set -e exec >&2 cd
        user: ada
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              cd /app
              cp -R /tmp/src/* .
              cpanm -l local --notest --installdeps .
              cp -R /app /tmp/cache

    # ...

{% endhighlight %}

It's easy to see what we're doing here: the old `build` has been split
into two parts:

- `build-base`, which does most of the heavylifting preparing everything
  for the later compilation phase, but without doing it.
- `build` now only strictly executes the compilation of modules and saves
  stuff in the cache. Note that we don't have to use the `su - ada` trick
  to execute the build part as user `ada`, because `dibs` can execute that
  part as `user: ada`.

Now, the typical invocation pattern would be as follows:

{% highlight bash %}
# build the base image, once at the beginning
$ dibs --alien build-base
# ...
#
# now, execution of the build phase is much faster
$ dibs --alien
# ...
# get updates from remote repository into src, then regenerate image
$ cd src
$ git pull
$ cd ..
$ dibs --alien
{% endhighlight %}


## Make `build` even more efficient

As it turns out, our program is not installing modules like crazy, so we
can use a bit of caching for it too. We already leveraged `/tmp/cache` as
a mechanism to let different actions *communicate* with each other (e.g.
to pass the compiled application from `build` to `bundle`), but nothing
prevents us from using it also across different `build`s:

{% highlight yaml %}
actions:
   # ...

   build:
      - from: sample-mojo-alien01-buildbase:latest
      - name: build
        user: ada
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              cd /app
              cp -R /tmp/src/* .

              # REUSE past compilations if available
              if [ -d '/tmp/cache/app/local' ] ; then
                 cp -R /tmp/cache/app/local /app
              fi

              cpanm -l local --notest --installdeps .
              cp -R /app /tmp/cache

   # ...
{% endhighlight %}

In this way, we're going also to reuse compilations by `cpanm` every time
the `/tmp/as-ada.sh` script is executed during the build phase, saving
more time.

## Enhancing `bundle`

The `bundle` sketch can use some enhancements too, because it re-creates
the whole thing from scratch over and over, whereas use creation and
runtime installation might be factored out and cached, much like what
happened with `build`.

At this point, it's also meaningful to think that the user creation
process might be factored out between `build` and `bundle`, as they have
the same goal. To do this, there are a few strategies:

- build a base image for the runtime, then use it as the base for the
  build base image
- build a pre-base image with user creation only, then use that as base
  image for the bundle base image and the build base image
- factor the user creation process out and reuse it in different sketches.

We will look into the three alternatives in the following sub-sections,
but in all cases we end up with a new
`sample-mojo-alien01-bundlebase:latest` image that we will use as starting
point for bundling, like this:

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

Let's take a closer look at the three alternatives now.

### Bundle As Global Base

If we look into the bundle image carefully, we see that its pre-requisites
are also in the build image, so why not use it as a starting point? This
is our first alternative approach:

{% highlight yaml %}
actions:
    # ...

    bundle-base: # new sketch for preparing a cached base image
      - from: alpine 3.6
      - name: bundle base image preparation
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add perl
              adduser -D -h /app ada
      - name: save base image for bundle
        tags: sample-mojo-alien01-bundlebase:latest
    
    build-base:
      - from: sample-mojo-alien01-bundlebase:latest
      - name: build base image preparation
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add build-base wget perl-dev
              wget -O /bin/cpanm --no-check-certificate https://cpanmin.us/
              chmod +x /bin/cpanm
      - name: save base image for build
        tags: sample-mojo-alien01-buildbase:latest

    # ...

{% endhighlight %}

The advantage of this approach is that is quite simple; the drawback is
that the bundle image might evolve in a direction that includes tools that
are not needed for building. This might be a problem or not depending on
circumstances; anyway, the build image is usually more bloated anyway, so
it should not be an issue in the average case.

### Common Pre-Base Image

A more "normalized" way of doing things would be to factor common
operations like user creation in a single, simpler base image, then use it
as a *pre-base* for generating two separated build image and a bundle
image, which can then evolve independently:

{% highlight yaml %}
actions:
    # ...

    base: # new sketch for preparing a cached base image
      - from: alpine 3.6
      - name: base image preparation
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              adduser -D -h /app ada
      - name: save base image
        tags: sample-mojo-alien01-base:latest

    bundle-base: # new sketch for preparing a cached base image
      - from: sample-mojo-alien01-base:latest
      - name: bundle base image preparation
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add perl
      - name: save base image for bundle
        tags: sample-mojo-alien01-bundlebase:latest

    build-base:
      - from: sample-mojo-alien01-base:latest
      - name: build base image preparation
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add build-base wget perl-dev perl
              wget -O /bin/cpanm --no-check-certificate https://cpanmin.us/
              chmod +x /bin/cpanm
      - name: save base image for build
        tags: sample-mojo-alien01-buildbase:latest

    # ...

{% endhighlight %}

The advantage of this approach is that the base image can then easily be
put into a separate process, e.g. managed by another team.

### Factoring a Common User Creation Stroke

In this case, the user creation process is a stroke by itself, defined
once and reused by the base images:

{% highlight yaml %}
actions:
   # ...

    create-user:
        pack:
           run: |
              #!/bin/sh
              set -e
              exec >&2
              adduser -D -h /app ada

    build-base:
      - from: alpine 3.6
      - create-user
      - name: base image preparation
        pack:
           # NOTE: no user creation in the script below
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add build-base wget perl perl-dev
              wget -O /bin/cpanm --no-check-certificate https://cpanmin.us/
              chmod +x /bin/cpanm
      - name: save base image for build
        tags: sample-mojo-alien01-buildbase:latest

    bundle-base:
      - from: alpine 3.6
      - create-user
      - name: base image preparation
        pack:
           # NOTE: no user creation in the script below
           run: |
              #!/bin/sh
              set -e
              exec >&2
              apk --no-cache add perl
      - name: save base image for bundle
        tags: sample-mojo-alien01-bundlebase:latest

   # ...
{% endhighlight %}

The advantage of this approach is that it's more visually clear what's
going on in the preparation of each base image, because there's less
referencing around to other base images.


## Where Are We Now?

At this point, I guess, we're somewhere very near to what a [multistage
Dockerfile][multistage] can do: we have a chain for building, another one
for packaging a lean final image with our application, and there's some
caching to help us speed up things.

Now for the second reason why I wanted a tool like [dibs][]: ease of
reuse. I already find [dibs][]'s way of expressing actions inside
a container better than the lower-level `RUN` provided by a Dockerfile,
but this is just the tip of the iceberg... as we will discover in our next
post!

The complete configuration file for this stage can be found
[here][final-dibs-yml], considering the third alternative in the previous
section.



[dibs]: https://github.com/polettix/dibs
[multistage]: https://docs.docker.com/develop/develop-images/multistage-build/
[sample-mojo]: https://gitlab.com/polettix/sample-mojo
[Heroku]: https://www.heroku.com/
[download-dibs-yml]: {{ site.url }}/assets/files/dibs-intro/10-alien/dibs.yml
[final-dibs-yml]: {{ site.url }}/assets/files/dibs-intro/10-alien/final/dibs.yml
