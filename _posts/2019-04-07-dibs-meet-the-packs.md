---
# vim: sts=4 ts=4 sw=4 expandtab syn=off :
layout: post
title: Dibs - Meet The Packs
image:
  feature: kakadu-pellicani.jpg
  credit: Pellicani al Kakadu National Park, Australia
  creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

This is the first post about [dibs][] ([first here][dibs-1] and [second
here][dibs-2]) and it should be clear by now that the main goal of Dibs
(at least "over" using a plain Dockerfile) is *reuse*. This time we take
an introductory look at *packs*, which per-se allow easily reusing stuff
in a slightly less *copy & paste* way; we will see in a future installment
how this can be further leveraged for a more *modern* way of sharing and
reusing things.

## Table of Contents

- TOC
{:toc}


## First Look At Packs

We already looked at packs, e.g. in our [first article][dibs-1] we can find
this:

{% highlight yaml %}
actions:
# ...
   build:
      # ...
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
{% endhighlight %}

It turns out that a *sketch* action (any sketch action!) needs a *pack* to
know what should be factually done inside the container. Hence, you will
always see something like this:

{% highlight yaml %}
actions:
# ...
   some-sketch-action:
      pack: # ... whatever defines the pack
      # ...
{% endhighlight %}

The example above with the `run` section was just possibly the simpler
kind of *pack*, that is one whose implementation is fit directly inside
Dibs's configuration file. There can be more, of course.

## A Library Of Packs

The next "simple" place where you can put a *pack* is an executable
program (be it a shell script of anything that you can run inside the
target container). Where should you place this file eventually? There are
a few options, but for the moment we will play it easy and opt for the
`pack` sub-directory of the project directory.

Evolving our previous example, we can fit the shell script in a file
inside `pack`, e.g. `pack/kickoff.sh`:

{% highlight bash %}
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
{% endhighlight %}

Then, we change the configuration file to use it:

{% highlight yaml %}
actions:
# ...
   build:
      # ...
      - name: build
        pack:
            project: kickoff.sh
{% endhighlight %}

The same script might be reused multiple times across the same
configuration file. We already learned to use YAML variables to avoid
repetition, but there's a semantic way to do this as well, i.e. put
definition of *packs* inside a `packs` section at the top level, like
this:

{% highlight yaml %}
packs:
   kickoff: # we choose the "explicit" way, it's the same as above
      type: project
      path: kickoff.sh
actions:
# ...
   build:
      # ...
      - name: build
        pack: kickoff    # same name inside "packs" above
{% endhighlight %}

In this way, you can save your scripts as standalone files and manage
(e.g. edit, track, etc.) individually with little effort to eventually
call them during container build-up.

## `args`: Making Packs More Reusable

A program that only does one thing in the same way might become dull very
quickly and leave you the temptation to copy and paste to get something
slightly different. Dibs actively wants you to stop this waste!

When you call a program in a pack, you can also pass arguments that will
appear as command-line arguments to the program itself. As an example,
save this as `pack/alpine-packs.sh`:

{% highlight bash %}
#!/bin/sh
set -e
exec >&2
apk --no-cache add "$@"
{% endhighlight %}

Now you can have this kind of definition:

{% highlight yaml %}
packs:
   alpine_packs:
      type: project
      path: alpine-packs.sh
actions:
# ...
   build:
      # ...
      - name: Install OS packs
        pack: alpine_packs
        args:
           - build-base
           - wget
           - perl
           - perl-dev
   # ...
   bundle:
      # ...
      - name: Install OS packs
        pack: alpine_packs
        args:
           - perl
{% endhighlight %}

## ... And, Of Course, Environment Variables

Command-line arguments via options `args` are not the only way to tell
your programs about behaving differently. Another way would be defining
environment variables instead, via the `env` key. The following example
transforms the one in the previous section to use an environment variable
with the list of space-separated packages to install.

Save this as `pack/alpine-packs-env.sh`:

{% highlight bash %}
#!/bin/sh
set -e
exec >&2
# CAUTION: no quotes around expansion of ALPINE_PACKAGES
apk --no-cache add $ALPINE_PACKAGES
{% endhighlight %}

Now you can have this kind of definition:

{% highlight yaml %}
packs:
   alpine_packs_via_environment:
      type: project
      path: alpine-packs-env.sh
actions:
# ...
   build:
      # ...
      - name: Install OS packs
        pack: alpine_packs_via_environment
        env:
           - ALPINE_PACKAGES: 'build-base wget perl perl-dev'
   # ...
   bundle:
      # ...
      - name: Install OS packs
        pack: alpine_packs_via_environment
        env:
           - ALPINE_PACKAGES: 'perl' 
{% endhighlight %}

## Enough For Now

Today we learned:

- you can place your programs (e.g. scripts) in standalone files inside
  the project tree and avoid bloating your configuration file
- it is very, very easy to use these outside-placed programs from
  *sketches*
- you have at least a couple ways to make these programs generic, i.e.
  either make them accept command-line arguments, or work based on
  environment variables.

There's more than this... but it's enough for now. As usual, let me know
what you think in the comments.

[dibs]: https://github.com/polettix/dibs
[dibs-1]: /hi-from-dibs
[dibs-2]: /dibs-yaml-reuse
[YAML]: https://yaml.org/
[YAML::XS]: https://metacpan.org/pod/distribution/YAML-LibYAML/lib/YAML/XS.pod
