---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: BitTorrent for personal file sharing
image:
   feature: yellow-river.jpg
---

I sometimes what to transfer a file from A to B and this file might be big.
Like a Virtual Machine Image around 20 GB.

I discovered that BitTorrent can be quite powerful and robust for the file
transfer, but unfortunately there is not too much information around as to
set up a "personal" file sharing chain.

One of the things that seem to be available are the DHT or *trackerless*
torrents. Well, I did not manage to make one work, so I had to revert to a
more irritating method of setting up a tracker. Here's how... without
using uTorrent, that is not freely available in Linux.

The steps are quite simple:

* set up a Tracker
* generate a torrent file
* start a BitTorrent client where the file to transfer is, using the
  torrent file to load it
* send the torrent file to the recipient and start another BitTorrent
  client with it.

We will see all of them step by step.

## Tools

We will use the *standard* BitTorrent client:

* [tarball] from SourceForge
* [a snapshot of the above][snapshot] taken on February 1st, 2015

[tarball]: http://bittorrent.cvs.sourceforge.net/viewvc/bittorrent/?view=tar
[snapshot]: {{ site.url }}/assets/files/bittorrent-20150201.tar.gz

Unpack the whole thing and get into the BitTorrent directory. We'll call
the directory you are into `$BT`.

## Tracker Set-Up

The tracker is a server program that helps... tracking the download of the
different chunks by the interested clients. It acts as a very minimal web
server that only accepts `GET` requests to a specific URI and with a
specific command line. You will not have to worry about this.

You have to choose a port where your tracker will listen. We will just
select 12345 for our example, so you only have to start the tracker:

{% highlight bash %}
cd "$BT"
port=12345
./bttrack.py --port $port --dfile dfile-$port >"log-$port.log" 2>&1 <<<'' &
{% endhighlight %}

This will start a Tracker in the background, listening on all the
interfaces at the port of your choice. The related URI is the following:
`http://your-server:12345/announce/`.

Of course, we are assuming that the Tracker can be reached through port
12345 of server `your-server`... adjust according to your environment!

## Torrent File Creation

You don't necessarily have a running Tracker to generate the torrent file,
but you will need one anyway... There are only a few really important
things to generate the torrent file: the Tracker's URI and the file to
transfer. The command is pretty straightforward:

{% highlight bash %}
./btmakemetafile.py inputfile.ext http://your-server:12345/announce \
    --target mystuff.torrent
{% endhighlight %}

## BitTorrent Client, *Server*-side

This is quite easy... but with a twist. The client on the server will be
installed in the same host as the tracker, and this is a problem because the
server *normally* relies upon the connection details (IP address) to
figure out where the peer is. In this case, it's highly likely that you would
get some local address! Luckily there's a parameter around this: `--ip`.

{% highlight bash %}
./btdownloadheadless.py --ip $visible_ip --minport 54321 --maxport 54321 \
     "$torrentpath"
{% endhighlight %}

As said, you should set `$visible_ip` to some address of the
serving machine that can be reached by the intended peer.

You will have to start this command from the place where your file is,
otherwise this instance will try to download the relevant file instead of
seeding it.

The `$torrenpath` is supposed to carry the path to the torrent
file generated in the previous step.

As you can see, we also chose to stick to a single port. This is important
later for setting up rules in the firewall.

## BitTorrent Client, *Client*-side

Here comes finally when you can download the torrent from the
destination. All you have to do is to send the torrent file (that is
way more compact!) to the recipient, and tell them to use their favourite
BitTorrent client to download it. Voilà!


## Don't Forget the Firewall!

If you are using some firewall you will have to ensure that the ports
are open. Most probably, the firewall will be iptables, in which case:

{% highlight bash %}
# this is for the Tracker
sudo iptables -A INPUT -p tcp -m tcp --dport 12345 -j ACCEPT

# this is for the Client
sudo iptables -A INPUT -p tcp -m tcp --dport 54321 -j ACCEPT
{% endhighlight %}

## Packing it all

The following script can be executed on the host where you will be
serving the file. You can provide a port for the tracker, or let it
get one for you. It assumes that the following port is free as well,
and assigns it to the client (yes, not *that* robust).

{% highlight bash %}
#!/bin/bash

filename=$1
port=${2:-$(perl -e 'print int(50000 + rand 15000)')}
hostname=${3:-$(hostname)}
ip=${4:-$(dig "$hostname" +short)}
CLIENTPORT=$(($port + 1))
BINDIR=$(dirname "$0")
BINDIR=$(readlink -f "$BINDIR")
BTTRACK="$BINDIR/bttrack.py"
BTCLIENT="$BINDIR/btdownloadheadless.py"
BTTORRENTCREATOR="$BINDIR/btmakemetafile.py"
TORRENTFILE="$(basename "$filename")-$port.torrent"

# Create torrent file
"$BTTORRENTCREATOR" "$filename" "http://$hostname:$port/announce" \
   --target "$TORRENTFILE"
echo "created: $TORRENTFILE"

# Start tracker, save pid for later
"$BTTRACK" --port $port --dfile dfile-$port \
   >"tracker-$port.log" 2>&1 <<<'' &
PID=$!

# Open ports. The client is blocking, so this has to be done before
sudo iptables -A INPUT -p tcp -m tcp --dport $port -j ACCEPT
sudo iptables -A INPUT -p tcp -m tcp --dport $CLIENTPORT -j ACCEPT

# Start client
"$BTCLIENT" --ip "${ip:-$hostname}" \
   --minport $CLIENTPORT \
   --maxport $CLIENTPORT \
   "$TORRENTFILE" >"client-$CLIENTPORT.log" 2>&

# When client is interrupted, clean all up
sudo iptables -D INPUT -p tcp -m tcp --dport $port -j ACCEPT
sudo iptables -D INPUT -p tcp -m tcp --dport $CLIENTPORT -j ACCEPT
kill "$PID"
rm "$TORRENTFILE" "dfile-$port" "client-$CLIENTPORT.log" "tracker-$port.log"
{% endhighlight %}
