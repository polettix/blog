---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Dokku - Your Tiny PaaS
image:
   feature: kakadu-volo-insieme.jpg
   credit: Uccelli al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

Do you like [Platform as a Service][PaaS]? Ever wondered about rolling
your own, especially if you have some capacity that you don't use and you
are always struggling deploying your stuff? Meet [Dokku], *[t]he smallest
PaaS implementation you've ever seen*.

## Table of Contents

- TOC
{:toc}

## Platform as a Service?

Wikipedia describes [Platform as a Service][PaaS] (abbreviated PaaS) like
this:

> Platform as a service (PaaS) is a category of cloud computing services
> that provides a platform allowing customers to develop, run, and manage
> applications without the complexity of building and maintaining the
> infrastructure typically associated with developing and launching an
> app.

One of the most widely used [PaaS][] platforms that I know of is
[Heroku][]. Once you set up your project on Heroku (which takes very
little energy with a few commands and configuration files), the promise is
that your development/deployment workflow will be this:


{% highlight text %}
# hack on your code
$ vi app.pl

# commit your changes
$ git commit app.pl -m 'Add killer feature'
[master 7bb308e] Add killer feature
1 file changed...

# push new commit(s) to the repository in Heroku
$ git push heroku master
Counting objects: 6, done.
# ... several lines of automated deployment...
=====> Application deployed:
       http://sample-mojo.example.com
{% endhighlight %}

So yes, the promise is that all your deployment effort is *just* the `git
push` command. Nifty, uh?

### Is it right for me?

Should you use this? It depends on you, what your goals are and what level
of control you want to retain. Do you have a personal project, or are just
starting a new one and you want to get something up and running before you
lose momentum? Then it's probably for you. Do you have a well-established
project with some complex gating rules for going in production? Chances
are you already have something in place, and switching would not be
beneficial.

Unless... you want to have a sandbox/staging environment where you want to
be able to hack quickly. So, there are plenty of occasions in which
[PaaS][] can be beneficial, especially if you want to concentrate on the
coding part and have little to no resources to take care of the system
management part.

Public [PaaS][] services like [Heroku][] come with a cost, of course. You
might be a shiny new startup in Silicon Valley and got a voucher for one
of them, of course; in this case you just have to reclaim your voucher.
Like other cloud services (e.g. IaaS), it's a nice way for investors to
give you money that they know will be invested in the infrastructure for
your services, instead of parties.

For the average people in the rest of the world, anyway, the story can be
different. Whether it's the right choiche to shell out money for
a [PaaS][] service or not is something that only you can assess; it's good
to know about it anyway. And also know what the alternatives are.

### I like it, but I have this server...

Doubts about using [PaaS][] are especially fit if you already have
capacity that you are using, or planning to use, for your project. It
feels like a waste of resources, doesn't it? This is where *DIY* [PaaS][]
projects come to the rescue: they allow you to setup a [PaaS][]-like
workflow but leveraging on infrastructure that you might already have (or
that you feel more comfortable with).

One use case I find particularly useful is for test services or very
little personal projects. *Dynos* in [Heroku][] each have a cost,
independently of how much resources they actually consume: in my private
[PaaS][] I can easily stuff a lot of them inside a single VPS, spending
a lot less money. The drawback is more administration on my side and less
robustness, of course.

## Dokku

[Dokku][] is a tiny [PaaS][] platform that you can install on your server.
Note that I used the singular form: it's meant for very restricted
environments where all you have *and need* is one single server; nothing
important or *production* that you care too much, so.

It is described as:

> The smallest PaaS implementation you've ever seen

and rightly so: it's a smart integration of other tools that can keep the
project itself up in a few (well, a couple thousand) lines of Bash code.

It's easy to [get
started](http://dokku.viewdocs.io/dokku/getting-started/installation/) so
I will not repeat the official steps here.

If you want to give it a try, you can also head to [Digital Ocean][] and
use one of their [one-click
apps](https://www.digitalocean.com/products/one-click-apps/). I don't
*completely* like this approach because their deployment is Ubuntu (I tend
to like Debian more) and their [Dokku][] version is `0.6.5` (there's
`0.7.2` around) right now.

You can find a small project [dokku-boot][] on GitHub that will help you
set up `0.7.2` on a new Debian instance (it should work just fine on
Ubuntu too). It's more or less a simple wrapper around the main
installation instructions, but it also installs a couple of handy
extensions for [Dokku][], like support for [Let's Encrypt][Let's Encrypt
plugin] (for free and hassle-free SSL certificates), [Redis] and
[Postgres].

From the `README`:

- Spin up a new VPS somewhere, e.g. [Digital Ocean][]. I usually choose
  the latest Debian release. You can select the smallest size if you just
  want to give it a try. (And please... set up and use SSH keys, it's 2016
  or later!). Let's say we save the IP address of this VPS in variable
  `DOKKU_IP`

- Log in a shell in the VPS as user `root` and run:

{% highlight bash %}
apt-get update
apt-get install -y curl perl
curl -LO https://github.com/polettix/dokku-boot/raw/master/dokku-boot.pl
perl dokku-boot.pl
{% endhighlight %}

- Wait for installation to complete, then go to `http://$DOKKU_IP/` and
  complete the setup of [Dokku][].

You end up with a reasonably *close* system (only ports `22`, `80` and `443`
will be open for incoming traffic). The last point can be somehow commented
further.

You will land in a page where the SSH keys you defined for user `root` are used
by default to initialize access to user `dokku` too. If you defined more keys,
only the first one will *actually* be used, so ensure that the one you will use
is actually the first one.

Next, you can define the hostname. Here we will assume that you *do own*
something registered directly after a [public suffix][]. You can do *most* of
what we describe in the following if you don't (actually, the only thing
you will struggle with is the [Let's Encrypt plugin][]). As of October
2016, owning one such domain can cost as low as about 3$ ([ClouDNS][]
usually has a few offers in their [pricing
list][cloudns-domains-pricing]). In this example we will assume to own the
ever-present `example.com`.

After this, you get to decide how your application will appear to the world.
There are two alternatives:

- Take the form `application-name.example.com`. This is probably the most
  elegant, but it is available only if you actually set a hostname and not an
  IP address. We will stick with this as we are assuming to own `example.com`
  (which we don't... of course!)
- Take the form `<domain-or-ip>:<port>`, where [Dokku][] will allocate a port
  for each application. This will not be described here, as it requires some
  additional settings on the `iptables` firewall rules for letting the ports to
  be accessible from the outside.

After all of this, you can just submit the form in the page and you will be all
set (you will be redirected to [Dokku][]'s documentation page after this step).

In the case you actually own a domain and you have control over its DNS
settings (as in our example), you should also set up a wildcard resolution
towards your [Dokku][] installation, with a A record like this:

{% highlight text %}
*.example.com IN A $DOKKU_IP
{% endhighlight %}

where `$DOKKU_IP` must be expanded with your installation's IP address, of
course. This setting will guarantee that a resolution for `someapp.example.com`
will actually be pointed towards your personal [PaaS][] system.

## Work On A Project

Now you have your personal [PaaS][] instance up and running, waiting for
your code to come. I'm a Perl enthusiast, so my example will be in Perl.

In the following sub-sections, we'll see:

- a few assumptions about how your project is structured
- what you have to do for connecting it to your [Dokku][] instance
- enjoy!

### Starting point

Our starting point is a project that is tracked with [git][]. In this
example, we will assume that we want to work on a simple `Hello World!`
application (what else) built with [Mojolicious][], and we will see a
couple of directions for evolving to a more complex application. You can
find the whole example in [this repository][sample-mojo] in GitHub if you
want to skip its construction.

The application itself (in file `app.pl`) is quite straightforward:

{% highlight perl %}
#!/usr/bin/env perl
use Mojolicious::Lite;
get '/' => sub {
my $c = shift;
   $c->res->headers->content_type('text/plain');
   $c->render(text => "Hello, World!\n");
};
app->start;
{% endhighlight %}

You are probably already using something to track the automation of
installing the dependencies, we will use a `cpanfile` because it's used by
both [cpanm][] and [carton][] (the former being quite important for our
later automation, as we will see). It's quite straightforward in this
case:

{% highlight perl %}
requires 'Mojolicious', '7.08';
{% endhighlight %}

We can install the module locally and check that it works actually:

{% highlight text %}
$ cpanm -L local --notest --quiet --installdeps .
Successfully installed IO-Socket-IP-0.38
Successfully installed Mojolicious-7.08
2 distributions installed

$ alias ploc="perl -I'$PWD'/local/lib/perl5"

$ ploc app.pl get /
[Sat Oct  8 18:40:34 2016] [debug] GET "/"
[Sat Oct  8 18:40:34 2016] [debug] Routing to a callback
[Sat Oct  8 18:40:34 2016] [debug] 200 OK (0.000391s, 2557.545/s)
Hello, World!
{% endhighlight %}

We only lack tracking it with [git][] at this point:

{% highlight text %}
# https://hackernoon.com/lesser-known-git-commands-151a1918a60
# see hint about `git it`
$ git init . && git commit -m Root --allow-empty

$ git add . && git commit -m 'Import initial files'
{% endhighlight %}

Up to this point there was almost no overhead related to [Dokku][]: we
would have written or application, installed the needed modules and
tracked changes with [git][] anyway.

### PaaS project setup in Dokku

Dokku mostly works sending commands via `ssh` to the user `dokku` in the
machine where it is installed. For this reason, it's useful to define the
following alias:

{% highlight text %}
$ alias dokku="ssh 'dokku@$DOKKU_IP'"
{% endhighlight %}

The following steps are needed whatever application you want to deploy via

{% highlight text %}
# we will call our application "sample-mojo"
$ dokku apps:create sample-mojo

# we assume to be in our project sample-mojo directory
$ git remote add dokku "dokku@$DOKKU_IP:sample-mojo"
{% endhighlight %}

Are we ready for the first push? Well... not yet. We still have to fix a couple
things:

- how will [Dokku][] figure out how to build our project? Like installing the
  right modules, etc.?
- how will it know what to run?

It turns out the [heroku-buildpack-perl-procfile][] project on GitHub can ease
our life for both steps, let's see how.

#### How to build: `.buildpacks`

[Heroku][] and [Dokku][] don't support [Perl][] applications out of the box.
I know, it's a shame, but it's easy to fix this via so-called [custom
buildpacks][] (which are the same as [Heroku][]'s) and many different clever
persons did this in slightly different ways.

The philosophy under [heroku-buildpack-perl-procfile][] is to make no
assumption on your application, apart that it's written in [Perl][] and will
need modules from either [CPAN][] or from some project-local directory.

If you mostly stick with web projects and you want to run them via [Starman][],
you will probably want to look into some other package. I wanted to keep
control, so evolved the awesome [original
heroku-buildpack-perl-procfile][khbpp] by [kazeburo][] to suit my needs.

To tell [Dokku][] that you want to use a buildpack you have a couple options
(see [custom buildpacks][] for some alternatives), in our case we will just add
a `.buildpacks` file in our project's root directory:

{% highlight text %}
# in the project's root directory
$ echo https://github.com/polettix/heroku-buildpack-perl-procfile.git \
     > .buildpacks

$ git add .buildpacks && git commit -m 'Add .buildpacks for Dokku builds'
{% endhighlight %}

#### How to run: `Procfile`

The *standard* way to describe an application in [Heroku][] is via a so-called
`Procfile` (so-called in this context means that you *MUST* call it with the
initial uppercase an the rest, otherwise it will not work!). It contains a line
for each component of your application, so that you can have e.g. a `web` part,
a `database` part, some `worker`s and so on.

You can name components with almost any reasonable name (e.g. use alphanumerics
or look for the rules). [Dokku][] assign no particular semantic to the names,
*except* to `web` which has (at least) two attached strings:

- one instance of a `web` service is always started initially (unless
  explicitly configured differently or no `web` is defined)
- `web` instances are accessible from the outside, there's an [nginx][] reverse
  proxy that is set-up automatically.

We will start with one single `web` component, so our `Procfile` is quite
simple:

{% highlight text %}
web: perl ./app.pl daemon --listen "http://*:$PORT"
{% endhighlight %}

As you can see, when [Dokku][] starts a new web instance, it also passes the
`PORT` environment variable so that your application can bind to the correct
port. How this parameter is used is dependent on the specific application
and/or framework that the application is using.

As for the `.buildpacks` file, we have to add `Procfile` to our [git][] project
and commit:

{% highlight text %}
$ git add Procfile && git commit -m 'Add Procfile for Dokku runs'
{% endhighlight %}

#### Ready!

At this point, we are ready for our first push to our [Dokku][] instance, YAY!
In our first push we will also set the `--set-upstream` so that our following
`push`es of `master` will be automatically sent to the remote `dokku`:

{% highlight text %}
$ git push --set-upstream dokku master
Counting objects: 6, done.
# ... several lines of automated deployment...
=====> Application deployed:
       http://sample-mojo.example.com

To dokku@example.com:sample-mojo
* [new branch]      master -> master
Branch master set up to track remote branch master from dokku.
{% endhighlight %}

Now we are ready to send the very first HTTP request towards our new service.
As you can see, there's a couple of lines that tells us where the service
lives:

{% highlight text %}
=====> Application deployed:
http://sample-mojo.example.com {% endhighlight %}

So, it's easy to send the request:

{% highlight text %}
$ curl http://sample-mojo.example.com
Hello, World!
{% endhighlight %}

Seems to work!

At this point you can start hacking on your application and follow the pattern
we described in the beginning:

{% highlight text %}
# hack on your code
$ vi app.pl

# commit your changes
$ git commit app.pl -m 'Add killer feature'
[master 7bb308e] Add killer feature
1 file changed...

# push new commit(s) to the repository in Heroku
$ git push heroku master
Counting objects: 6, done.
# ... several lines of automated deployment...
=====> Application deployed:
http://sample-mojo.example.com
{% endhighlight %}

## Moar! Moar! Moar!

You can get tired of your single-service application pretty soon. Want to add
a database and cannot live with [SQLite][] for too long? Need to add some
*worker* process to handle housekeeping or long-running jobs? Concentrating all
in a single instance of a *web* thingie is clearly not the right way to go
unless you're out of headaches.

This is where your `Procfile` comes to the rescue. For every *kind* of
additional service, you just need to add a line with the name of the service
and the command line to start it.

### First, evolve the code...

In our example, we will add support for a [Minion][] worker trying to replicate
the example in the [DESCRIPTION][minion-description], with just a little twist
in the database used (we're going to use [SQLite][] in this example). This is
how we transform our `app.pl` into:

{% highlight perl %}
#!/usr/bin/env perl
use Mojolicious::Lite;

plugin Minion => {SQLite => 'sqlite:test.db'};

# Slow task
app->minion->add_task(poke_mojo => sub {
 my $job = shift;
 $job->app->ua->get('mojolicious.org');
 $job->app->log->debug('We have poked mojolicious.org for a visitor');
});

# Perform job in a background worker process
get '/' => sub {
 my $c = shift;
 $c->minion->enqueue('poke_mojo');
 $c->render(text => 'We will poke mojolicious.org for you soon.');
};

app->start;
{% endhighlight %}

Of course we will need to make sure that the needed plugins are correctly
installed, so our `cpanfile` becomes:

{% highlight perl %}
requires 'Mojolicious', '7.08';
requires 'Minion', '6.0';
requires 'Minion::Backend::SQLite', '0.007';
{% endhighlight %}

Again, we can install them locally and make sure that everything works fine:

{% highlight text %}
$ cpanm -L local --notest --quiet --installdeps .
...
{% endhighlight %}

Now, let's make a little local test: we first generate a `get` to the regular
web application, then we start the minion (we might make it in two different
shells but it will work anyway because [Minion][] is decoupled through the
database):

{% highlight text %}
$ alias ploc="perl -I'$PWD'/local/lib/perl5"

$ ploc app.pl get /
[Sat Oct  8 22:53:42 2016] [debug] GET "/"
[Sat Oct  8 22:53:42 2016] [debug] Routing to a callback
[Sat Oct  8 22:53:42 2016] [debug] 200 OK (0.012938s, 77.292/s) 
We will poke mojolicious.org for you soon.

$ ploc app.pl minion worker
[Sat Oct  8 22:53:47 2016] [debug] Worker 18861 started
[Sat Oct  8 22:53:47 2016] [debug] Checking worker registry and job queue
[Sat Oct  8 22:53:47 2016] [debug] Performing job "1" with task "poke_mojo" in process 18862
[Sat Oct  8 22:53:47 2016] [debug] We have poked mojolicious.org for a visitor
{% endhighlight %}

### Then, add a new service...

Now, we make sure that the Minion worker is defined in `Procfile`:

{% highlight text %}
web:    perl ./app.pl daemon --listen "http://*:$PORT"
minion: perl ./app.pl minion worker
{% endhighlight %}

### Then, learn about scaling...!

At this stage, we *just* need to commit and push, right? Let's see:

{% highlight text %}
$ git commit -am 'Evolve example to use Minion'
[master af4ba9d] Evolve example to use Minion
3 files changed, 18 insertions(+), 3 deletions(-)

$ git push
Counting objects: 9, done.
#... some building happens here...
-----> Discovering process types
       Procfile declares types -> web, minion
#... something else happens...
=====> web=1
-----> Attempting...
{% endhighlight %}

So, it seems that [Dokku][] knows about our `minion` service type, but it
starts none. Now you understand what we meant before when we said that `web` is
special because [Dokku][] starts one by default!

A quick look to the current scaling setup is worth the time as a double check:

{% highlight text %}
$ dokku ps:scale sample-mojo
-----> Scaling for sample-mojo
-----> proctype           qty                                                                          
-----> --------           ---                                                                          
-----> web                1
{% endhighlight %}

So... no `minion`, no party? Fortunately, `ps:scale` is not only for querying
the current status, but for changing it as well; let's bump `minion` then:

{% highlight text %}
$ dokku ps:scale sample-mojo minion=1
-----> Scaling sample-mojo:minion to 1
#... some lines...
=====> web=1
=====> minion=1
#... some lines...
=====> Application deployed:
       http://sample-mojo.example.com
{% endhighlight %}

Now that's right!

### Then, we think we're ready **but**...

Are we ready now? Well... let's see!

{% highlight text %}

$ curl http://sample-mojo.example.com
We will poke mojolicious.org for you soon.

# now we wait a few seconds to give the worker process the time get hold of the
# new task. The number of seconds might be reduced but let's play safely
$ sleep 5

$ dokku logs sample-mojo
2016-10-08T21:10:42.160743389Z app[minion.1]: [Sat Oct  8 21:10:42 2016] [debug] Worker 8 started
2016-10-08T21:10:42.182393541Z app[minion.1]: [Sat Oct  8 21:10:42 2016] [debug] Checking worker registry and job queue
2016-10-08T21:10:30.978550240Z app[web.1]: [Sat Oct  8 21:10:30 2016] [info] Listening at "http://*:5000"
2016-10-08T21:14:44.107362361Z app[web.1]: [Sat Oct  8 21:14:44 2016] [debug] GET "/"
2016-10-08T21:14:44.108955921Z app[web.1]: [Sat Oct  8 21:14:44 2016] [debug] Routing to a callback
2016-10-08T21:14:44.127066080Z app[web.1]: [Sat Oct 8 21:14:44 2016] [debug] 200 OK (0.019002s, 52.626/s)
{% endhighlight %}

Uhm... the `worker` seems still unaware of the request from the frontend...
what's happening?

It turns out that it's a database issue here. When we run the example in our
development box, *both* the web service and the minion worker were running in
the same directory of the same box. On the other hand, in this case the two are
running inside two separate *Linux containers* created via [Docker][], so it's
*like* they are running in separate hosts.

Fact is that [SQLite][] is a **single** file database: for our system to work,
both the web and the minion services MUST operate on the same file! Now you
understand why [dokku-boot][] includes [Postgres][] and [Redis][] plugins,
don't you?

### It will not take long now!

The problem still remains though: how do I manage to share files/directory
across services? That's simple... use *persistent* `storage`! They are
directories created in the [Dokku][] node that will be *mounted* in your
services, let's see how to do this.

First, we need a place where our shared directory will live. It MUST be
accessible with full permissions by user `dokku`, so we will stick with the
best practice (as of October 2016, at least) of using
`/var/lib/dokku/data/storage` and we will ask [Dokku][] to use sub-directory
`sample-mojo` inside it:

{% highlight text %}
$ dokku storage:mount sample-mojo \
     /var/lib/dokku/data/storage/sample-mojo:/app/shared
{% endhighlight %}

The command above tells us that the *host* directory `/var/lib/.../sample-mojo`
will be mapped to directory `/app/shared` inside the containers (all of them)
where the application will run.

As of version `0.7.2`, you don't need to create the shared directory
beforehand: [Dokku][] will take care to create one for you. The directory
will be created only when the first container will need it.

Now we just have to tell our application where to put/look for the shared
database, which is a single-line change:


{% highlight text %}
$ git diff
diff --git a/app.pl b/app.pl
index 70b7418..25183d8 100755
--- a/app.pl
+++ b/app.pl @@ -1,7 +1,7 @@ #!/usr/bin/env perl use Mojolicious::Lite;
 
-plugin Minion => {SQLite => 'sqlite:test.db'};
+plugin Minion => {SQLite => 'sqlite:/app/shared/test.db'};
 
 # Slow task
 app->minion->add_task(poke_mojo => sub {

$ git commit -am 'Change position of Minion database'
[master 8a139bc] Change position of Minion database
 1 file changed, 1 insertion(+), 1 deletion(-)
{% endhighlight %}

Now let's push and try again:

{% highlight text %}
$ git push
#... wait for it...

$ curl http://sample-mojo.example.com/
We will poke mojolicious.org for you soon.

# now we wait a few seconds to give the worker process the time get hold of the
# new task. The number of seconds might be reduced but let's play safely
$ sleep 5

$ dokku logs sample-mojo
2016-10-08T21:53:17.079481775Z app[minion.1]: [Sat Oct  8 21:53:17 2016] [debug] Worker 7 started
2016-10-08T21:53:17.106477103Z app[minion.1]: [Sat Oct  8 21:53:17 2016] [debug] Checking worker registry and job queue
2016-10-08T21:54:42.166105068Z app[minion.1]: [Sat Oct  8 21:54:42 2016] [debug] Performing job "1" with task "poke_mojo" in process 143
2016-10-08T21:54:42.245450605Z app[minion.1]: [Sat Oct  8 21:54:42 2016] [debug] We have poked mojolicious.org for a visitor
2016-10-08T21:53:05.831553141Z app[web.1]: [Sat Oct  8 21:53:05 2016] [info] Listening at "http://*:5000"
2016-10-08T21:54:41.207238916Z app[web.1]: [Sat Oct  8 21:54:41 2016] [debug] GET "/"
2016-10-08T21:54:41.210001387Z app[web.1]: [Sat Oct  8 21:54:41 2016] [debug] Routing to a callback
2016-10-08T21:54:41.221802741Z app[web.1]: [Sat Oct  8 21:54:41 2016] [debug] 200 OK (0.013645s, 73.287/s)
{% endhighlight %}

It works! As you can see, there are two logs line from the `minion.1` app component that say:

{% highlight text %}
[...] [debug] Performing job "1" with task "poke_mojo" in process 143
[...] [debug] We have poked mojolicious.org for a visitor
{% endhighlight %}

which tell us that the `minion` received the task and executed it.

It's instructive at this point to take a look at the directory that was
created as `/var/lib/dokku/data/storage/sample-mojo`; we will need to
impersonate `root` on the [Dokku][] node this time:

{% highlight text %}
$ ssh "root@$DOKKU_IP" ls -l /var/lib/dokku/data/storage
total 8
drwxr-xr-x 2 32767 32767 4096 Oct  8 21:53 sample-mojo
{% endhighlight %}

What's this thing with user and group ids `32767`? Simple: when [Docker][]
is instructed to run containers by [Dokku][], it is told to start them as
these user and group id. They are *different enough* from what you have in
the machine (the highest user id is `dokku`'s at `1000`, the highest group
id is still `dokku`'s at `1000` except for a few service group ids that
are at `65534`, so still very *distant* from `32767`) so that you can be
reasonably sure there will be no clash or overlapping *by chance*.

## Backing Services

As we saw in a previous [section](#then-we-think-were-ready-but), each
service instance runs inside its own container and is quite isolated from the
other ones, even though they actually run on the same node. That's what makes
[Dokku][] powerful: it allows you to run multiple services, which might each
have their own quirk about filesystem, configurations, running processes,
library versions and so on, but still guarantee that they will play nicely in
the same host.

One of the consequences is that you have to take explicit actions to have
them share files/directories: in our case, we wanted the `web` and
`minion` services to share a common directory where they would be able to
operate on the same `SQLite` file. We were lucky that there is the storage
management to help us with this.

What if we want to connect services *differently*? For example, we might
need to use a different database technology, and choose [PostgreSQL][]
instead. [Heroku][] and [Dokku][] can get you covered for a lot of
technologies, and lucky for us there's the [Postgres][] plugin that will
help us right out of the box.

The initial [Dokku tutorial][] help us here, so we will just take the
relevant command without too many comments. First, we take care to see
whether the plugin is really installed or not:

{% highlight text %}
$ dokku help
Usage: dokku [--quiet|...

Primary help options, ...

Commands:

    apps             L...
    certs            M...
    ...

Community plugin commands:

    letsencrypt <app> ...
    ...
    postgres          ...
    redis             ...
{% endhighlight %}

Fine, we do have plugins for [Let's Encrypt][Let's Encrypt plugin],
[Redis] and [Postgres], listed in the `Community plugin commands` section.

These services provided out of the box are called *backing services*;
there are quite a number of them (e.g. [see the official ones][Official
Dokku plugins]) and they should get you covered in most situations.

Let's define one backing service for our application then, by first
creating it and then linking to our application:

{% highlight text %}
$ dokku postgres:create sample-mojo-pg
       Waiting for container to be ready
       Creating container database
       Securing connection to database
=====> Postgres container created: sample-mojo-db
=====> Container Information
       Config dir:          /var/lib/dokku/services/postgres/sample-mojo-db/config
       Data dir:            /var/lib/dokku/services/postgres/sample-mojo-db/data
       Dsn:                 postgres://postgres:1b8c1fb63db2cbee3c407c8fd815152a@dokku-po...
       Exposed ports:       -                        
       Id:                  ecaf7be1f12cc146da63c2da1b4f9c737e26ccce6f3aef27d7af302feb1d674d
       Internal ip:         172.17.0.5               
       Links:               -                        
       Service root:        /var/lib/dokku/services/postgres/sample-mojo-db
       Status:              running
       Version:             postgres:9.5.4

$ dokku postgres:link sample-mojo-pg sample-mojo
-----> Setting config vars
       DATABASE_URL: postgres://postgres:1b8c1fb63db2cbee3c407c8fd815152a@dokku-postgres-...
-----> Restarting app sample-mojo
... other lines about application restart..
{% endhighlight %}

As we can see, the plugin took care to set the environment variable
`DATABASE_URL` in our application to the right value for consumption by
the application itself. We can now use it in our code then, so the
`app.pl` file is modified as follows:

{% highlight perl %}
#!/usr/bin/env perl
use Mojolicious::Lite;

my $dsn = $ENV{DATABASE_URL} || 'sqlite:/app/shared/test.db';
my $type = ($dsn =~ m{^postgres:}mxs) ? 'Pg' : 'SQLite';
plugin Minion => {$type => $dsn};

# Slow task
app->minion->add_task(poke_mojo => sub {
 my $job = shift;
 $job->app->ua->get('mojolicious.org');
 $job->app->log->debug('We have poked mojolicious.org for a visitor');
});

# Perform job in a background worker process
get '/' => sub {
 my $c = shift;
 $c->minion->enqueue('poke_mojo');
 $c->render(text => 'We will poke mojolicious.org for you soon.');
};

app->start;
{% endhighlight %}

This will make sure that we can continue to use [SQLite][] locally and
[PostgreSQL][] remotely (even though you should strive to have perfect
alignment across all your deployment environments!).

We just have to make sure that our Perl application will be able to use
[PostgreSQL][] now, so the `cpanfile` becomes as follows:

{% highlight perl %}
requires 'Mojolicious', '7.08';
requires 'Minion', '6.0';
requires 'Minion::Backend::SQLite', '0.007';
requires 'Mojo::Pg', '2.30';
{% endhighlight %}

Commit, then push:

{% highlight text %}
$ git commit -am 'Add support for PostgreSQL backing service'
[master 4ad17b9] Add support for PostgreSQL backing service
 2 files changed, 4 insertions(+), 1 deletion(-)

$ git push
Counting objects: 7, done.
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 578 bytes, done.
Total 4 (delta 2), reused 0 (delta 0)
-----> Cleaning up...
-----> Building sample-mojo from herokuish...
-----> Adding BUILD_ENV to build environment...
-----> Multipack app detected
=====> Downloading Buildpack: https://github.com/polettix/heroku-buildpack-perl-procfile.git
=====> Detected Framework: Perl/Procfile
-----> Installing dependencies
       Successfully installed DBD-Pg-3.5.3
       Successfully installed Mojo-Pg-2.30
       2 distributions installed
... all good up to now...
remote: App container failed to start!!
=====> sample-mojo web container output:
       Invalid PostgreSQL connection string "postgres://postgres:1b8c1fb63db2...
... last message repeated a few times...
 ! [remote rejected] master -> master (pre-receive hook declined) error:
 failed to push some refs to ...
{% endhighlight %}

Ouch! Well, I think [Mark Jason Dominus][] got it right at this point:

![You can't just make...](http://perl.plover.com/pics/jc8.gif)

Simply put, the `DATABASE_URL` environment variable will need some
adaptation before we can use it, right? This error at least told us one
thing though: the application we are trying to deploy is *actually*
attempting to use the [PostgreSQL][] database backing service after all!

It turns out that we just have to force the URL scheme to `postgresql`
(with the final `ql` part):

{% highlight perl %}
#!/usr/bin/env perl
use Mojolicious::Lite;

my $dsn = $ENV{DATABASE_URL} || 'sqlite:/app/shared/test.db';
$dsn =~ s{^postgres.*?:}{postgresql:}mxs;
my $type = ($dsn =~ m{^postgresql:}mxs) ? 'Pg' : 'SQLite';
plugin Minion => {$type => $dsn};

# Slow task
app->minion->add_task(poke_mojo => sub {
 my $job = shift;
 $job->app->ua->get('mojolicious.org');
 $job->app->log->debug('We have poked mojolicious.org for a visitor');
});

# Perform job in a background worker process
get '/' => sub {
 my $c = shift;
 $c->minion->enqueue('poke_mojo');
 $c->render(text => 'We will poke mojolicious.org for you soon.');
};

app->start;
{% endhighlight %}

>As of release `2.31` of [Mojo::Pg] this should not be necessary any more,
>although it's still not out as of `2016-10-16`. See [Updates](#updates)
>for details.

Again, commit, push and check:

{% highlight text %}
$ git commit -am 'Adapt DATABASE_URL to Mojo::Pg URL scheme'
[master c7f2d50] Adapt DATABASE_URL to Mojo::Pg URL scheme
 1 file changed, 2 insertions(+), 1 deletion(-)

poletti@Polebian2:sm (master)$ git push
...
=====> Application deployed:
       http://sample-mojo.example.com
...

# deployment was fine, let's send a GET
$ curl http://sample-mojo.example.com
We will poke mojolicious.org for you soon.

# take some time
$ sleep 5

# check logs
$ dokku logs sample-mojo
... app[minion.1]:... Worker 8 started
... app[minion.1]:... Checking worker registry and job queue
... app[minion.1]:... Performing job "1" with task "poke_mojo" in process 145
... app[minion.1]:... We have poked mojolicious.org for a visitor
...
{% endhighlight %}

The fact that it's performing job `1` again is another hint that it is
actually using [PostgreSQL][], because the jobs numbering was restarted.
Anyway, we don't need the persistent storage any more at this time, so we
can double check by just removing it:

{% highlight text %}
$ dokku storage:list sample-mojo
sample-mojo volume bind-mounts:
     /var/lib/dokku/data/storage/sample-mojo:/app/shared

$ dokku storage:unmount sample-mojo /var/lib/dokku/data/storage/sample-mojo:/app/shared

$ dokku storage:list sample-mojo
sample-mojo volume bind-mounts:

$ dokku ps:restart sample-mojo
... usual stuff here...

$ curl http://sample-mojo.example.com
We will poke mojolicious.org for you soon.

# take some time
$ sleep 5

# check logs
$ dokku logs sample-mojo
... app[minion.1]:... Worker 7 started
... app[minion.1]:... Checking worker registry and job queue
... app[minion.1]:... Performing job "2" with task "poke_mojo" in process 145
... app[minion.1]:... We have poked mojolicious.org for a visitor
...
{% endhighlight %}

YAY, it's still working indeed!

## Encryption Anyone?

Up to this point, all our traffic has been left into the wilderness of
plain text. If you think that encrypting communications can be a good
thing, though, you probably already started wondering how to add TLS to
the lot.

[Dokku][] provides you means for managing certificates via the `certs`
group of commands:

{% highlight text %}
$ dokku certs:help
Usage: dokku certs:COMMAND

Manage Dokku apps SSL (TLS) certs.

Additional commands:
    certs:add <app> CRT KEY             Add an ssl endpoint to an app. Can also import from a tarball on stdin
    certs:chain CRT [CRT ...]           [NOT IMPLEMENTED] Print the ordered and complete chain for the given certificate
    certs:generate <app> DOMAIN         Generate a key and certificate signing request (and self-signed certificate)
    certs:info <app>                    Show certificate information for an ssl endpoint
    certs:key <app> CRT KEY [KEY ...]   [NOT IMPLEMENTED] Print the correct key for the given certificate
    certs                               Manage Dokku apps SSL (TLS) certs
    certs:remove <app>                  Remove an SSL Endpoint from an app
    certs:rollback <app>                [NOT IMPLEMENTED] Rollback an SSL Endpoint for an app
    certs:update <app> CRT KEY          Update an SSL Endpoint on an app. Can also import from a tarball on stdin
{% endhighlight %}

This is definitely the way to go if you are using a domain where you can't
define a wildcard resolution or it's not immediately below a [public
suffix][], or more simply you want to use your homebrewn self-signed
certificates (which is perfectly secure if you have full control on all
clients, of course!).

If you instead:

- have control over your domain DNS configurations
- the domain is immediately below a [public suffix][]

then you can enjoy the services of the [Let's Encrypt plugin][]. Let's see how.

The only real setup you have to do is define an email address; this is
used by [Let's Encrypt][] to notify you about certificates that are about
to expire (this will be our safenet, because we can setup the plugin to
renew the certificates automatically). Then you just have to activate the
plugin.

If you're lazy like me, you can set the email address up as a global
variable, so that every project will use the same. You can still override
this on a per-project basis, anyway.

{% highlight text %}
$ dokku config:set --global DOKKU_LETSENCRYPT_EMAIL=you@example.com
-----> Setting config vars
       DOKKU_LETSENCRYPT_EMAIL: you@example.com
{% endhighlight %}

Then, you just have to activate the plugin for your app:

{% highlight text %}
$ dokku letsencrypt sample-mojo
=====> Let's Encrypt sample-mojo
-----> Updating letsencrypt docker image...
latest: Pulling from dokkupaas/letsencrypt-simp_le
420890c9e918: Already exists
e4a2ae244258: Already exists
5c6ac6d1c950: Already exists
Digest: sha256:18a19b34beceba79dd5be458abe7e132fc7486da1da19cc4d0395ad4578031ef
Status: Image is up to date for dokkupaas/letsencrypt-simp_le:latest
       done updating
-----> Enabling ACME proxy for sample-mojo...
-----> Getting letsencrypt certificate for sample-mojo...
        - Domain 'sample-mojo.example.com'
darkhttpd/1.11, copyright (c) 2003-2015 Emil Mikulic.
listening on: http://0.0.0.0:80/
2016-10-09 07:05:42,620:INFO:__main__:1211: Generating new account key
2016-10-09 07:05:44,514:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:44,762:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:45,019:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:46,032:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): letsencrypt.org
2016-10-09 07:05:46,762:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:47,015:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:47,283:INFO:requests.packages.urllib3.connectionpool:207: Starting new HTTP connection (1): sample-mojo.example.com
2016-10-09 07:05:47,359:INFO:__main__:1305: sample-mojo.example.com was successfully self-verified
2016-10-09 07:05:47,381:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:47,749:INFO:__main__:1313: Generating new certificate private key
2016-10-09 07:05:48,211:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:52,438:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:52,693:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:53,007:INFO:requests.packages.urllib3.connectionpool:758: Starting new HTTPS connection (1): acme-v01.api.letsencrypt.org
2016-10-09 07:05:53,260:INFO:__main__:391: Saving account_key.json
2016-10-09 07:05:53,261:INFO:__main__:391: Saving fullchain.pem
2016-10-09 07:05:53,262:INFO:__main__:391: Saving chain.pem
2016-10-09 07:05:53,262:INFO:__main__:391: Saving cert.pem
2016-10-09 07:05:53,263:INFO:__main__:391: Saving key.pem
-----> Certificate retrieved successfully.
-----> Installing let's encrypt certificates
-----> Unsetting sample-mojo
-----> Unsetting DOKKU_NGINX_PORT
-----> Setting config vars
       DOKKU_PROXY_PORT_MAP: http:80:5000
-----> Setting config vars
       DOKKU_PROXY_PORT_MAP: http:80:5000 https:443:5000
-----> Setting config vars
       DOKKU_NGINX_PORT: 80
-----> Setting config vars
       DOKKU_NGINX_SSL_PORT: 443
-----> Configuring sample-mojo.example.com...(using built-in template)
-----> Creating https nginx.conf
-----> Running nginx-pre-reload
       Reloading nginx
-----> Configuring sample-mojo.example.com...(using built-in template)
-----> Creating https nginx.conf
-----> Running nginx-pre-reload
       Reloading nginx
-----> Disabling ACME proxy for sample-mojo...
       done
{% endhighlight %}

So, after a bunch of back and forth with [Let's Encrypt][], the plugin
took care to reconfigure the reverse proxy to:

- redirect all traffic from port `80` to port `443`
- accept traffic on port `443`

Let's see the redirection part:

{% highlight text %}
$ curl -v http://sample-mojo.example.com/
* About to connect() to sample-mojo.example.com port 80 (#0)
...
> GET / HTTP/1.1
> User-Agent: curl/7.26.0
> Host: sample-mojo.example.com
> Accept: */*
> 
...
< HTTP/1.1 301 Moved Permanently
< Server: nginx
< Date: Sun, 09 Oct 2016 07:09:55 GMT
< Content-Type: text/html
< Content-Length: 178
< Connection: keep-alive
< Location: https://sample-mojo.example.com:443/
...
{% endhighlight %}

Let's follow the redirection now, note that `curl` does not complain at
all about the certificate:

{% highlight text %}
$ curl -L http://sample-mojo.example.com/
We will poke mojolicious.org for you soon.
{% endhighlight %}

Last thing we want to do is to set up automatic renewal of the
certificates for all applications, because they expire every `90` days
(this short time is to encourage automation):

{% highlight text %}
$ dokku letsencrypt:cron-job --add
-----> Added cron job to dokku's crontab.
no crontab for dokku
{% endhighlight %}

Done! Don't worry about the last line, it appears if our [Dokku][]
instance is brand new and no previous `crontab` setting was present for
user `dokku`.

## Summing Up

After this (admittedly) long journey, we got to this point:

- we have a [Dokku][] node where we can easily deploy our applications - the
  Perler, the better in my opinion, but you're not necessarily limited to it;
- we know how to share a directory across different components of an
  application
- we know how to connect to backing services, like a [PostgreSQL][] database
  for example
- we secured our application web frontend communications via TLS

This is probably something that should get you more than started! For going
beyond, you should definitely check the excellent documentation in [Dokku][]'s
website.

Have fun!

## Updates

- `2016-10-09` a change for supporting the `postgres://` url scheme in
  addition to `postgresql://` is on its way (see [this
  commit][pg-commit]). This makes using environment variable
  `DATABASE_URL` a breeze (see [Backing Services](#backing-services)) as
  it will be immediately consumable by [Mojo::Pg][Mojo::Pg] and the
  associated [Minion][] backend, YAY! (We will have to wait for the new release
  of [Mojo::Pg] though!).
- `2016-10-16` most of the stuff in this article has been compressed in a
  cheatsheet available in this [wiki][]. Nice thing about [GitLab][] is that
  it's possible to also whip up a few [snippets][].
- `2016-10-16` added a [Table of Contents](#table-of-contents) for better
  navigation of the document.
- `2016-12-23` added note on Debian 8 in [Vultr][].
- `2017-09-16` fixed a few missing links and typos.


[PaaS]: https://en.wikipedia.org/wiki/Platform_as_a_service
[Dokku]: http://dokku.viewdocs.io/dokku/
[Heroku]: https://www.heroku.com/
[Digital Ocean]: https://www.digitalocean.com/
[dokku-boot]: https://github.com/polettix/dokku-boot
[Let's Encrypt]: https://letsencrypt.org/
[Let's Encrypt plugin]: https://github.com/dokku/dokku-letsencrypt
[Redis]: https://github.com/dokku/dokku-redis
[Postgres]: https://github.com/dokku/dokku-postgres
[Mojolicious]: https://metacpan.org/pod/Mojolicious
[sample-mojo]: https://github.com/polettix/sample-mojo
[git]: https://git-scm.com/
[cpanm]: https://github.com/miyagawa/cpanminus
[carton]: https://github.com/perl-carton/carton
[public suffix]: https://publicsuffix.org/
[ClouDNS]: https://www.cloudns.net/
[cloudns-domains-pricing]: https://www.cloudns.net/domain-pricing-list/
[heroku-buildpack-perl-procfile]: https://github.com/polettix/heroku-buildpack-perl-procfile
[Perl]: http://www.perl.org/ [CPAN]: http://metacpan.org
[khbpp]: https://github.com/kazeburo/heroku-buildpack-perl-procfile
[kazeburo]: https://github.com/kazeburo
[custom buildpacks]: https://github.com/dokku/dokku/blob/master/docs/deployment/methods/buildpacks.md
[nginx]: https://nginx.org/
[Minion]: https://metacpan.org/pod/Minion
[minion-description]: https://metacpan.org/pod/Minion#DESCRIPTION
[Docker]: http://docker.io/
[SQLite]: https://www.sqlite.org/
[PostgreSQL]: https://www.postgresql.org/
[Dokku tutorial]: http://dokku.viewdocs.io/dokku/deployment/application-deployment/
[Official Dokku plugins]: http://dokku.viewdocs.io/dokku/community/plugins/#official-plugins-beta
[Mark Jason Dominus]: http://blog.plover.com/
[wiki]: https://gitlab.com/polettix/dokku-notes/wikis/Cheatsheet
[snippets]: https://gitlab.com/polettix/dokku-notes/snippets
[GitLab]: https://gitlab.com/
[pg-commit]: https://github.com/kraih/mojo-pg/commit/4414d784b7e22a4b4eca7657e91a6eec25ce923c
[Mojo::Pg]: https://metacpan.org/pod/Mojo::Pg
[Vultr]: https://www.vultr.com/
[CPAN]: https://www.metacpan.org/
[Starman]: https://github.com/miyagawa/Starman
