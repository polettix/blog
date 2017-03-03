---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Telegram Keyboard Button Encoding
image:
   feature: kakadu-on-yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

Telegram [custom keyboards][] are a handy feature to provide a cleaner
interface to your users. But unlike HTML, these buttons are doomed to
send their *text* instead of a configurable *value*. Or are they?

## What's The Problem, Exactly?

The buttons in a keyboard for Telegram have only one mandatory field
*text* that has the following description (as of March 1st, 2017 at
least):

> Text of the button. If none of the optional fields are used, it will be
> sent to the bot as a message when the button is pressed.

The *optional fields*, if you're curious, are available only to send
either a location or a phone number, not some generic, programmer-defined
value.

So, the bottom line is that, in the general case, a button is stuck to
sending whatever text it also displays. As anticipated in the introductory
teaser, this is unlike HTML buttons, where you can set independently the
text that is shown on the button and the value that is associated to the
button itself (which, in most cases, is also sent to the server).

## Why Is That A Problem, Exactly?

Suppose you want to implement a keyboard in which you want to track two
different variables, Happyness and Relax. You want to provide a button for
showing their current value, and some buttons to increse those values. It
might be something like this:

{% highlight text %}
+-----------+-----------+-----------+-----------+
| Happyness |    +1     |    +2     |    +3     |
+-----------+-----------+-----------+-----------+
|   Relax   |    +1     |    +2     |    +3     |
+-----------+-----------+-----------+-----------+
{% endhighlight %}

Do you see the problem with this keyboard? There are two versions of
button `+1`, `+2` and `+3`, which means that you will not be able to
figure out which exact button the user pressed, because in both `+1` cases
you would just be getting... `+1`.

## Unicode Zero-Width Rescuers

It turns out that Telegram keyboard buttons actually support Unicode
strings as texts, and most clients seem to display them correctly. So...
can we ab**\*COUGH\***use this? Sure!

Unicode has a few characters that you can *put there* but that will not
appear in the text. Some of them are:

- `U+200B`, a.k.a. `ZERO WIDTH SPACE`
- `U+200C`, a.k.a. `ZERO WIDTH NON-JOINER`
- `U+200D`, a.k.a. `ZERO WIDTH JOINER`

The `ZERO WIDTH` property is what interests us here: printing a zero-width
character basically means printing... nothing! So, the following strings:

{% highlight perl %}
"Hello"
"Hello\x{200B}"
"\x{200D}He\x{200C}llo\x{200B}\x{200C}"
{% endhighlight %}

will render exactly the same in the client, but will result in very
different strings sent from the client to the bot when pressed. Exactly
the mechanism we were after!

## Possible *Formal* Uses

The suggestion, at this point, is to figure out an encoding scheme for
attaching a custom (and unique) value to each button, that will allow us
to understand what button was pressed even though multiple buttons expose
the same visible text.

If you have only a few of them, you can for example keep a *counter* that
increases at each new button, and append that number of zero-width
characters, like this:

{% highlight perl %}
state $count = 0;
# ...
$button{text} .= "\x{200B}" x ++$count;
{% endhighlight %}

Upon reception of anything from the client, we can just extract the number
of these characters and we have our code back:

{% highlight perl %}
my ($empties) = $text =~ m{(\x{200B}+)\z}mxs;
my $button_id = length $empties;
{% endhighlight %}

Another alternative is to turn the numeric code into a binary sequence and
encode it using two caracters, one for the `1` and another one for the
`0`:

{% highlight perl %}
state $count = 0;
# ...
my $binary = unpack 'B32', pack 'N', ++$count;
$button{text} .= join '',
    map { $_ ? "\x{200C}" : "\x{200D}" }
    split //, $binary;
{% endhighlight %}

You get the idea. Once you successfully attach an integer value to the
button, you can keep a translation table on the bot side to associate some
"intended value" for the button, e.g.:

{% highlight perl %}
my %value_for = (
    1 => '/command-one',
    2 => '/command-one with-arg',
    3 => '/stop',
    # ...
);
{% endhighlight %}

Hence, you can follow this workflow:

- decide the *text* and the *value* for the button
- associate a *unique integer* code to this pair
- generate the *encoded text* from *text* and *unique integer*, using one
  of the techniques shown above
- set the `text` in the keyboard button to the *encoded text* - it will
  render just like *text* in the client
- when the button is pressed in the client, you will receive the
  *encoded text* back
- get the *unique integer* back from the *encoded text*
- use the *unique integer* to find the associated *text*/*value* pair
- use the *value* from the pair

and it will be like you put *text* in the button... but actually received
*value*.

## Perl Anyone?

The tecnique above has been used to create the new class
[Bot::ChatBots::Telegram::Keyboard][], if you are interested you are more
than welcome to try and use it!

The binary encoding explained in the previous section has been slightly
changed and extended to cope with:

- introducing a *keyboard identifier*, so that you can manage multiple
  keyboards and be able to figure out which keyboard was used in
  association to a received command;
- optimizing the space removing leading `0` characters.

For each button, you can define both the `text` that you want to be shown,
and the `_value` that you want to get back. The field name starts with an
underscore to cope for possible future extensions of the Telegram API
where they might introduce a *real* `value` field... making this blog post
so obsolete!

The introduction of the keyboard identifier and the space optimization
rely on the usage of all three characters introduced before:

- `U+200B` represents the `1`
- `U+200C` represents the `0`
- `U+200D` is used for marking the boundaries of the codes

## Wrap-up

Short article this time, but hopefully useful!

We saw that Telegram custom keyboards can be annoying in their overlapping
of the text printed on the button and the value that is sent back to the
bot when the button is pressed. We also saw that it is possible to work
around this limitation thanks to a few Unicode characters that have *zero
width*, so they don't appear when printed but are anyway still there and
are also sent by the client when the button is pressed. By means of some
not-so-clever encoding we can then associated a unique identifier to each
button in a keyboard, and ultimately a value of our choice.

Leave comments below if you have questions, until next time have fun!


[custom keyboards]: https://core.telegram.org/bots#keyboards
[Bot::ChatBots::Telegram::Keyboard]: https://metacpan.org/pod/Bot::ChatBots::Telegram::Keyboard
