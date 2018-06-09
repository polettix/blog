---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: A Simple Telegram Bot
image:
   feature: kakadu-uccello.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

[Telegram][] is a messagging platform/App much like [WhatsApp][] and
companions. One nifty feature is that it allows integrating *bots*,
contarily to [WhatsApp][]... let's see an example in Perl.

## Telegram Bot HowTo

There are a few steps to get your bot up to speed, [full instructions
here][telegram-bots-intro]. The gist is:

- register yourself in Telegram
    - this allows you to register your bot
- open a chat with [BotFather][] and follow instructions
    - you will need to provide a name for your bot, we'll call it
      *prova_bot* in the following;
    - at the end of the process you are provided with a *token*, that is
      a string like `nnnnnnnnn:ssssssssssssssssssssssss-ssssssssss` where
      `n` are digits and `s` are alphanumeric characters
- code your bot
- connect to [Telegram][] authenticating with the *token* obtained in
  a previous step

In the following, we will assume that you set your *token* in the
environment variable `TOKEN`, e.g. in a `bash` shell:

{% highlight bash %}
$ export TOKEN='nnnnnnnnn:ssssssssssssssssssssssss-ssssssssss'
{% endhighlight %}

## A *Very* Simple Telegram Bot

For building our bot we will rely upon [Bot::ChatBots::Telegram][] from
[CPAN][]. We'll just take the [example][longpoll-example]:

{% highlight perl %}
#!/usr/bin/env perl
use strict;
use warnings;
use Log::Any::Adapter qw< Stderr >;
use Bot::ChatBots::Telegram::LongPoll;

my $token = shift || $ENV{TOKEN};

my $lp = Bot::ChatBots::Telegram::LongPoll->new(
   token     => $token,
   processor => \&processor,
   start     => 1,
);

sub processor { # tube-compliant
   my $record = shift;
   my $text = $record->{payload}{text};
   print "$text\n";
   $record->{send_response} = "you said: '$text'";
   return $record; # follow on..
}
{% endhighlight %}

Save this as `longpoll`. Now you can just start the bot (make sure to have
[Bot::ChatBots::Telegram][] installed and reachable!):

{% highlight bash %}
$ perl longpoll "$TOKEN"
{% endhighlight %}

If you `export`ed the environment variable `TOKEN` you don't need to pass
it on the command line of course.

At this point you're ready to connect to your bot! Assuming, again, that
your bot's name is *prova_bot*, you can look for it in [Telegram][] (its
address would be
[https://telegram.me/prova_bot](https://telegram.me/prova_bot) if you use
the web application in a browser). Start chatting with it and it will echo
everything back! Very useful!

What is happening:

- your application is running a loop and constantly querying [Telegram's
  API][tg-api] to seek new incoming messages. This method is called
  *polling* and this is why we named our file `longpoll`;
- as soon as any message is received, `Bot::ChatBots::Telegram::LongPoll`
  puts it in a data structure and calls your `processor` sub defined in
  the file. This is the sense of the line `processor => \&processor`;
- you process the incoming message as you like in your own callback
  function. It is supposed to return the record itself or something else,
  see [Data::Tubes][] for more details. If you "just" want to send
  a simple textual response, just populate the `send_response` key as in
  the example file above, but of course you might want to explore sending
  photos, videos, documents, etc. etc.

A few considerations:

- **PRO**: *extremely* simple to setup
- **PRO**: allows testing your own logic very quickly, just stop and
  restart the process
- **PRO**: works well from anywhere with access to the [Telegram
  API][tg-api] endpoint as a client (hence also behind proxies)
- **CON**: the polling mechanism is suboptimal

## Growing Up: Web Hooks

The [Telegram API][tg-api] also allows using a different mechanism for
connecting a bot, called *webhook*. In this alternative you can provide
a *callback URL* served by your bot: whenever one or more messages are
available for it, [Telegram][] will take care to send them along to that
endpoint. No more polling, yay!

Here is an [example][webhook-example] that we will put in a file `webhook`:

{% highlight perl %}
#!/usr/bin/env perl
use strict;
use warnings;
use Log::Any qw< $log >;
use Log::Any::Adapter;
use Mojolicious::Lite;
Log::Any::Adapter->set('Stderr');

my $token   = $ENV{TOKEN};
my $bot_url = $ENV{BOT_URL} || 'https://example.com/mybot';

plugin 'Bot::ChatBots::Telegram' => instances => [
   [
      'WebHook',
      processor  => \&processor,
      register   => 1,
      token      => $token,
      unregister => 0,
      url        => $bot_url,
   ],
];

app->start;

sub processor { # tube-compliant
   my $record = shift;
   my $text = $record->{payload}{text};
   print "$text\n";
   $record->{send_response} = "you said: '$text'";
   return $record; # follow on..
} 
{% endhighlight %}

The `processor` function is exactly the same as before, which is good: as
soon as you are ready to step up your bot as a *web hook*, you don't need
to change your logic, just switch gears in the interface towards
[Telegram][].

The script is started like this:

{% highlight bash %}
$ # set TOKEN
$ # set BOT_URL
$ perl webhook daemon
{% endhighlight %}

We are relying upon [Mojolicious][] here, that will start a server to
implement the bot endpoint; see the documentation for all options upon
starting the program.

We are supposed to provide the exact location of this endpoint in the
Internet, in a place reachable by the [Telegram API][tg-api], which is why
we have to set the variable `BOT_URL`.

One requirement when using *web hooks* is that the URL *MUST* be secure, i.e.
the scheme must be `HTTPS`. This means that you will have to setup certificates
and the proper encryption layer, which is in any case quite easy to do with
[Mojolicious][]. You will probably have to read a bit more if you plan on
running the application behind a reverse proxy.

Summarizing:

- **PRO**: *production* level, allows you to start multiple instances and
  distribute the load instead of relying on polling
- **CON**: quite more difficult to set up:
    - requires setting up TLS, which means either generating certificates
      or getting valid ones (e.g. see [Let's Encrypt][letsencrypt] for
      this)
    - requires a place that is *visible* from [Telegram]'s servers, i.e.
      exposed on the Internet (with all security implications...)


## Security Caveat

You have to do your homework and assess the security of [Telegram][] for
your case. I read around that they basically baked their own security
layer which is normally suboptimal. Additionally, it's not possible to use
bots in private encrypted chats.


## Release Your Bots!

I hope you were intrigued by the simplicity to build a bot for Telegram.
We did just a little more than `Hello, World!` of course, but the logic of
your bot is... yours! You know that you can do without much of the
scaffolding, because it's already there for you.

Have fun!

## Updates

The [longpoll][longpoll-example] example has been updated to initialize
`Log::Any`, so the verbatim copy above has been updated accordingly.


[Telegram]: https://www.telegram.org/
[WhatsApp]: https://www.whatsapp.com/
[Bot::ChatBots::Telegram]: https://metacpan.org/pod/Bot::ChatBots::Telegram
[Data::Tubes]: https://metacpan.org/pod/Data::Tubes
[CPAN]: https://www.metacpan.org/
[longpoll-example]: https://github.com/polettix/Bot-ChatBots-Telegram/blob/master/eg/longpoll
[webhook-example]: https://github.com/polettix/Bot-ChatBots-Telegram/blob/master/eg/webhook
[telegram-bots-intro]: https://core.telegram.org/bots
[BotFather]: https://telegram.me/botfather
[tg-api]: https://core.telegram.org/bots/api
[Mojolicious]: https://metacpan.org/pod/Mojolicious
[letsencrypt]: https://letsencrypt.org/
