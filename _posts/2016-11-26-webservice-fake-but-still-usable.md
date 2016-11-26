---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: WebService::Fake - but still usable!
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

Some time ago one of the rites of passage for a wannabe Perl programmer
was having its own take on a templating system. I duly complied with
[Template::Perlish][], which I'm quite happy about and I use anywhere
I can. Later, it seems that many people thought they would have a take at
building the next cool web service/application framework; here, I set
quite low expectactions, but it's still useful!

## Table of Contents

- TOC
{:toc}

## What is it about?

When building *real* stuff, quite often I have to interact with some
external API, usually provided as a webservice of some sort. Not always
I have direct access to it (especially from my laptop in some casual
place), or want to hammer the service while doing development. The classic
use case where a *mock* can be useful.

It's quite easy to setup such an example application by directly using one
of the available web frameworks. Among them, [Mojolicious][] is probably
best suited for the job, as it has a really low *entrance fee* for setting
it up (a basic installation takes only two distributions and is usually
very, very quick). If you already have [Dancer][] around, anyway, it's
also very easy to setup a simple application with it too. So, this is the
perfect scenario for *reinventing the wheel* and have a personal shot to
the problem.

I'm actually cheating a lot in this, because [WebService::Fake][] uses
[Mojolicious][] behind the scenes. *But hey, what did you expect from
something with `Fake` in its name*?!?

So there you go, [WebService::Fake][] is my personal take to having
something that lets you build your webservice (or web application, for
what it's worth) in some way. I've not prove it formally, but it *should*
let you do almost anything, in some strange and skewed perlish way: easy
things are easy, complicate things are somehow possible but you'd better
do them with something different!

## Care to show an example?

Sure! The web service definition is provided via a YAML file, like this:

{% highlight yaml %}
routes:
  - path: '/'
    body: '{"message":"Hello, World!"}'
{% endhighlight %}


Suppose it's saved as `hello-world.wsf`. You can then start the faker in
a shell (assuming `wsf` is in `PATH`):

{% highlight yaml %}
shell$ WEBSERVICE_FAKE=hello-world.wsf wsf daemon
[Sat Nov 26 15:30:00 2016] [info] Listening at "http://*:3000"
Server available at http://127.0.0.1:3000
{% endhighlight %}

The `daemon` should ring some bell about [Mojolicious][] I guess. We can
now do a `GET` in another shell and see what happens:

{% highlight text %}
shell$ curl -v http://localhost:3000/
* About to connect() to localhost port 3000 (#0)
*   Trying ::1...
* Connection refused
*   Trying 127.0.0.1...
* connected
* Connected to localhost (127.0.0.1) port 3000 (#0)
> GET / HTTP/1.1
> User-Agent: curl/7.26.0
> Host: localhost:3000
> Accept: */*
> 
* additional stuff not fine transfer.c:1037: 0 0
* HTTP 1.1 or later with persistent connection, pipelining supported
< HTTP/1.1 200 OK
< Content-Type: application/json
< Server: Mojolicious (Perl)
< Content-Length: 27
< Date: Sat, 26 Nov 2016 14:30:03 GMT
< 
* Connection #0 to host localhost left intact
{"message":"Hello, World!"}* Closing connection #0
{% endhighlight %}

A few comments:

- it works! This can be surprising for something that prides to be *fake*;
- the `Server` is another confirmation we're building on top of
  [Mojolicious][]...
- the default `Content-Type` is set to `application/json`. There's
  a reason why the module name starts with `WebService`, after all,
  although you can change it as we will see shortly
- whatever we set as the `body` is returned as... the body.

## Should I be impressed?

Just for comparison, the equivalent [Mojolicious::Lite][] code for the
previous section would be (without too much golfing, I admit):

{% highlight perl %}
use Mojolicious::Lite;
get '/' => sub {shift->render(json => {message => 'Hello, World!'})};
app->start;
{% endhighlight %}

So yeah... [WebService::Fake][] lets you spare a few strokes, but it's
nothing you couldn't get directly from [Mojolicious][] anyway.


### Use the head(ers)

Let's complicate the web service definition a bit, for example to set
a new server name and set a customized header too:

{% highlight yaml %}
routes:
  - path: '/'
    body: '{"message":"Hello, World!"}'
    headers:
      - Server: 'WebService::Fake/0.001'
        X-Whatever: 'whatever is whatever'
{% endhighlight %}

It does what you expect:

{% highlight text%}
shell$ curl -v http://localhost:3000/
#....
< HTTP/1.1 200 OK
< Content-Length: 27
< Date: Sat, 26 Nov 2016 14:46:10 GMT
< X-Whatever: whatever is whatever
< Server: WebService::Fake/0.001
< Content-Type: application/json
< 
* Connection #0 to host localhost left intact
{"message":"Hello, World!"}* Closing connection #0
{% endhighlight %}

This is easy with [Mojolicious::Lite][] too of course:

{% highlight perl %}
use Mojolicious::Lite;
get '/' => sub {
    my $c = shift;
    my $headers = $c->res->headers;
    $headers->server('WebService::Fake/0.001');
    $headers->header('X-Whatever' => 'whatever is whatever');
    $c->render(json => {message => 'Hello, World!'});
};
app->start;
{% endhighlight %}

It's just *slightly* more complicated but still quite compact.
[Mojolicious][] provides a few headers shortcuts but you have somehow to
remember them, although you can fallback with the generic `header` method
for both known and custom ones.

The real difference is actually that [Mojolicious][] provides a complete
(and consistent) set of tools as part of the toolkit, while
[WebService::Fake][] tries to optimize for the case where you somehow
*already know* the shape of the answer you want to get, and want to
describe it as quickly as possible.

### Craft your answer

As a last example for this section, suppose you also want to provide
a different return code, e.g. `203 Non-Authoritative Information`. It's
easy to do this in our definition YAML:

{% highlight yaml %}
routes:
  - path: '/'
    body: '{"message":"Hello, World!"}'
    code: 203
    headers:
      - Server: 'WebService::Fake/0.001'
        X-Whatever: 'whatever is whatever'
{% endhighlight %}

Again, it's up to the promise:

{% highlight text%}
shell$ curl -v http://localhost:3000/
#....
< HTTP/1.1 203 Non-Authoritative Information
< X-Whatever: whatever is whatever
< Content-Length: 27
< Server: WebService::Fake/0.001
< Date: Sat, 26 Nov 2016 14:58:20 GMT
< Content-Type: application/json
< 
* Connection #0 to host localhost left intact
{"message":"Hello, World!"}* Closing connection #0
{% endhighlight %}

The same thing in [Mojolicious::Lite][]:

{% highlight perl %}
use Mojolicious::Lite;
get '/' => sub {
    my $c = shift;
    my $headers = $c->res->headers;
    $headers->content_type('application/json');
    $headers->server('WebService::Fake/0.001');
    $headers->header('X-Whatever' => 'whatever is whatever');
    $c->res->body('{"message": "Hello, World!"}');
    $c->rendered(204);
};
app->start;
{% endhighlight %}

Things get a bit more complicated. To set the custom HTTP status code, we
have to take a different route for rendering the body (I hereby declare my
ignorance with respect to how keep the `json => {...}` alive, but it's not
essential), because `render` is not useful here.

Again, it's a matter of understanding what shortcuts are most useful in
the general case: in a real application/service, [Mojolicious][] takes
sane defaults, in this whole *faking someone else's webservice* context
[WebService::Fake][] goes for a different optimization route.

## I've only 2 minutes left...

So let's go fast. If you already have the right answers to the requests
you want to fake, then you should be all set. If you need to add a bit of
logic though...

### Using Templates

Body and headers are actually defined in terms of [Template::Perlish][]
templates, so this does what you think:

{% highlight yaml %}
routes:
  - path: '/'
    body: '{"now":"[%= scalar localtime %]"}'
{% endhighlight %}

### Accessing variables

You can *spice up* your fake answers including a few elements from the
request too, e.g. parameters:

{% highlight yaml %}
routes:
  - path: '/'
    body: '{"name":"[% params.name %]"}'
{% endhighlight %}


### Placeholders

Did I mention that there's [Mojolicious][] providing features? You can
define routes with placeholders, and later access them:

{% highlight yaml %}
routes:
  - path: '/hello/:name'
    body: '{"greeting": "hello", "name":"[% stash.name %]"}'
{% endhighlight %}

### Defaults

Have a lot of routes and want to set common things once and for all?

{% highlight yaml %}
defaults:
  headers:
    - Content-Type: text/plain
      X-Whatever: whatever
      Server: 'Something/Fake 1.0'
routes:
  - path: '/hello/:name'
    body: 'Hello, [% stash.name %]!'
  - path: '/negate/:something'
    body: '[% stash.something %] is no-no!'
{% endhighlight %}

### Body wrapper

Suppose you have to fake some API that has some boilerplate that never
changes across different routes, and you want to change only a single
part. This is where a body wrapper comes handy:

{% highlight yaml %}
defaults:
  body_wrapper: |
    {
      "status": "OK",
      "timestamp": "[%= scalar localtime %]",
      "data": [% content %]
    }
routes:
  - path: '/hello/:name'
    body: '{"greeting": "hello", "name":"[% stash.name %]"}'
  - path: '/negate/:something'
    body: '{"action": "negate", "what": "[% stash.something %]"}'
  - path: '/text/hello/:name'
    headers:
      - Content-Type: text/plain
    body_wrapper: ~
    body: 'Hello, [% stash.name %]!'
{% endhighlight %}

As you can see from the last route, you can selectively disable the
wrapper on a per-route basis.

## Time's up!

You have surely noticed that there's no specific support for security and
the like, there's no explicit support for sanitizing your inputs, escaping
your output, etc. etc. i.e. all those goodies that help you build
something robust to put into the wild. 

So what's it good for?!? I told you in the beginning... fake web services,
that's it! It's meant to be a sparring partner for your programs to
excercise against something that can actually answer them something, not
to put in front of your "customers" (so don't try to do that!).

We didn't go too much in depth, and you might find a few additional tricks
if you're curious enough to take a look at the [docs][WebService::Fake].

Whatever you decide to make of it... happy faking!


[Template::Perlish]: https://metacpan.org/pod/Template::Perlish
[Mojolicious]: https://metacpan.org/pod/Mojolicious
[Mojolicious::Lite]: https://metacpan.org/pod/Mojolicious::Lite
[Dancer]: https://metacpan.org/pod/Dancer
[WebService::Fake]: https://metacpan.org/pod/distribution/WebService-Fake/script/wsf
