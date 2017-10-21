---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Setup a Taskwarrior server
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

Do you use [Taskwarrior][] and want to setup a private remote server for
backing stuff up and sync across multiple devices? Here's a few notes
you might find interesting.

## Table of Contents

- TOC
{:toc}

## What will we talk about?

First of all, the [Taskwarrior][] site has comprehensive instructions on
[how to setup your own sync server][taskd-setup]. Take it as a good
starting point, it will actually work quite well if you are doing all on
your own.

In the following sections, we will begin with a brief introduction to
the concepts related to setting up the security part of the Taskserver.
This is by far the most tricky part of the setup, and the one more
likely to make you angry.

If you're in a hurry, you can skip the following section about securing
the communications, and jump directly to the configuration parts. Enjoy!


## Securing The Communications

[Taskwarrior][] allows you to setup encrypted communications between
client and server, and rightly so. This is done using a protocol called
[Transport Layer Security][TLS] (or TLS), which requires you to use
*keys*, *certificates*, *certification authorities* and *certificate
revocation lists*.

Sounds complicated? It is! We will not get into the details but just
look at the core concepts that matter in configuring Taskwarrior (see
[Information security][] for additional resources).

When you care about security in syncing your local changes to a remote
server, the immediate issue you are probably worried with is
*confidentiality*, i.e.: how do I make sure that nobody else is able to
understand what me and the server are saying?

Another aspect you should care about is whether the system you're
syncing with is actually what it claims to be, and not something set up
to appear so. If you have confidentiality, but you're telling your
secrets to the wrong system... that's not very secure, is it? This works
also the other way around, of course: they system accepting sync
requests has to be sure that you are who you claim to be, otherwise
others might impersonate you and mess with your data.

For both aspects (there are more, of course) maths come to the rescue.
In particular, *encryption* can give you confidentiality, while *digital
signatures* can give you reasonable proof of someone's identity.

### Keys

At the core of both are techniques that go under the umbrella of
asymmetric cryptography. Asymmetric means that for security reasons each
subject has two keys, one called *private* that has to be kept secret at
all times, and one *public* that can be distributed freely. They act as
keys where one can open whatever the other is capable of closing, so
they always come as a *key pair*.

For example, if you want to send a message (think of it like "closing
the message in a box") you use the recipient's public key to do that,
and be sure that only the recipient will be able to read it using the
private key. This is encryption.

On the other hand, if you want proof that the peer has the private key
corresponding to the public key you already have, you tell them to lock
a message you invent on the spot inside a box, and use their public key
to open the box: it will work only if the two keys form a *pair*. This
is signing, or putting a *signature*.

### Certificates

At this point you might be thinking that this whole construction works
only as long as you actually *trust* that the public key you have
actually comes from the right source. The best way to ensure this is to
get this public key in some way that you trust, like e.g. meet the
person and get the key from a USB pen, or ask them to spell it on the
phone. Whatever makes you feel good for your level of secrecy.

While theoretically correct, this method has the non-trivial flaw of
being completely impractical for today's Internet size. This would mean
going to your bank and taking the key, going to Google's and take their
key, then Facebook, Twitter, and whatever service you use that leverages
TLS. This is where *certificates* come into play.

A certificate is basically a public key with some information attached,
in particular with the identity of the owner of that public key, in the
form of a *Common Name* (abbreviated CN), which is basically a domain
name owned by the organization (like `www.example.com`). It's like you
had a key and put a label on it saying that this key is owned by the
same people that run `www.example.com`.

### Certification Authorities

Of course everybody would be able to put a label about `www.example.com`
on *their own* public key, so we're the catch? In addition to containing
a public key and a CN, a certificate also contains a *signature* by
a third party called the *Certification Authority* (abbreviated CA). So
the certificate says: this public key is owned by the people that also
own this CN, and this is guaranteed by the CA. At this point, of course,
you must have the CA certificate to verify that their signature is valid
(because the CA certificate will contain their public key and their
identity!).

This shifts your trust from the people that run the CN to the people
that run the CA. While it may seem that this didn't improve things too
much (you still have to figure out how to trust the CA people!), this
actually makes things easier for you, because the same CA can emit
certificates for a lot of CNs. Hence, instead of going to everyone's and
get their public key, you just go to the CA and get theirs: this will
make sure that all the certificate they signed actually come from the
CNs written in the certificates.

#### A chain of CAs

This same process might apply to CAs too. A little CA might ask a bigger
one to sign its certificate to declare that they are entitled to sign
certificates, and so on. Hence, when some web site sends you their
certificate, they might also send you a *chain of intermediate CA
certificates* where each certificate is about the CA that signed the
certificate immediately before, up to the last that is signed by some
well-known CA.

At this point you might ask: "Hey! I didn't ever go to any *well known*
CA to get this *rule-them-all* CA certificate!". Right, you didn't. But
most browsers come with a bunch of pre-recorded certificates of well
known CAs, so here's how you got them behind the scenes. Now you should
ask yourself if you really trust your browser, shouldn't you?

There are quite some CAs out there, from the most famous like
[Comodo][], [Symantec][] and [GoDaddy][], to minor ones. The most famous
are those whose certificates get installed in browsers and TLS libraries
by default. They have a non-trivial work to do, because they have to
keep their private keys very private (if someone stole them, they could
be used to issue false certificates!) and they also have to make sure
that people asking a certificate for a CN actually *own* that CN (i.e.
they have *to go there* instead of you). This is why certificates
usually come with a cost, which varies depending on the level of trust
that they provide (bank's certificates undergo a much deeper scrutiny
with respect to some casual user's home page), and this is also why
browsers can show a simple lock for lesser certificates up to a full
green indication for the most trusted ones.

#### Which CA for Taskwarrior?

Back to Taskwarrior, if you don't want to shell out money for setting up
your own sync server, you have a couple of alternatives:

- you can set up your fake CA and sign your own certificates. In
  a private context this makes absolutely sense, because you are sure to
  trust everyone involved... unless you suffer from multiple
  personalities and you are not sure about a couple of them!
- if you have a real domain hosted somewhere, you can get certificates
  for free in a few places, one of which is [Let's Encrypt][]. They will
  issue you *real* certificates, although they are an intermediate CA so
  they will also provide their own certificate that is signed by
  a bigger well-known company.
  
Which way should you go? In a private or very controlled environment,
you can definitely go with the first option. The instructions you find
in [Taskwarrior][]'s [instructions page][taskd-setup] actually assume
that this is they way you are going to take. This will require a bit
more complicated procedure on the client side, because you will have to
take care that the client actually trusts the fake CA you set up (but
you have the certificate for this fake CA, so you're going to be fine).

On the other hand, if you plan to give access to a wider audience, your
best chance is probably to go for a certificate issued by a *real* CA,
like Let's Encrypt. Which one you choose depends on which guarantees you
want to have about the CA: the higher you need, the more you will have
to spend on it.

### What about clients?

Up to now, we discussed how can your client be sure about the server
(which might be a web server, or a `taskd` installed somewhere). For the
web, this is most of the times all that you need.

In the case of [Taskwarrior][] this is not all, though. Put yourself
into `taskd`'s shoes: should it blindly accept all updates that claim to
come from you as valid? What if someone else tries to sync updated
pretenting to be you, and mess up with your precious activities?

The same story we saw above with *key pairs* and *certificates* applies
to clients as well. So, you can generate a pair of key, set the private
one in the client and keep the public one in the server, inside
a certificate that tells who you are.

### Expiration and Certificate Revocation List

One last thing to keep in mind is that certificates are usually issued
with an expiration date. The more time passes, the more the public key
can be subject to an attack to try to figure out the associated private
key, for example; or the more you might have leaked your private key.
So, although it's a hassle to take care of renewing your keys and
certificates, this is actually a safety measure.

In addition to expiration, you might want to invalidate certificates
ahead of time. This might e.g. happen if you discover that the private
key was leaked somehow. For this reason. so-called *Certificate
Revocation Lists* (abbreviated CRL) can help you track certificates that
aren't trusted anymore, even if they have a valid signature and have not
expired yet.

The CRL is usually kept by the CA, because it's the entity that
guarantees about the validity of the certificates it signs.

### Summary

After this long digression, we come to the following summary
conclusions:

- there are three types of entities involved in this whole TLS story:
    - users
    - servers
    - CAs
- there are three basic kind of artifacts that we have to take care of:
    - private keys, which we will simply call *key*s in the following;
    - (public) *certificate*s
    - (public) *certificate revocation list*s

Each entity involved (users, servers, CAs) will have the first two kind
of artifact (a key and a certificate), while CAs will also have a CRL.
So, you will have to deal with the following artifacts:

- *user key* and *user certificate*
- *server key* and *server certificate*
- *CA key*, *CA certificate* and *CA CRL*.

It helps to remember that they are all data that is saved into files,
although there might be a many-to-one relation (e.g. a file containing
certificates might contain a server certificate, followed by a chain of
CA certificates up to one signed by a well-known CA).


## Setup Remote Sync

Before starting, we will assume that:

- you have some degree of control over a domain. It must not necessarily
  be a *real* one, i.e. visible from the outside or registered in
  official DNSs; it suffices that you can somehow control the resolution
  process in clients so that that particular domain points to the IP
  Address of the Taskserver you set up. In this example, we will call
  this domain `taskd.example.com`, although we will also assume that it
  is stored in environment variable `DOMAIN`;
- you will use the port stored in the environment variable `PORT`, which
  you already ensured that will be available elsewhere (e.g. you opened
  the right ports in the firewall, etc.). Just for you to know, it's
  customary to set the port to `53589`;
- your Taskserver software is already installed and ready to be started,
  only missing the right configuration for security. We will assume it
  is stored in a directory whose path is stored in environment variable
  `TWSERVER`;
- your Taskwarrior software in the client is already installed and
  working. We will assume that its base directory's path is stored in
  environment variable `TWCLIENT`.

### User accounts

Whatever the way you choose to configure keys, certificates etc. you
will need to enable your user(s) for syncing their tasks, ensuring that
they will not trump onto each other.

Users can be grouped in *organizations*. To create an organization you
can issue the following command *on the server*:

{% highlight bash %}
taskd add org name-of-your-org
{% endhighlight %}

where `name-of-your-org` can be whatever you choose to call your
organization. Suggestion: use letters, numbers, underscores and hyphens
only. If you plan to keep things simple (all users inside the same
organization) this is the only time you will need to issue this command.

After this, for each user you want to create you have to run the
following command, still on the server:

{% highlight bash %}
taskd add user name-of-your-org 'Name O. User'
{% endhighlight %}

You will get back something like this:

{% highlight text %}
New user key: cf31f287-ee9e-43a8-843e-e8bbd5de4294
Created user 'Name O. User' for organization 'name-of-your-org'
{% endhighlight %}

where the key will be different (each user will get its own unique key).

In the following, we will assume that environment variables
`ORGANIZATION`, `USER_NAME` and `USER_KEY` contain... what you think
that they should contain. In our example, they contain respectively
the strings `name-of-your-org`, `Name O. User` and
`cf31f287-ee9e-43a8-843e-e8bbd5de4294`.

### Alternative 1: DIY

If your setup is sufficiently restricted and you have good control over
your clients, you can go the *do it yourself* way and be the CA of
yourself. This is also the easiest thing to do with what ships with
[Taskwarrior][] by default, because there are scripts that allow you to
do exactly this.

All the heavy lifting is done within a directory named `pki`. Depending
on the distribution/system you use, it might be located in a different
location; we will let you find it and wait patiently here. Just for
a hint, this is what you should find in that directory (this example was
run in Alpine Linux):

{% highlight text %}
/ $ cd /usr/share/taskd/pki/
/usr/share/taskd/pki $ ls -l
total 28
-rw-r--r--    1 root     root          1272 May 10  2015 README
-rwxr-xr-x    1 root     root           664 May 10  2015 generate
-rwxr-xr-x    1 root     root           633 May 10  2015 generate.ca
-rwxr-xr-x    1 root     root           778 May 10  2015 generate.client
-rwxr-xr-x    1 root     root           889 May 10  2015 generate.crl
-rwxr-xr-x    1 root     root           866 May 10  2015 generate.server
-rw-r--r--    1 root     root           138 May 10  2015 vars
{% endhighlight %}

Before running anything, you MUST edit the file `vars`, that initially
appears like this:

{% highlight text %}
BITS=4096
EXPIRATION_DAYS=365
ORGANIZATION="Göteborg Bit Factory"
CN=localhost
COUNTRY=SE
STATE="Västra Götaland"
LOCALITY="Göteborg"
{% endhighlight %}

The only, single important thing that you MUST change is the `CN`
setting (remember the *Common Name*? Well, this is it!). As we are
assuming to operate `taskd.example.com`, this is what we have to setup
here. It does not hurt to change a few of the other parameters of
course, but it's not strictly necessary. This is how we will change it
in this example:

{% highlight text %}
BITS=4096
EXPIRATION_DAYS=365
ORGANIZATION="Yadda Yadda Yadda"
CN=taskd.example.com
COUNTRY=IT
STATE="Lazio"
LOCALITY="Roma"
{% endhighlight %}

It does not hurt to repeat: **change `CN` to your domain**.

Now, you just run the shell script `generate` inside the directory, and
let the magic happen. It boils down to the following four commands (at
least as of release 2.5.1):

{% highlight bash %}
./generate.ca
./generate.server
./generate.crl
./generate.client client
{% endhighlight %}

It should be pretty clear at this point:

- first of all, a *fake* CA is generated. This is us acting as a CA,
  that is not widely recognised but that we can totally trust! This step
  generates files `ca.key.pem` (the CA's private key) and `ca.cert.pem`
  (the public certificate). This certificate is somehow special, because
  it tells two things:
    - first, that it's from a Certification Authority, so it should be
      trusted when used for signing other certificates;
    - second, that it's signed... by the certificate owner itself. This
      is why it's also called a *self-signed certificate*.
- Now that we have a CA, we can sign certificates for other entities,
  i.e. servers and clients. The second step takes care to generate the
  server's key pair, saving the private key in `server.key.pem` and
  generating a certificate that includes the public key in
  `server.cert.pem`. *This is where the details in file `vars` are
  used*.
- The third step generates a Certificate Revocation List. This is
  probably overkill for a small setup, but it does not hurt to have one
  anyway. The step generates the file `server.crl.pem`.
- The fourth step generates a (private) key and a certificate for
  a client, so that it will be able to demonstrate its identity back to
  the server. This step generates `client.key.pem` and
  `client.cert.pem`.

One interesting thing is that the CA we created in the first step has
a double role here, because it signs the certificates for both the
server and the clients. This is not the most generic setup that you can
have, as we will see below; for the moment, we will stick with it.

This is a summary of the generated files and where you should put them:

{% highlight text %}
SERVER                          CLIENT
---------------------------     ---------------------------
"$TWSERVER"/server.key.pem      "$TWCLIENT"/client.key.pem
"$TWSERVER"/server.cert.pem     "$TWCLIENT"/client.cert.pem
"$TWSERVER"/server.crl.pem      "$TWCLIENT"/ca.cert.pem
"$TWSERVER"/ca.cert.pem
{% endhighlight %}

To be completely right, you should also ensure to keep `ca.key.pem`
somewhere, because it will be needed to regenerate the `server.crl.pem`
file in case of need.



#### Server configuration

Now you only have to do the configurations. On the server you have to
setup the files we generated and moved into the right location, plus
where the daemon should be listening (we will copy also a couple of
additional configurations while we are at it):

{% highlight text %}
taskd config --force -- server      "$DOMAIN:$PORT"
taskd config --force -- log         "$TWSERVER"/taskd.log
taskd config --force -- pid.file    "$TWSERVER"/taskd.pid
taskd config --force -- server.key  "$TWSERVER"/server.key.pem
taskd config --force -- server.cert "$TWSERVER"/server.cert.pem
taskd config --force -- server.crl  "$TWSERVER"/server.crl.pem
taskd config --force -- ca.cert     "$TWSERVER"/ca.cert.pem
{% endhighlight %}

#### Client configuration

Configuration on the client involves the following items:

- tell the client where the server for synchronization is;
- make sure we will accept the server's certificate. As this is signed
  by our fake CA, we have to make sure that the TLS library will accept
  it by loading the fake CA certificate at the right time;
- set the trust model to the `strict`est mode, because we care about
  security (otherwise, you wouldn't be reading this!)
- tell the client about our own user identifier and the organization we
  will save our data within;
- set the client key and certificate so that it will be able to provide
  them when requested by the server.

This is what we can do then:

{% highlight text %}
task config --force -- taskd.server      "$DOMAIN:$PORT"
task config --force -- taskd.ca          "$TWCLIENT"/ca.cert.pem
task config --force -- taskd.trust       strict
task config --force -- taskd.credentials "$ORGANIZATION/$USER_NAME/$USER_KEY"
task config --force -- taskd.key         "$TWCLIENT"/client.key.pem
task config --force -- taskd.certificate "$TWCLIENT"/client.cert.pem
{% endhighlight %}

Done!


### Alternative 2: *Real* certificate

First thing to do: just do Alternative 1 and start from there. It's
really not much different and you don't really want to read it again.

Done? OK, now let's move on.

One thing to keep in mind is that with real certificates there are two
CAs that come into play:

- the CA that signs your server certificate, and
- the CA that signs your clients' certificates.

In the previous example, we used the same CA for both, but in this case
the first one is outside of our control (unless you *are* the people
behind some well-known CA, of course!) while the second one most
probably will remain ours. Why? Well, those certificates are needed to
ensure that the people that ask to connect actually were allowed by us,
so it's quite reasonable that we do still provide them without asking
those people to pay for a certificate.

To start with, just repeat whatever was described in Alternative
1 above. We will be using probably a different key and surely
a different certificate for the server, but all the rest remains exactly
as described so it's worth to just repeat the steps.

In this example, we will assume that you get your certificate with [Let's
Encrypt][]. It's a bit of work to set it up, but after that you can
automate the renewal of the certificate (as a matter of fact, this
automation is encouraged) and forget about it in some crontab line.

Now go get your certificate for your domain. We will wait here until
you're done.

Really.

At the end you will end up with the same files as in the previous
section, with the addition of a `domain.key` and a `domain.crt` file
that come from the setup for [Let's Encrypt][]. It's worth to remember that
you MUST NEVER send your `domain.key` to anyone, including [Let's
Encrypt][]!

#### Server configuration

On the server side, all you have to do is copy `domain.key` over
`server.key.pem` and `domain.crt` over `server.cert.pem`, then restart
`taskd` if it was running using the previous certificates.

This is really all that you need to do on the server side. The CA
certificate *in the server* does not change, because this is the
certificate for the CA that generates the clients' certificates, not the
server's.

#### Client configuration

*Theoretically*, on the client side you should not need to do
*anything*. This is because the certificate file you get from [Let's
Encrypt][] should already contain two certificates inside, one for your
server followed by one for the CA of [Let's Encrypt][] (this latter
signed by a well-known CA, of course). Clients are able to follow the
chain of certificates in a file they receive, automatically.

Anyway, as of version 2.5.1 you will discover that this does not really
work out of the box. Why is this? Well, it's because the code does not
load the well-known certificates, so the client follows the chain of
certificates (correct) but it eventually lands on a CA that it does not
know of, despite it's a well-known one. This will be probably corrected
in some future release (although most probably it will work only for
clients compiled against a version of the library GnuTLS that is at
least 3.0.20).

So are we out of luck? Not really. After completing the configuration
like in the Alternative 1 above, all we have to do is to get the last
(CA) certificate from the new server certificate, and save it inside
file `$TWCLIENT/ca.cert.pem` **in the client**.

It's easy to extract the certificate, just look for the last section in
the file that is included between clear `BEGIN CERTIFICATE` and `END
CERTIFICATE` markers:

{% highlight text %}
-----BEGIN CERTIFICATE-----
MIIGNTCCBR2gAwIBAgISAyzjWXqpc+Xbd... \
.................................... | THIS IS THE SERVER CERTIFICATE
pOlsXXuFidxtdN6ey7iA+SgLE+ZEZWfC9... /
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEkjCCA3qgAwIBAgIQCgFBQgAAAVOFc... \
.................................... | THIS IS THE CA CERTIFICATE
+X+Q7UNKEkROb3N6KOqkqm57TH2H3eDJA... /
-----END CERTIFICATE-----
{% endhighlight %}

Now, from the next invocation of `task sync`, the server will send the
new shiny *real* certificate, and the client will not reject it because
it's configured to trust the Let's Encrypt CA. YAY!

### Quick consideration on clients authentication

You might have noticed at this point that there's something going on
with client authentication. This actually happens at two levels:

- at the TLS level, the server asks the client for its client
  certificate;
- at the Taskwarrior level, the server asks the client for the
  organization, the username and the user key (the one generated by
  `taskd`, not the TLS private key!) that acts both as a unique
  identifier for the account AND as a password.

These two authentications are not actually connected together, although
they probably should. In particular, it would be great if the client's
certificate CN included the string we are setting for
`taskd.credentials` in the client.

Anyway, this is not how it works today. So, for any practical reason,
you don't *strictly* need to generate a new TLS key and certificate for
each new user you want to manage... because everyone will just be fine
with the `client.key.pem` and `client.cert.pem` files you generated in
the first place. Which also means: if some of your users figures out the
username and the taskd user key of someone else, they will be able to
sync against them. There's always space for improvement!

## Summing Up

[Taskwarrior][] is really a great and useful piece of code. Being able
to setup your own Taskserver for syncing up all your devices is a very
useful addition too; doing it properly requires some attention but it's
really not difficult as long as you follow the instructions carefully.

Using it with *real* certificates is definitely doable, although the
process can be enhanced to make it even simpler (with less
configurations needed on the client side). Even now it's not really
difficult and just requires one step more than what would be ideal.

The clients authentication process should probably relate user accounts
managed by Taskwarrior to the certificates generated for clients. This
would allow better restriction of access (like "you can access
a specific resource if and only if you know the resources details *and*
you also have the certificate attached to that resource") and also an
effective usage of the Certificate Revocation List. Anyway,
[Taskwarrior] is under active development... and you might be the one to
implement those enhancements!

Until then... happy tasking!



[Taskwarrior]: https://taskwarrior.org/
[taskd-setup]: https://taskwarrior.org/docs/taskserver/setup.html
[Let's Encrypt]: https://letsencrypt.org/
[TLS]: https://en.wikipedia.org/wiki/Transport_Layer_Security
[Information security]: https://en.wikipedia.org/wiki/Information_security
[Comodo]: https://en.wikipedia.org/wiki/Comodo_Group
[Symantec]: https://en.wikipedia.org/wiki/Symantec
[GoDaddy]: https://en.wikipedia.org/wiki/GoDaddy
