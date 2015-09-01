---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: Changes, nags and git hooks
image:
   feature: cape-tribulation-canguro.jpg
   credit: Canguro a Cape Tribulation, Australia
   creditlink: https://en.wikipedia.org/wiki/Kangaroo
comments: true
---

I use [Dist::Zilla] with a few plugins, including `NextRelease` and
`Git::Check`. I was always nagged by the fact that committing actually
left the `Changes` file uncommitted... until now.

[Dist::Zilla]: https://metacpan.org/pod/Dist::Zilla

First of all, I discovered that there was no reason why I should have to
be nagged at all. The [documentation][dzilla-git] about
[Dist::Zilla] is pretty clear that both plugins run at the same stage, so
it's only a matter of proper ordering[^impatient]. Guess what? My `dzil`
file always has the *wrong* order!

[^impatient]: For those of you that are too lazy to click on the link and
    read through the page, you are supposed to put `NextRelease` before
    `Git::Check`.

[dzilla-git]: http://dzil.org/tutorial/vcs-git.html

The funny thing is that today I had some kind of epiphany and I
**understood** why this thing was nagging me. It **was supposed** to do
so! It **was designed** to do so! In this way, I would be nagged to
actually populate the Changes file with something meaningful before doing
a release, right?

Now, of course this was not the intended behaviour (again, see
[here][dzilla-git]) and there are better ways to ensure that `Changes` is
populated in some meaningful way before doing a release
([Dist::Zilla::Plugin::CheckChangesHasContent][dzp-cchc] being my new
plugin of election for this task), but in the excitement for my epiphany I
also figured that *presto!*, I need a [git][git-hook-1] [hook][git-hook-2]
to ensure that I don't commit `Changes` without intention (yes, I tend to
`git commit -a` a bit too much).


[dzp-cchc]: https://metacpan.org/pod/Dist::Zilla::Plugin::CheckChangesHasContent

[git-hook-1]: http://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks

[git-hook-2]: http://githooks.com/

This is the `pre-commit` hook that I came out with:

{% highlight bash %}
#!/bin/bash

target='Changes'

seen_target=0
skip=1
while read omode nmode ohash nhash changetype filename; do
[ "$filename" == "$target" ] && seen_target=1
   if [ $skip -ne 0 ]; then
      skip=0 # skip the first item only
   else
      [ $seen_target -eq 0 ] && continue
      echo "ERROR - '$target' MUST be committed alone"
      exit 1
   fi
done < <(git diff-index --cached HEAD)

exit 0
{% endhighlight %}

Now, after the real *enlightenment* came (i.e. finding
[DZP::CheckChangesHasContent][dzp-cchc]) this is obviously not needed any
more... but I'll keep it around should the need arise.

While using [DZP::CheckChangesHasContent][dzp-cchc], I figured that the
first addition of some *change* to the file would spoil all my efforts to
remember about `Changes` before the release. My hands were much faster
than my brains, again: I was about to propose a patch for the plugin when
I simply read the documentation:

> It looks for an unindented line starting with the version to be
> released. It then looks for any text from that line until the next
> unindented line (or the end of the file), ignoring whitespace. [...] If
> you had nothing but whitespace between [them], the release would be
> halted.

So, it is sufficient to add a **non-indented** line immediately after the
`{{"{"}}{NEXT}}` string to make sure the plugin will complain, e.g.:

{% highlight text %}
{{"{"}}{NEXT}}
CHECK YOUR CHANGES AND REMOVE THIS LINE!
   - I did this
   - I did that

1.0  1972-11-09 07:45:00 Europe/Rome
   - Born
{% endhighlight %}

Now of course I would like that line to be added automatically... this
time, before forking the relevant plugin, I'll try to think if there's
some already available way to do that!

## Update

There can be a workaround to obtain something very similar to
the above... It is sufficient to set the `format` parameter of the
`NextRelease` plugin to something like this:

{% highlight text %}
[NextRelease]
format = Changes for My::Module:%n%n%-9v %{yyyy-MM-dd HH:mm:ssZZZZZ VVVV}d%{ (TRIAL RELEASE)}T
{% endhighlight %}

i.e. the same format as the default one, but with some meaningful
introduction text (`Changes for...` in our example, followed by two
newlines). In this way, the following `Changes` file:

{% highlight text %}
{{"{"}}{NEXT}}
   - I did this
   - I did that

1.0  1972-11-09 07:45:00 Europe/Rome
   - Born
{% endhighlight %}

will generate this for the release package:

{% highlight text %}
Changes for My::Module:

2.0  1990--11-09 07:45:00 Europe/Rome
   - I did this
   - I did that

1.0  1972-11-09 07:45:00 Europe/Rome
   - Born
{% endhighlight %}

and will be updated into this:

{% highlight text %}
{{"{"}}{NEXT}}

Changes for My::Module:

2.0  1990--11-09 07:45:00 Europe/Rome
   - I did this
   - I did that

1.0  1972-11-09 07:45:00 Europe/Rome
   - Born
{% endhighlight %}

At this point, it will be sufficient to add new items *below the
introduction line*, like this:

{% highlight text %}
{{"{"}}{NEXT}}

Changes for My::Module:
   - This happened here
   - This happened there

2.0  1990--11-09 07:45:00 Europe/Rome
   - I did this
   - I did that

1.0  1972-11-09 07:45:00 Europe/Rome
   - Born
{% endhighlight %}

in order to *keep [DZP::CheckChangesHasContent][dzp-cchc] complain* until
the intro line is removed from the file, like this:

{% highlight text %}
{{"{"}}{NEXT}}
   - This happened here
   - This happened there

2.0  1990--11-09 07:45:00 Europe/Rome
   - I did this
   - I did that

1.0  1972-11-09 07:45:00 Europe/Rome
   - Born
{% endhighlight %}

We're ready for a new release now!
