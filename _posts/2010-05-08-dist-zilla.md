---
# vim: ts=4 sw=4 expandtab syn=off tw=72
layout: post
title: 'Giving Dist::Zilla a try'
keywords: 'perl, dzilla, cpan'
image:
   feature: tramonto.jpg
   credit: Tramonto in Australia
   creditlink: https://en.wikipedia.org/wiki/Australia
comments: false
---

I’m just new to [Dist::Zilla],
so these are the records of what I found about it... If you're impatient
and only want the results, go to [The Lucky Path](#the-lucky-path)
section below, otherwise keep reading!

[Dist::Zilla]: https://metacpan.org/pod/Dist::Zilla

### Installation

The installation was more or less flawless. There are a number of
modules that get installed, other get updated. Curiously enough, the
installation for [Dist::Zilla] itself went wrong due to [a bug in perl
5.8.x](http://rt.perl.org/rt3/Public/Bug/Display.html?id=3038)’s regular
expression operator `qr` that triggers an error in one of the tests.

### Starting a new module

This step requires you to do work! From the
[official tutorial](http://dzil.org/) (as of May 8, 2010):

> This document will be overhauled when dzil new is more useful.<br/>
> For now, we won't even cover the new command, because it's so pointless.

So let's follow [the hints here](http://dzil.org/tutorial/new-dist.html)
and create something:

{% highlight text %}
~/dzilla$ mkdir Sample-Module
~/dzilla$ cd Sample-Module
~/dzilla/Sample-Module$ mkdir t
~/dzilla/Sample-Module$ mkdir -p lib/Sample
~/dzilla/Sample-Module$ vi t/00-load.t
~/dzilla/Sample-Module$ showfile t/00-load.t

|  # vim: filetype=perl :
|  use strict;
|  use warnings;
|
|  use Test::More tests => 1; # last test to print
|
|  BEGIN {
|     use_ok('Sample::Module');
|  }
|
|  diag("Testing Sample::Module $Sample::Module::VERSION");

~/dzilla/Sample-Module$ vi lib/Sample/Module.pm
~/dzilla/Sample-Module$ show lib/Sample/Module.pm

|  package Sample::Module;
|  use strict;
|  use warnings;
|  use English qw( -no_match_vars );
|  use Carp;
|
|  1;
|  __END__

~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|  name    = Sample-Module
|  author  = Flavio Poletti <polettix@cpan.org>
|  license = Perl_5
|  copyright_holder = Flavio Poletti
|  
|  [@Basic]
{% endhighlight %}

In case you're wondering, I'm working in Linux and the `show`
stuff above is a shell function defined as follows:

{% highlight bash %}
function show() { 
    echo
    sed 's/^/|  /' "$1"
    echo
}
{% endhighlight %}

Well... there's nothing to tell me what to do now, so let's just
`build` it:

{% highlight text %}
~/dzilla/Sample-Module$ dzil build
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
Unable to extract an abstract from lib/Sample.pm. Please add...
[DZ] no version was ever set...
{% endhighlight %}

Bummer! There seem to be two problems here (and with the tutorial): the
first one is the absence of the *abstract*, the other one seems more
serious because it triggers some error internally to [Dist::Zilla].

### Adding an `ABSTRACT`

Fixing the first issue should be simple, I remember reading about the
abstract [somewhere](http://dzil.org/tutorial/writing-docs.html)
and it seems to just require an additional line in the module file:

{% highlight text %}
~/dzilla/Sample-Module$ vi lib/Sample/Module.pm
~/dzilla/Sample-Module$ show lib/Sample/Module.pm

|   package Sample::Module;
|   # ABSTRACT: a sample module to play with Dist::Zilla
|   
|   use strict;
|   use warnings;
|   use English qw( -no_match_vars );
|   use Carp;
|   
|   1;
|   __END__

~/dzilla/Sample-Module$ dzil build
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] no version was ever set...
{% endhighlight %}


I just think that some *explicit* mention about the `ABSTRACT`
would be nice on the reader in the tutorial!

### Dealing with the *version*

[Managing Version Numbering with Dist::Zilla](http://dzil.org/tutorial/versioning.html)
seems to be a good candidate to get rid of the second error. I find
particularly reassuring the following sentence:

> The simplest way to specify your dist's version is to put it in *dist.ini*

so let's try it immediately:

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   <em style="color:red">version = 3.14.15</em>
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Basic]

~/dzilla/Sample-Module$ dzil build
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-3.14.15
[DZ] writing archive to Sample-Module-3.14.15.tar.gz
{% endhighlight %}

WTF? Definitely not what I expected from a `build` command!
[I'll dig it later](#build-wtf), now let's try to test it:

{% highlight text %}
~/dzilla/Sample-Module$ dzil test
[DZ] building test distribution under .build/krERIMYW7M
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in .build/krERIMYW7M
Checking if your kit is complete...
Looks good
Writing Makefile for Sample::Module
cp lib/Sample/Module.pm blib/lib/Sample/Module.pm
PERL_DL_NONLAZY=1 /opt/perl-5.8.8/bin/perl...
<em style="color:red">t/00-load.t .. 1/1 Use of uninitialized value in concatenation (.) or string at t/00-load.t line 11.</em>
# Testing Sample::Module 
t/00-load.t .. ok   
All tests successful.
Files=1, Tests=1,  0 wallclock secs ( 0.01 usr  0.02 sys +  0.02 cusr  0.00 csys =  0.05 CPU)
Result: PASS
[DZ] all's well; removing .build/krERIMYW7M
{% endhighlight %}

Yay, it's working... more or less. There is still no `$VERSION`
in my module, and this is something that annoyed me a lot in these years.
Maybe it's time to read some more from the tutorial:

> There are a number of plugins that put your version number to use.
PkgVersion inserts a $VERSION definition in all your packages so that
they'll all have versions matching distribution's version. NextRelease
adds version headers to your changelog file so you don't need to worry
about what the next version number will be until it's built. PodVersion
or PodWeaver can insert a =head1 VERSION section in your documentation.
The Git integration plugins system uses your version to tag releases.
>
> All of these plugins go a long way to taking care of version
accounting for you. PkgVersion and the Pod mungers, especially,
eliminate the need to update multiple files in multiple ways.
>
> The next step to letting Dist::Zilla help manage your versions is to
let it manange your version numbering, too.

Well, let's try this again then...

### Dealing with the éversion*, reloaded

I would actually have done this step in any case, because I'm lazy and
I like my system to figure out stuff like version numbering, unless it's
time that I really need to bump the version. I also use
[git](http://git-scm.com/), so it seems I'm quite lucky because
of [Dist::Zilla::Plugin::BumpVersionFromGit].

[Dist::Zilla::Plugin::BumpVersionFromGit]: http://search.cpan.org/dist/Dist-Zilla-Plugin-BumpVersionFromGit/

The installation of this module is not clean, anyway. In particular,
it seems that using Debian's git is not liked very much by this module,
that has tests fixed for version 1.7 while I have 1.5:

{% highlight text %}
#   Failed test at t/basic.t line 45.
#                   'git: 'a-command-not-likely-to-exist' is not a git-command. See 'git --help'.
# '
#     doesn't match '(?-xism:which does not exist)'
{% endhighlight %}

How the hell did they decide to change error messages is obscure to me.
Now the problem is... to install or not to install? Probably the best thing
to do would be to self-compile git and go with the bleading edge, but I'm
lazy enough to decide that `git tag` is probably unchanged...
so I go for `make install`.

After the installation, following [Dist::Zilla::Plugin::BumpVersionFromGit]
should be easy:

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Basic]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

{% endhighlight %}

So let's try:

{% highlight text %}
~/dzilla/Sample-Module$ dzil test
[DZ] building test distribution under .build/hYUzF1mKs7
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
fatal: Not a git repository
{% endhighlight %}

Ach! I didn't initialise the git repository!!! Let's fix this:

{% highlight text %}
~/dzilla/Sample-Module$ git init
Initialized empty Git repository in .git/
~/dzilla/Sample-Module$ git add dist.ini lib/Sample/Module.pm t/00-load.t
~/dzilla/Sample-Module$ git commit -m 'Initial import'
Created initial commit bf8a91c: Initial import
 3 files changed, 31 insertions(+), 0 deletions(-)
 create mode 100644 dist.ini
 create mode 100644 lib/Sample/Module.pm
 create mode 100644 t/00-load.t
{% endhighlight %}

and give it a new try:

{% highlight text %}
~/dzilla/Sample-Module$ dzil test
[DZ] building test distribution under .build/6rSmgX1Gpw
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in .build/6rSmgX1Gpw
Checking if your kit is complete...
Looks good
Writing Makefile for Sample::Module
cp lib/Sample/Module.pm blib/lib/Sample/Module.pm
PERL_DL_NONLAZY=1 /opt/perl-5.8.8/bin/perl...
t/00-load.t .. 1/1 Use of uninitialized value in concatenation (.) or string at t/00-load.t line 11.
# Testing Sample::Module 
t/00-load.t .. ok   
All tests successful.
Files=1, Tests=1,  0 wallclock secs ( 0.00 usr  0.02 sys +  0.01 cusr  0.02 csys =  0.05 CPU)
Result: PASS
[DZ] all's well; removing .build/6rSmgX1Gpw
{% endhighlight %}

What's wrong now?!? OK I get it, it draws the *whole bundle* version
number from git, but still does not set it inside modules; it seems that I
did not read the tutorial with sufficient attention:

> There are a number of plugins that put your version number to use.
**PkgVersion inserts a `$VERSION` definition in all your packages so
that they'll all have versions matching distribution's version.**
NextRelease adds version headers to your changelog file so you don't
need to worry about what the next version number will be until it's
built. PodVersion or PodWeaver can insert a `=head1 VERSION` section in
your documentation. The Git integration plugins system uses your version
to tag releases.

Let's add `PkgVersion` then, and give it yet another try:

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Basic]
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~/dzilla/Sample-Module$ dzil test
[DZ] building test distribution under .build/uFlnF2gzDc
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in .build/uFlnF2gzDc
Checking if your kit is complete...
Looks good
Writing Makefile for Sample::Module
cp lib/Sample/Module.pm blib/lib/Sample/Module.pm
PERL_DL_NONLAZY=1 /opt/perl-5.8.8/bin/perl...
t/00-load.t .. 1/1 # Testing Sample::Module 0.1.0
t/00-load.t .. ok   
All tests successful.
Files=1, Tests=1,  1 wallclock secs ( 0.01 usr  0.02 sys +  0.01 cusr  0.01 csys =  0.05 CPU)
Result: PASS
[DZ] all's well; removing .build/uFlnF2gzDc
{% endhighlight %}

According to the docs, I can bump the version by myself:

{% highlight text %}
~/dzilla/Sample-Module$ V=3.14.15 dzil build
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-<em style="color:red">3.14.15</em>
[DZ] writing archive to Sample-Module-<em style="color:red">3.14.15</em>.tar.gz
{% endhighlight %}

<a name="build-wtf"></a>

### `dzil build` WTF?

I expected `build` to do something similar
to either [Module::Build](https://metacpan.org/pod/Module::Build)'s `./Build`
or [ExtUtils::MakeMaker](https://metacpan.org/pod/ExtUtils::MakeMaker)'s `make`,
but it seems that it actually builds up the
distribution file, *a-la* `./Build dist` or `make dist`. To be
fair, it's written in the help:

{% highlight text %}
~/dzilla/Sample-Module$ dzil | grep build:
     build: build your dist
{% endhighlight %}

but I'm not particularly fond of these changes in terminology, especially
when they change from well-established conventions.

As a CPAN author that uses these modules from some time,
`dist` would be much, much better.

### So, what's inside that package?

This is what's inside the directory after running `dzil build`:

{% highlight text %}
~/dzilla/Sample-Module$ dir
total 24
-rw-r--r-- 1 poletti dialout  148 2010-05-08 12:52 dist.ini
drwxr-xr-x 3 poletti dialout 4096 2010-05-08 12:20 lib
drwxr-xr-x 4 poletti dialout 4096 2010-05-08 12:52 Sample-Module-3.14.15
-rw-r--r-- 1 poletti dialout 7920 2010-05-08 12:52 Sample-Module-3.14.15.tar.gz
drwxr-xr-x 2 poletti dialout 4096 2010-05-08 12:21 t
~/dzilla/Sample-Module$ cd Sample-Module-3.14.15
~/dzilla/Sample-Module/Sample-Module-3.14.15$ dir
total 48
-rw-r--r-- 1 poletti dialout   148 2010-05-08 12:52 dist.ini
drwxr-xr-x 3 poletti dialout  4096 2010-05-08 12:52 lib
-rw-r--r-- 1 poletti dialout 18258 2010-05-08 12:52 LICENSE
-rw-r--r-- 1 poletti dialout   977 2010-05-08 12:52 Makefile.PL
-rw-r--r-- 1 poletti dialout    86 2010-05-08 12:52 MANIFEST
-rw-r--r-- 1 poletti dialout   386 2010-05-08 12:52 META.yml
-rw-r--r-- 1 poletti dialout   311 2010-05-08 12:52 README
drwxr-xr-x 2 poletti dialout  4096 2010-05-08 12:52 t
{% endhighlight %}

Well, it seems that promises have been kept!

### Dealing with the *version*, revolution

There's one final thing to do with version numbering, anyway: git must be
told to "remember" it, otherwise I'm still stuck in dealing with this
stuff by myself. [Dist::Zilla::Plugin::Git] comes to the
rescue, according to [this tutorial page](http://dzil.org/tutorial/vcs-git.html).
Well, actually the tutorial page gives for granted that you already
know the module and installed it:

[Dist::Zilla::Plugin::Git]: https://metacpan.org/pod/Dist::Zilla::Plugin::Git

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Basic]
|   [PkgVersion]
|   [@Git]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~/dzilla/Sample-Module$ dzil test
couldn't load plugin @Git given in config: Can't locate Dist/Zilla/PluginBundle/Git.pm
...
[lots of error lines here]
{% endhighlight %}

Unluckily, the module installation is not clean due to git's version...
again. From the `Changes` file:

> fix tests to work with git 1.7.0

This time the problem seems to be a bit more serious, so I decide to
upgrade git and the module eventually gets installed. Time to give it a try:

{% highlight text %}
~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.0
[DZ] writing archive to Sample-Module-0.1.0.tar.gz
[@Basic/TestRelease] ...
...
Result: PASS
[@Basic/TestRelease] all's well; removing .build/uFQW51GQq_

*** Preparing to upload Sample-Module-0.1.0.tar.gz to CPAN ***

Do you want to continue the release process? (yes/no) [no]
{% endhighlight %}

Hey, wait a moment! I have uncommitted files, why didn't it spot them?

{% highlight text %}
~/dzilla/Sample-Module$ git status
# On branch master
# Changed but not updated:
...
# Untracked files:
...
{% endhighlight %}

It turns out to be an ordering problem inside <code>dist.ini</code>:

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   <em style="color:red">[@Git]</em>
|   [@Basic]
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.0
[DZ] writing archive to Sample-Module-0.1.0.tar.gz
[@Git/Check] branch master has some untracked files:
[@Git/Check]   Sample-Module-0.1.0.tar.gz
[@Git/Check]   Sample-Module-0.1.0/LICENSE
[@Git/Check]   Sample-Module-0.1.0/MANIFEST
[@Git/Check]   Sample-Module-0.1.0/META.yml
[@Git/Check]   Sample-Module-0.1.0/Makefile.PL
[@Git/Check]   Sample-Module-0.1.0/README
[@Git/Check]   Sample-Module-0.1.0/dist.ini
[@Git/Check]   Sample-Module-0.1.0/lib/Sample/Module.pm
[@Git/Check]   Sample-Module-0.1.0/t/00-load.t ...
{% endhighlight %}

The check works, at last. It's interesting (and correct) that `dist.ini`
does not participate in the checks. Now let's see if it all works, it's
necessary to add the release package names in the exclusion list for
git:

{% highlight text %}
~/dzilla/Sample-Module$ vi .git/info/exclude
~/dzilla/Sample-Module$ show .git/info/exclude

|   # git-ls-files --others --exclude-from=.git/info/exclude
|   # Lines that start with '#' are comments.
|   # For a project mostly in C, the following would be a good set of
|   # exclude patterns (uncomment them if you want to use them):
|   # *.[oa]
|   # *~
|   Sample-Module-*

{% endhighlight %}

and then re-run the `release` command:

{% highlight text %}
~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.0
[DZ] writing archive to Sample-Module-0.1.0.tar.gz
[@Git/Check] branch master is in a clean state
[@Basic/TestRelease] Extracting ...
...
[@Basic/TestRelease] all's well; removing .build/EqUfLZpmQJ

*** Preparing to upload Sample-Module-0.1.0.tar.gz to CPAN ***

Do you want to continue the release process? (yes/no) [no]^C
[@Basic/ConfirmRelease] Aborting release...
{% endhighlight %}

Well, we're going a bit too far, I don't want to push this stuff to
CPAN. It seems that this is due to some plugin in the `@Basic` bundle,
so let's see how to disable it... In [Dist::Zilla] distribution page
there's an interesting [Dist::Zilla::PluginBundle::Filter] so I get rid
of the basic bundle and go for the filter:

[Dist::Zilla::PluginBundle::Filter]: https://metacpan.org/pod/Dist::Zilla::PluginBundle::Filter

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Git]
|   <em style="color:red">[@Filter]</em>
|   <em style="color:red">bundle = @Basic</em>
|   <em style="color:red">remove = UploadToCPAN</em>
|   <em style="color:red">remove = ConfirmRelease</em>
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

{% endhighlight %}

Time for a new test

{% highlight text %}
~/dzilla/Sample-Module$ dzil release
you can't release without any Releaser plugins ...
{% endhighlight %}

Ouch! I hope [Dist::Zilla::Plugin::FakeRelease] will help me out:

[Dist::Zilla::Plugin::FakeRelease]: https://metacpan.org/pod/Dist::Zilla::Plugin::FakeRelease

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Git]
|   [@Filter]
|   bundle = @Basic
|   remove = UploadToCPAN
|   remove = ConfirmRelease
|   <em style="color:red">[FakeRelease]</em>
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

{% endhighlight %}

Now, just to double-check the `Git::Check` module, I modify a file:

{% highlight text %}
~/dzilla/Sample-Module$ vi lib/Sample/Module.pm
~/dzilla/Sample-Module$ show lib/Sample/Module.pm

|   package Sample::Module;
|   # ABSTRACT: a sample module to play with Dist::Zilla
|   # just a comment
|   
|   use strict;
|   use warnings;
|   use English qw( -no_match_vars );
|   use Carp;
|   
|   1;
|   __END__

{% endhighlight %}

and run the `release` command once again:

{% highlight text %}
~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.0
[DZ] writing archive to Sample-Module-0.1.0.tar.gz
[@Git/Check] branch master has some uncommitted files:
[@Git/Check]   lib/Sample/Module.pm ...
{% endhighlight %}

Awesome! After committing let's try this again:

{% highlight text %}
~/dzilla/Sample-Module$ git commit lib/Sample/Module.pm -m "added comment"
~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.0
[DZ] writing archive to Sample-Module-0.1.0.tar.gz
[@Git/Check] branch master is in a clean state
[@Filter/TestRelease] ...
...
[@Filter/TestRelease] all's well; removing .build/yqbgoYW_GV
[FakeRelease] Fake release happening (nothing was really done)
[@Git/Tag] Tagged v0.1.0
[@Git/Push] pushing to origin
fatal: 'origin' does not appear to be a git repository
fatal: The remote end hung up unexpectedly
{% endhighlight %}

Uhm, it seems that I'd better get rid of the `Git::Push` plugin,
because my repository is local:

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Filter]
|   bundle = @Git
|   remove = Git::Push
|   [@Filter]
|   bundle = @Basic
|   remove = UploadToCPAN
|   remove = ConfirmRelease
|   [FakeRelease]
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.0 to 0.1.1
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.1
[DZ] writing archive to Sample-Module-0.1.1.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] Extracting ...
...
[@Filter/TestRelease] all's well; removing .build/E9CAlzs8sG
[FakeRelease] Fake release happening (nothing was really done)
can't open Changes for reading:  No such file or directory\
 at /opt/perl-5.8.8/lib/site_perl/5.8.8/Dist/Zilla/File/OnDisk.pm line 31
{% endhighlight %}

OK, the version bumping works, all's well but... there's an error at the
end! First of all, I wonder why it didn't pop up last time the release
process blocked in `Git::Push`, but whatever the reason I have
to find who's preventing this release from happening. This requires a
little hack into [Dist::Zilla] itself, in particular inside the
offending module `Dist::Zilla::File::OnDisk` we change the
`die()` into `Carp::confess`:

{% highlight text %}
can't open Changes for reading: No such file or directory...
   Dist::Zilla::File::OnDisk::_read_file(...
   Dist::Zilla::File::OnDisk::__ANON__(...
   Class::MOP::Attribute::default(...
   Dist::Zilla::File::OnDisk::content(...
   Dist::Zilla::Plugin::Git::Commit::_get_changes(...
   Dist::Zilla::Plugin::Git::Commit::__ANON__(...
   String::Formatter::method_replace(...
   String::Formatter::format(...
   String::Formatter::__ANON__(...
   Dist::Zilla::Plugin::Git::Commit::get_commit_message(...
   <em style="color:red">Dist::Zilla::Plugin::Git::Commit</em>::after_release(...
   Dist::Zilla::release(...
   Dist::Zilla::App::Command::release::execute(...
   App::Cmd::execute_command(...
   App::Cmd::run(...
{% endhighlight %}

So that's the culprit... `DZP::Git::Commit`! For the `$VERSION` stuff we
don't actually need it, so let's rule it away for the moment:

{% highlight text %}
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Filter]
|   bundle = @Git
|   remove = Git::Push
|   remove = Git::Commit
|   [@Filter]
|   bundle = @Basic
|   remove = UploadToCPAN
|   remove = ConfirmRelease
|   [FakeRelease]
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.0 to 0.1.1
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.1
[DZ] writing archive to Sample-Module-0.1.1.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] Extracting ...
...
[@Filter/TestRelease] all's well; removing .build/ieACRWrTGf
[FakeRelease] Fake release happening (nothing was really done)
[@Filter/Tag] Tagged v0.1.1
{% endhighlight %}

At the very last!!! Anyway, having a `Changes` file is actually a good
thing, so let's add one and restore the ruled out plugin:

{% highlight text %}
~/dzilla/Sample-Module$ touch Changes
~/dzilla/Sample-Module$ git add Changes
~/dzilla/Sample-Module$ git commit Changes -m 'added Changes file'
[master 27e56cd] added Changes file
 0 files changed, 0 insertions(+), 0 deletions(-)
 create mode 100644 Changes
~/dzilla/Sample-Module$ vi dist.ini
~/dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Filter]
|   bundle = @Git
|   remove = Git::Push
|   [@Filter]
|   bundle = @Basic
|   remove = UploadToCPAN
|   remove = ConfirmRelease
|   [FakeRelease]
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.1 to 0.1.2
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.2
[DZ] writing archive to Sample-Module-0.1.2.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] ...
...
[@Filter/TestRelease] all's well; removing .build/dvgGmImcg2
[FakeRelease] Fake release happening (nothing was really done)
[@Filter/Commit] Committed dist.ini
[@Filter/Tag] Tagged v0.1.2
~/dzilla/Sample-Module$ show Changes


{% endhighlight %}

Much ado abouth nothing? Maybe I have to actually do some changes, let's
try:

{% highlight text %}
~/dzilla/Sample-Module$ vi lib/Sample/Module.pm
~/dzilla/Sample-Module$ show lib/Sample/Module.pm

|   package Sample::Module;
|   # ABSTRACT: a sample module to play with Dist::Zilla
|   # just a comment, extended
|   
|   use strict;
|   use warnings;
|   use English qw( -no_match_vars );
|   use Carp;
|   
|   1;
|   __END__

~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.2 to 0.1.3
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.3
[DZ] writing archive to Sample-Module-0.1.3.tar.gz
[@Filter/Check] branch master has some uncommitted files:
[@Filter/Check]   lib/Sample/Module.pm ...
{% endhighlight %}

Correct, let's commit and go forth:

{% highlight text %}
~/dzilla/Sample-Module$ git commit -a -m "extended the comment"
[master 71a01c0] extended the comment
 1 files changed, 1 insertions(+), 1 deletions(-)
<b>~/dzilla/Sample-Module$ dzil release</b>
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.2 to 0.1.3
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.3
[DZ] writing archive to Sample-Module-0.1.3.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] ...
...
[@Filter/TestRelease] all's well; removing .build/yn5wsMwfpC
[FakeRelease] Fake release happening (nothing was really done)
[@Filter/Tag] Tagged v0.1.3
~/dzilla/Sample-Module$ show Changes


{% endhighlight %}

Still nothing, but this will probably be meat for some future article!

*Update*: I later tried to move the `Git` stuff before
the `Basic` and release stuff, and it actually worked as expected:

{% highlight text %}
~dzilla/Sample-Module$ show dist.ini

|   name    = Sample-Module
|   author  = Flavio Poletti <polettix@cpan.org>
|   license = Perl_5
|   copyright_holder = Flavio Poletti
|   
|   [@Filter]
|   bundle = @Basic
|   remove = UploadToCPAN
|   remove = ConfirmRelease
|   [FakeRelease]
|   [@Filter]
|   bundle = @Git
|   remove = Git::Push
|   [PkgVersion]
|   
|   [BumpVersionFromGit]
|   first_version = 0.1.0
|   version_regexp  = ^v(.+)$

~dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.3 to 0.1.4
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.4
[DZ] writing archive to Sample-Module-0.1.4.tar.gz
[@Filter/TestRelease] Extracting ...
...
[@Filter/TestRelease] all's well; removing .build/zD6QJBMw7z
[@Filter/Check] branch master has some untracked files:
[@Filter/Check]   adjust.pl ...
{% endhighlight %}

I don't actually understand why this happens; anyway, I still think that
keeping the `Git::Check` stuff before is better, because the whole
build and test stuff is not performed if there are pending commits.

<a name="the-lucky-path"></a>

### The Lucky Path

Well, back to the very beginning... what should I do to:
- start using [Dist::Zilla] from scratch
- with basic integration with [git]
- and with automatic version numbering?

[git]: http://www.git-scm.com/

Here's my recipe!

#### Install needed stuff

You'll need a reasonably recent version of [git], so install it beforehand.
Then install the Perl modules:

{% highlight text %}
~/dzilla$ cpanm Dist::Zilla Dist::Zilla::Plugin::BumpVersionFromGit Dist::Zilla::Plugin::Git
{% endhighlight %}

#### Create module directory and stuff

This is up to you, just a minimal example:

{% highlight text %}
~/dzilla$ mkdir Sample
~/dzilla$ cd Sample
~/dzilla/Sample$ mkdir lib
~/dzilla/Sample$ cat >lib/Sample.pm <<END_OF_MODULE
package Sample;
# ABSTRACT: whatever
1;
__END__
END_OF_MODULE
~/dzilla/Sample$ touch Changes
~/dzilla/Sample$ git init
Initialized empty Git repository in /home/poletti/sviluppo/perl/dzilla/Sample/.git/
~/dzilla/Sample$ git add .
~/dzilla/Sample$ git commit -m 'Initial import'
[master (root-commit) 3b19203] Initial import
 1 files changed, 3 insertions(+), 0 deletions(-)
 create mode 100644 Changes
 create mode 100644 lib/Sample.pm
~/dzilla/Sample$ echo 'Sample-*' >> .git/info/exclude
{% endhighlight %}

Remember to ensure that the `Changes` file is created, or
[Dist::Zilla::Plugin::Git::Commit] will complain later.

[Dist::Zilla::Plugin::Git::Commit]: https://metacpan.org/pod/Dist::Zilla::Plugin::Git::Commit

#### Create `dist.ini`

Now create `dist.ini`, the configuration file for [Dist::Zilla]:

{% highlight text %}
~/dzilla/Sample$ cat >dist.ini <<END_OF_FILE
name    = Sample
author  = A. U. Thor <someone@example.com>
license = Perl_5
copyright_holder = A. U. Thor

[@Filter]
bundle = @Git
remove = Git::Push
[@Filter]
bundle = @Basic
remove = ConfirmRelease
remove = UploadToCPAN
[FakeRelease]
[PkgVersion]

[BumpVersionFromGit]
first_version = 0.1.0
version_regexp  = ^v(.+)$
END_OF_FILE
~/dzilla/Sample$ git add dist.ini
~/dzilla/Sample$ git commit -m 'added dist.ini'
[master 98feba7] added dist.ini
 1 files changed, 18 insertions(+), 0 deletions(-)
 create mode 100644 dist.ini
{% endhighlight %}

#### Enjoy your toolchain

At this point, you can check the toolchain:

{% highlight text %}
~/dzilla/Sample$ dzil release
[DZ] beginning to build Sample
[DZ] guessing dist's main_module is lib/Sample.pm
[DZ] extracting distribution abstract from lib/Sample.pm
[DZ] writing Sample in Sample-0.1.0
[DZ] writing archive to Sample-0.1.0.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] Extracting ~/dzilla/Sample/Sample-0.1.0.tar.gz to .build/3GuZPYcWef
Checking if your kit is complete...
Looks good
Writing Makefile for Sample
cp lib/Sample.pm blib/lib/Sample.pm
No tests defined for Sample extension.
[@Filter/TestRelease] all's well; removing .build/3GuZPYcWef
[FakeRelease] Fake release happening (nothing was really done)
[@Filter/Tag] Tagged v0.1.0
{% endhighlight %}

If you want, you can restore the automatic upload to CPAN feature of
`release`, by changing the dist.ini file like this:

{% highlight text %}
~/dzilla/Sample$ cat >dist.ini <<END_OF_FILE
name    = Sample
author  = A. U. Thor <someone@example.com>
license = Perl_5
copyright_holder = A. U. Thor

[@Filter]
bundle = @Git
remove = Git::Push
[@Basic]
[PkgVersion]

[BumpVersionFromGit]
first_version = 0.1.0
version_regexp  = ^v(.+)$
END_OF_FILE
{% endhighlight %}

#### A shell script to rule them all

This script should do all that you need, just cross your fingers:

{% highlight bash %}
mkdir Sample
cd Sample

mkdir lib
cat >lib/Sample.pm <<END_OF_MODULE
package Sample;
# ABSTRACT: whatever
1;
__END__
END_OF_MODULE

touch Changes

cat >dist.ini <<END_OF_FILE
name    = Sample
author  = A. U. Thor 
license = Perl_5
copyright_holder = A. U. Thor

[@Filter]
bundle = @Git
remove = Git::Push
[@Filter]
bundle = @Basic
remove = ConfirmRelease
remove = UploadToCPAN
[FakeRelease]
[PkgVersion]

[BumpVersionFromGit]
first_version = 0.1.0
version_regexp  = ^v(.+)$
END_OF_FILE

git init
git add .
git commit -m 'Initial import'
echo 'Sample-*' >> .git/info/exclude

dzil release
{% endhighlight %}

### That's all, folks

Well, it seems that [Dist::Zilla]
has its sharp edges, but seems that it's actually possible to start using
it and it's quite promising... Stay tuned for further adventures of this
total newbie in [Dist::Zilla]'s world!
