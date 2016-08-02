---
# vim: ts=4 sw=4 expandtab syn=off tw=72
layout: post
title: 'local::lib for distributions'
keywords: 'perl, local::lib, standalone'
image:
   feature: tramonto.jpg
   credit: Tramonto in Australia
   creditlink: https://en.wikipedia.org/wiki/Australia
comments: false
---

[local::lib] is a love-it-or-hate-it module, with the additional feature
that you don't get the hate-it part.

[local::lib]: https://metacpan.org/pod/local::lib

Recently, I had to develop a script to do a couple of HTTP redirections.
I headed towards CPAN, quickly found that [HTTP::Server::Simple] (and in
particular [HTTP::Server::Simple::CGI]) and in some twenty minutes I had a
working prototype. Forget that I changed my mind a couple of times
before having what I eventually used for my test...

[HTTP::Server::Simple]: https://metacpan.org/pod/HTTP::Server::Simple
[HTTP::Server::Simple::CGI]: https://metacpan.org/pod/HTTP::Server::Simple::CGI

Now, I knew I had to go into an environment that could possibly prevent
me from using my machine to perform the test. As a matter of fact, I
didn't know whether I could use the program anywhere, let alone know
what kind of Perl environment I would have found. Nightmare!

Luckily enough, it turned out that I only needed modules that do not
require compilation. I love Pure Perl modules! So now I had the problem
to bundle all the needed non-core modules in a way that was convenient
to deliver. This is where [local::lib] really saved the day,
and in particular its `--self-contained` option. Well - yes -
I've seen options that were commented way better... but at least the
only reference in the synopsis made me curious enough to discover that
it was hitting the nail right in the head.

On my machine I have my own compiled Perl version to tinker with, so I
installed [local::lib] without the need to bootstrap anything. At this
point, all I had to do was something along these lines:

{% highlight text %}
shell$ perl -MCPAN -Mlocal::lib=--self-contained,my_lib -e 'CPAN::install($_) for @ARGV' HTTP::Server::Simple URI Log::Log4perl
{% endhighlight %}

Yes... I'm quite fond of `Log::Log4perl`, but that's another story.

The installation above went smooth and installed all the modules, and
their needed *non-core* dependencies, under the directory tree starting
from `my_lib`. I checked that there were actually no compiled components
- dependencies could play some trick - and I verified that I had been
lucky. Yay!

The directory structure you end up with is more or less the following:

{% highlight text %}
my_lib/bin
my_lib/lib/perl5/...
my_lib/man
{% endhighlight %}

I didn't need either the bin or the man subdirectory, so I just moved
the contents `my_lib/lib/perl5` into a `lib` subdirectory, removed what
remained of `my_lib` and... that's it! Well, wait a minute, I had to
make a slight change to the code as well:

{% highlight text %}
#...
use FindBin;
use lib $FindBin::Bin;
{% endhighlight %}

OK, now *that's it*! The funny part? I was actually able to use my
laptop, so I didn't need anything of this...
