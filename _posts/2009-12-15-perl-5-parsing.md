---
# vim: ts=4 sw=4 expandtab syn=off tw=72
layout: post
title: 'Why parsing should be simple?'
keywords: 'perl, parsing, language'
image:
   feature: tramonto.jpg
   credit: Tramonto in Australia
   creditlink: https://en.wikipedia.org/wiki/Australia
comments: false
---

Following [an article](http://greenokapi.net/blog/2009/12/15/github-language-statistics/)
by [osfameron](http://greenokapi.net/blog) (found
thanks to [Planet Perl Iron Man](http://ironman.enlightenedperl.org/)) I landed
on [the interesting analysis](http://corte.si/posts/code/devsurvey/index.html)
performed by Aldo Cortesi. I was quite
unsurprised at seeing yet another variant of the old thorny "Perl is
dead or at least does not feel very well" infamous adage.

I was a bit more surprised at
seeing [this comment](http://corte.si/posts/code/devsurvey/index.html#comment-25790536)
(*this comment does not seem to appear any more now*):

> At the risk of inflaming more Perl
> programmers to come and manfully defend their language on my blog, I
> think there's a reason why Python has a nice BNF grammar, and Perl has
> 5600 lines of ad-hoc parsing code:
> [http://www.perlmonks.org/?node_id=663393](http://www.perlmonks.org/?node_id=663393)


I wonder which reason Aldo is thinking about. IMHO, the reason is that
probably Python development focuses more on language orthogonality and
Perl development more on programmers' ease at the possible expense of a
more complicated compiler, but it's just me.
