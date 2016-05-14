---
# vim: ts=4 sw=4 expandtab syn=off tw=72 :
layout: post
title: Writing About Stuff
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

One of the most effective ways to debug and refine my code is to...
write about it. I am so smart that I figured it out all alone... at
about 43!

(I mean *fourty-three, wow!*, not *6.0415263e+52*).

## Data::Tubes, Again and Again

I'm working on a project called [Data::Tubes][] lately. To be honest,
there's not much left to do with respect to my original plan, so I'm
actually more *writing about it* than *writing it* now.

While doing this, two things are becoming more and more evident:

- this project is not much relevant. I see the value of it, and I'll
  probably use it quite extensively to solve a class of problems that
  pop up from time to time, but overall it's quite niche-y;
- to really make something useful, it's better to use it. A lot of the
  changes in the interface happened while writing examples.

The first aspect is a bummer to some extent; on the flip side, I'm
having fun, learning something, keeping my programming muscles exercised
and... doing something that most probably will be useful at some time.

The second one is just rediscovering what I probably read over and over,
with relations to Test Driven Developemnt to some extent. I'm really not
sticking to the KISS principle - it turns out that many times I'm adding
things "just because it's easy" and blends well, not out of real need.
On the other hand, writing about it let me refine the interface to
something *handy* as opposed to simply *doable*.

## Frustration!

For relevancy of the project, here's were the hubris really gets put to
test. Well, some humility never hurt anyone.

When I first saw a reference in [issue 245 of Perl Weekly][perlweekly] I
was a bit disapponted to see the whole idea summarized as *templating
engine using tags that resemble the tags of Template::Toolkit and input
data in PSKV format. That might stand for Pipe Separated Keys and
Values.*. Wait... what? The whole point of [Data::Tubes][] is to give
you all the flexibility on how you read, process, render and write your
outputs... how come?!?

I'm not blaming Gabor of course. The [Perl Weekly][pw] team does a
really remarkable job of keeping people updated on what happens in the
Perl world, and it was of course my fault to not provide clear
information about my project.

After that, I saw that [Data::Tubes][] was featured in [this issue of
Perl Tricks][perltricks]. Wow, they called it *a cute data
transformation module*... how kind! But wait... what? What does *needs
iterators* mean?!? They're there since the beginning!!!

Again, I think that the [authors][ptauth] at [Perl Tricks][pt] do an
amazing job... again, my fault for not making things clear enough!

## So What?

So... what did I do? Well, I thought that the whole frustration thing
could mean two things:

- I really suck at synthesizing and describe the gist of things. I still
  have to figure out how to improve here...
- all the stuff I coded needed much better documentation, not only the
  *reference* type (the POD was already in place), but the kind that you
  would initially turn to to understand how a thing can be actually
  useful to address a problem.

This resulted in a *lot* of writing (the [web site][Data::Tubes], the
articles in the [wiki][])... again confirming my distance from
synthesys!

All this writing benefited me in two ways:

- I wrote something that will help me to use my project effectively and
  efficiently when I will need it. I'm trying to write stuff in the way
  I'd like to read it!
- I got better insight at what it can do and how it can be done better -
  more features to add, wow!

## The Birth of `bucket`

One such thing that happened lately eventually led to the addition of
the `bucket` type of `tap`. Let's go in steps!

[Data::Tubes][] lets you define a sequence, or [pipeline][], of
transforming actions called tubes. Each tube receives as input exactly
one *record* and outputs:

- `()`: the input record is simply discarded;
- `($onething)`: the `$onething` is the output record, that is suitable
  for being fed to the following tube;
- `(records => \@manythings)`: the input record gave rise to a sequence
  of output records, returned as an array reference;
- `(iterator => sub{...})`: the input record gave rise to a *promise* to
  generate zero, one or more output records

During the design of [pipeline][] I had to deal with the generic case,
where you don't know in anticipation what the tubes in the pipeline will
return. The most sensible choice seemed to be the *iterator*: it allows
returning whatever number of output records (so it's general enough) and
it also does not assume that you want to go all the way down in one
single shot (which is what an iterator is useful for).

So, when we define a pipeline like this:

{% highlight perl %}
use Data::Tubes qw< pipeline >;
my $pipeline = pipeline(
   'Source::iterate_files',
   'Reader::by_line',
   ['Parser::by_format' => 'name,age'],
   [
      'Renderer::with_template_perlish',
      "Hi [% name %]! You're [% age %] today!\n",
   ],
   'Writer::to_files'
);
{% endhighlight %}

we get back a tube whose output contract is the `iterator` one:

{% highlight perl %}
my @outcome = $pipeline->(\@filenames);
# $outcome[0] is the string 'iterator'
# $outcome[1] is an iterator. NO real computation happened yet!

while (my ($out) = $outcome[1]->()) {
    # ... use the $out-put record if needed
}
{% endhighlight %}

One thing that was immediately evident, though, was that in most cases
what I wanted was to just run the whole thing for all input records.
This initially led me to add the [drain][] function, which takes care to
feed a tube with inputs and *drain* whatever comes out of it:

{% highlight perl %}
use Data::Tubes qw< pipeline drain >;

# create the pipeline as before, then instead of calling this:
#    my @outcome = $pipeline->(\@filenames);
# you can call this:
drain($pipeline, \@filenames);
{% endhighlight %}

This is a drag (you have to import [drain]!), so a couple of options
were added to automate the draining process. The most basic is `tap`,
that when set to `sink` ensures that the iterator is drained on the spot
and nothing is returned (to save memory):

{% highlight perl %}
use Data::Tubes qw< pipeline >;
my $pipeline = pipeline(
   'Source::iterate_files',
   'Reader::by_line',
   ['Parser::by_format' => 'name,age'],
   [
      'Renderer::with_template_perlish',
      "Hi [% name %]! You're [% age %] today!\n",
   ],
   'Writer::to_files',
   {tap => 'sink'}
);
$pipeline->(\@filenames);
{% endhighlight %}

So far so good.

While writing an article about [alternatives], though, I came to
discovering that [pipeline][] is not only useful to define the *outer*
pipeline, i.e. the one that does the end-to-end processing, but also to
define sub-pipelines to be fed as [alternatives][].

In a nutshell, [alternatives][] allows you to provide a list of
alternative tubes, each of which will be tried over the same input
record until one of them *accepts* it and returns something back.

This led me to a bug though, because:

- by default, [pipeline][] returns a tube that always returns an
  iterator. Hence, the first tube in the alternatives would always get
  the input record, even if it would eventually toss it away at
  *iterator firing* time;
- working around the iterator setting the `tap` to `sink` will make
  *all* the alternatives to be always fired, because the `sink` does not
  return anything.

While it was already possible to address the problem with the available
interface ([pipeline][] also supported a `pump` option that could be
used effectively), there was clearly a need for both exhausting the
iterator *and* getting the output records. Hence, the following example
does use [alternatives][] in the right way:

{% highlight perl %}
my $template_for_OK = ...;
my $template_for_NOT_OK = ...;
pipeline(
   'Source::iterate_files',
   'Reader::by_line',
   ['Parser::by_format' => 'status:name'],
   [
      'Plumbing::alternatives',
    
      # First alternative, try to see if it's a good one
      pipeline(
          sub { # filter only good ones
             return $_[0] if $_[0]{structured}{status} eq 'OK;
             return;
          },
          ['Renderer::with_template_perlish' => $template_for_OK],
          {tap => 'bucket'}, # <<< LOOK HERE!!!
      ),
    
      # as a fallback, we render for NOT OK
      ['Renderer::with_template_perlish' => $template_for_NOT_OK],
   ],
   'Writer::to_files',
   {tap => 'sink'}, # we can just toss the records away here
)->(\@input_filenames);
{% endhighlight %}

## Conclusions?

I don't think I have some conclusions for this article to be honest. I'm
having fun with [Data::Tubes][], although I start doubting its relevance
and usefulness. But one thing is sure: for me, it's an amazing learning
tool as a hobby programmer!


[Data::Tubes]: http://github.polettix.it/Data-Tubes/
[pipeline]: https://metacpan.org/pod/Data::Tubes#pipeline
[drain]: https://metacpan.org/pod/Data::Tubes#drain
[alternatives]: https://metacpan.org/pod/Data::Tubes::Plugin::Plumbing#alternatives
[fallback]: https://metacpan.org/pod/Data::Tubes::Plugin::Plumbing#fallback
[perlweekly]: http://perlweekly.com/archive/245.html
[pw]: http://perlweekly.com/
[perltricks]: http://perltricks.com/article/what-s-new-on-cpan---march-2016/
[pt]: http://perltricks.com/
[ptauth]: http://perltricks.com/authors/
[wiki]: https://github.com/polettix/Data-Tubes/wiki
