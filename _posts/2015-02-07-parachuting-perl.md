---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: Parachuting Perl
image:
   feature: pink-lake.jpg
comments: true
---

I'm probably not the only one in the world to work in an Enterprise-like
world. Which basically boils down to little Perl knowledge (at least
in the admittedly few Enteprises I got in contact with) and usage of
streamline Linux distribution with horribly old Perl versions.

What I'm probably, again, not the only one in the world to do is to
just set up *my* own `perl` installation for usage by my applications. This
makes me comfortable about what I'm going to use, without messing with
the system's `perl`. After that, of course, there comes the problem of
many possible applications living together... so I have to cope with
this as well.

One additional problem that might kick-in is when I have to use a different
`perl` version for an application. As an example, I recently discovered
[Regexp::Grammars] is compatible with `perl` starting from version 5.10, but
only if different from 5.18... so what if my environment is 5.18? There might
be the need to handle different `perl` installations too, then.

[Regexp::Grammars]: https://metacpan.org/pod/Regexp::Grammars

There are currently a lot of tools that simplify the task of having
one's own `perl`, keeping a private library for an application, possibly
shipping also the modules because there's no connectivity to the
Internet... let's see one possible workflow.

## The Plan

The plan is very simple:

1. install [plenv] to address the possibility of multiple Perl versions. It
   is quite lean and it seems to do its work without getting too much in
   the way
2. build a private `perl` through [perl-build], which can be installed as
   a plugin of [plenv], so that we can use `plenv` only
3. install [cpanminus] (a.k.a. `cpanm`) to easily handle module installation
   later. Again, this can be handled as a plugin of `plenv`, we'll see how
4. declare the dependencies of our application in the root directory of the
   application itself, through a `cpanfile` declaration.
5. use [carton] to handle the installation of an application-private library
   of code from the dependencies, so that we will be able to decouple from
   the shared libraries installed in whatever `perl` we will use. This allows
   e.g. to have two different application use two different versions of a
   library, but leverating on the exact same `perl` installation. Carton
   will also help us run our application with the right environment, more on
   this later.

[plenv]: https://github.com/tokuhirom/plenv
[perl-build]: https://metacpan.org/pod/distribution/Perl-Build/script/perl-build
[cpanminus]: https://github.com/miyagawa/cpanminus
[carton]: https://metacpan.org/pod/Carton

Should you have your development and deployment environment equal to each
other? Yes and no. For example, I already have [perlbrew] installed on my
dev machine, and the shift to [plenv] is something to do with a bit of
calm... so as long as I'm sure that I use the same `perl` version in the
two places I should be fine. This means that steps 1..3 above will in
general be a pre-requisite on the target deployment machine, while
steps 4 and 5 are more on the development machine.

So let's start!

## Deployment Environment Set-Up

Depending on the target machine you will be using, it might be easy or
impossible to actually install your own `perl` and its modules (especially
when compilation is needed). If this is the case, try to see if you can
create a compatible environment somewhere else, e.g. in a virtual machine
in your computer or online, so that you can be pretty sure that when you
copy things over you will be fine.

In the following, then, we will assume
that the deployment machine is equipped with all the tools needed to
compile and install `perl` and modules, which e.g. for a Debian release
would mean ensuring that package `build-essentials` is in place, with
the addition of a system `perl`, `curl` and `git`. For other
*enterprise*-like distributions like RHEL and SLES there are the
applicable package managers, otherwise you will have to roll your own!

Before starting, we have to note that there is absolutely no need to
be `root` here. As a matter of fact, it's probably better *not* to be
`root` at all.

### [plenv]

The installation of [plenv] is (or can be) as simple as cloning its
repository on GitHub. We'll also take care to install the other tools
as suggested by the documentation, that I will blatantly copy here (or so):

    cd ~
    git clone git://github.com/tokuhirom/plenv.git .plenv

Now it's time to add `~/.plenv/bin` to your `PATH` environment variable.
Where it is stored/set is actually a matter of the system you are in,
so your mileage may vary with the suggestion provided in the [plenv]
documentation. Good places to look are:

* `~/.bashrc` or `~/.bash_profile` or `~/.profile` if you're using bash
* `~/.zshrc` if you're using zsh
* whatever provided by the other shells

You can either edit the place where `PATH` is set, or add a line like this
at the end (file and syntax depend from the shell and considerations above):

    echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bashrc

At this point, you can execute the following and have [plenv] *visible*
in your shell:

    exec "$SHELL" -l

Time for initializing [plenv] now. A sub-command tells you what to add
to the file you modified for the `PATH` variable, just run:

    plenv init -

and look carefully at the output. For example, I have (more or less) this:

    export PATH="$HOME/.plenv/shims:${PATH}"
    export PLENV_SHELL=bash
    source '$HOME/.plenv/libexec/../completions/plenv.bash'
    plenv() {
        local command
        command="$1"
        if [ "$#" -gt 0 ]; then
            shift
        fi

        case "$command" in
        rehash|shell)
            eval "`plenv "sh-$command" "$@"`";;
        *)
            command plenv "$command" "$@";;
        esac
    }


If it's OK with your policies, then you can proceed in installing those
lines like you did for `PATH` modification above. Actually, what is
suggested by the author of [plenv] is to add this:

    echo 'eval "$(plenv init -)"' >> ~/.bash_profile

which is less save than installing the lines above. Unless you are going
to update [plenv] in the future (e.g. with `git pull` at some time) you're
fine, but if you do update you might end up with less secure things
happening during that `init` process that would be executed at every
login... the choice is yours to take. My only consideration is that you
probably already rely upon work done by complete strangers, and this seems
more or less the same situation.

Again, to make the changes happen you have to update your shell:

    exec "$SHELL" -l

### Plugging [perl-build] in

[Perl-build][perl-build] is a separate tool from the same author, and
is targeted at assisting in the installation of a new `perl`. Being from
the same author, anyway, makes it easy to integrate with [plenv], which
is what we will do here:

    git clone git://github.com/tokuhirom/Perl-Build.git \
       ~/.plenv/plugins/perl-build

Yes, this is it!

### Your first `perl`

It's time for some serious compilation now. Make sure you know which
`perl` version you need, and ask [plenv] to install it (it will use
[perl-build] behind the scenes for the heavy-lifting):

    plenv install 5.20.1  # use *your* perl version of course!

Wait a few minutes for the installation to complete, then let [plenv]
regenerate the *shims*:

    plenv rehash

Now, this is written in the documentation and I respect it, but I
wonder whether this step is really necessary and, if it is, why at
all. Can't this be done as the final part of `plenv install ...`?
Maybe it is (looking at the contents of `~/.plenv/shims` it appears
to be so) and I can't read the documentation properly, go figure.

### Installing [cpanminus]

Another capability offered by [plenv] is to install [cpanminus]. I think
most know it today, so I'll not add anything on it.

I don't really like do to this using [plenv] though, because especially
in deployment machines I prefer to use the *fatpacked* self-containing
version. We already added a couple of directories to the `PATH`, so
we will install it in one of them:

    # you can do this with wget as well, of course
    curl -L 'https://github.com/miyagawa/cpanminus/raw/devel/cpanm' \
        > ~/.plenv/bin/cpanm
    chmod a+x ~/.plenv/bin/cpanm

This should Just Work.


### Time to pack...

The deployment server is ready at this point. Ok, sort of at least for my
taste.

First of all there's a lot of cruft left by [plenv] after installing
`perl`, so I usually get rid of it:

    cd ~/.plenv
    rm -rf build cache

For perl 5.20.1 this saved me some 170+ MB, which are not bad when you
eventually have to pack it all for distributing into multiple deployment
machines. What I ended up was about 66 MB that shrink down to about 17 MB
after bzip2 compression, so it's perfectly acceptable to have human
transfer time (unless your datacenter has shiny gigabit or multi-gigabit
networking equipment).

Another thing that I like to have around is a script for making the
changes to the shell initialization when I will carry the whole
package around (because I usually have to). So I save something like this
inside `~/.plenv/bin/colonize.sh and provide execution permissions to it:

{% highlight bash %}
#!/bin/bash
#
# usually saved as ~/.plenv/bin/colonize.sh

# change the target according to what your system has, e.g.
# ~/.profile or ~/.bash_profile or ~/.zshrc or...
target="$HOME/.bashrc"

if grep '^export PATH=.*/\.plenv/bin' "$target" >/dev/null 2>&1 ; then
    echo "plenv already set-up in this system" >&2
    exit 0
fi

cat >>"$target" <<'END'

export PATH="$HOME/.plenv/bin:$PATH"
eval "$(plenv init -)"
END
{% endhighlight %}

At this point we're really ready to pack (feel free to substitute the `j`
with e.g. a `z` if your system does not have `bzip2` installed):

    cd ~
    tar cvjf myperl.tar.bz2 .plenv

To install it into another (equivalent) deployment machine you just
have to transfer the file, unpack and *colonize*:

    scp myperl.tar.bz2 "$user"@"$remote":/tmp
    ssh "$user"@"$remote" \
        'cd ~ && tar xvf /tmp/myperl.tar.bz2 && ./plenv/bin/colonize.sh'

## Development Environment Set-Up

You might have a brand new development machine and follow the steps above
to set it up exactly like a deployment one: congratulations! Otherwise, you
should at least ensure that when testing in your dev machine you are
using the same `perl` version as you installed in the deployment machines,
with similar compilation options (e.g. with or without threads).

In the following, we will take the hard way and assume that you don't have
[plenv] in the development machine. This is what I have today, so whatever
I write here wouldn't be tested if I assumed that [plenv] is used in the
dev machine.

It's now time to concentrate on the application. Assuming it lives in its
own directory, with proper version control set up (e.g. `git`), we have to
ensure that non-core modules are properly tracked, and [carton] will help
us out on this.

### Dependencies handling with [carton]

Installing [carton] should not be a problem. You can do it via
[cpanm][cpanminus] on the `perl` that you use on the development
machine.

You declare your dependencies in a `cpanfile` inside the root of your
project, like this:

    # This is file "cpanfile"
    requires 'Log::Log4perl::Tiny', '1.2.6';
    requires 'Template::Perlish';
    requires 'JSON', '2.59';

As you can see, you can either specify the module version - e.g. because
you know that the specific version has a particular feature - or not. At
this point, [carton] helps you install these modules in a local directory
called `local`:

    carton install

The first time you run this it will create the `local` directory and put
all installed modules there. Another important file that is created
is `cpanfile.snapshot`, that records the `cpanfile` and the results
of the installation in a manner that will allow the exact re-creation
of the environment created here. At this point `git` will be complaining
about these new files:

* you definitely want `cpanfile` and `cpanfile.snapshot` to be tracked by
  `git`. The first helps you keep track of what you need, the second will
  allow you to recreate the environment multiple times, and will help
  anyone that wants to collaborate too. We'll see how in a moment.
* you definitely do *not* want to track `local`. At the point where you
  have the instructions to recreate it with `cpanfile.snapshot`, it does
  not make sense to move it around. And, as you probably already guessed,
  it will probably be difficult to move compiled modules around, unless
  your development environment matches the deployment one perfectly (or
  so).

Which basically boils down to something like this:

    echo local/ >> .gitignore
    git add .gitignore cpanfile cpanfile.snapshot
    git commit -m 'using carton dependencies handling'

### Running applications

Carton has its own way of helping you start applications with the
right environment:

    carton exec program option option option...

It also plays well with [plenv], so if you set up a *local* version of
`perl` with it it will use that. My impression is that it fiddles with
`PERL5LIB` to point towards the `local` directory that was created.

Another approach that does not require you to wrap your application
calls via [carton] - which might get annoying - is to set up usage
of the `local` library directly from your application. You probably
already do something like this if you store most of your code inside
the `lib` directory:

    use FindBin '$Bin';
    use lib "$Bin/../lib", "$Bin/../local/lib/perl5";

## Workflow

These are my suggestions for the update of the distributions. In my
case, the deployment machines do not have `git` installed (it was on
the first one for installing [plenv] but it is not a requirement) so
I do my deployments with good ol' tarballs (well, I use [deployable]
but it's another story).

[deployable]: http://repo.or.cz/w/deployable.git

### Application Deployment Environment

I use this kind of layout:

    - application-container
        - application -> distro/application-2.0
        - distro
            - application-1.0
                - etc -> ../../etc
                - local -> ../../local
                - vendor -> ../../vendor
            - application-1.2
                - etc -> ../../etc
                - local -> ../../local
                - vendor -> ../../vendor
            - application-2.0
                - etc -> ../../etc
                - local -> ../../local
                - vendor -> ../../vendor
        - etc
        - local
        - vendor

There is a higher level container directory that will hold the different
releases and also all local data, i.e. data that are specific to the
installation in the deployment server. In this example, they will be the
`etc`, `local` and `vendor` directories, but there might be more of course.

New packages are deposited and expanded inside the `distro`, where you can
find the different releases in case quick rollback is needed. Installing
a new release is as simple as:

* expanding the new tarball inside `distro`
* create the symbolic links to link back to `etc`, `local` and `vendor`
  (these might be part of the tarball itself)
* move the `application` symbolic link to point towards the new release
  from a previous one.

What's the `vendor` directory for then? Most of the times the deployment
machines are not connected to the Internet, and so you have to carry the
dependencies with you somehow. [Carton][carton] allows you to create a
bundle of these modules like this:

    carton bundle

and this will create a `vendor` sub-directory with all the needed stuff.
If you go this route, the suggestion is to put `vendor/` too inside
`.gitignore`.

### Deployment Strategy

Before the very first deployment, you will have to create the
directory layout described above:

    cd /path/to/application/parent
    mkdir -p application-container/{distro,etc,local,vendor}

For your application you create a distribution tarball, e.g.
`application-2.0.tar.bz2`, and transfer it into the deployment
machine inside `application-container/distro`. You can begin the
installation then:

    tar xvf application-2.0.tar.bz2
    cd application-2.0
    ln -s ../../etc
    ln -s ../../local
    ln -s ../../vendor

Most the times you will not need to install new dependencies, but
sometimes (e.g. the very first time) you will. If this is
the case, you can generate the bundle of the dependency files
inside the development machine:

    carton bundle
    tar cvjf dependencies.tar.bz2 vendor

and then transfer this bundle in the deployment machine and install
it (we will assume that `application-container/distro` is going to
keep all our packages):

    cd /path/to/application-container
    tar xvf distro/dependencies.tar.bz2
    cd application-container/distro/application-2.0
    carton install --deployment --cached

Last step is to activate the release:

    cd /path/to/application-container
    rm -f application
    ln -s distro/application-2.0 application

and restart your application, if applicable.

Congratulations! You're ready to start using your application!
