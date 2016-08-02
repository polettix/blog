---
# vim: ts=4 sw=4 expandtab syn=off tw=72
layout: post
title: "Equality is reflexive... isn't it?"
keywords: 'perl, cpan, junction'
image:
   feature: tramonto.jpg
   credit: Tramonto in Australia
   creditlink: https://en.wikipedia.org/wiki/Australia
comments: false
---

I read about [Perl6::Junction](http://search.cpan.org/dist/Perl6-Junction)
in an [article](http://blogs.perl.org/users/marc_sebastian_jakobs/2009/11/my-favorite-module-of-the-month-perl6junction.html)
on [blogs.perl.org](http://blogs.perl.org/) and I was tickled. I quickly
went on CPAN to see what the module was about beyond the post above, and
saw two enthusiastic reviews by two bigs (at least this is what I
consider both of them).

I have to say that I was a bit disappointed in seeing that they both
talked about very clear documentation, while it seemed a bit too minimal
for my taste. I do agree that the test suite is complete, anyway, and
it's a useful source for examples too! The tests are indeed quite
extensive, and there are also tests for something that made me curious,
i.e.: "will it be possible to use junctions on both sides?". The answer
turns out to be positive, and there are tests for those cases (see the
`t/join.t` test file for details).

One funny thing in the module is that the following both apply:

{% highlight perl %}
my $is_true = (all(3, 4) == any(3, 4));
my $is_NOT_true = (any(3, 4) == all(3, 4));
{% endhighlight %}

It actually makes sense: the first says "do all elements in the `{3, 4}`
set have something equal to them in the `{3, 4}` set?". Course they do,
because `3` in the first set has `3` in the second, and `4` in the first set
has `4` in the second. The second says "is any element in the `{3, 4}` equal
to all the elements in `{3, 4}`?". Course there isn't, because `3` from the
first set is equal to `3` in the second set, but fails to be equal to `4`.

Hence, the (numeric) equality operator does not maintain the reflexive
property here, and it seems just... *weird*, even though it makes
perfectly sense.
