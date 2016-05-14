---
# vim: ts=4 sw=4 expandtab syn=off tw=72
layout: post
title: Dockerize a simple application
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

This is how I did it!

## Install Docker

Nothing fancy here, detailed instructions can be found for the three
environments:

- [Linux](https://docs.docker.com/linux/)
- [Mac](https://docs.docker.com/mac/)
- [Windows](https://docs.docker.com/windows/)

In particular, if you're a Debian enthusiast like me, [you might find
this
interesting](https://docs.docker.com/engine/installation/linux/debian/).

## Select a Base Image

I'm selecting Alpine Linux for this exercise. Being able to strip the
base image size down to 5 megabytes sounds like the overhead for using
Docker is pretty negligible.

    $ docker pull alpine

    $ docker images
    REPOSITORY   TAG     IMAGE ID      CREATED       SIZE
    alpine       latest  70c557e50ed6  9 days ago    4.798 MB
    hello-world  latest  690ed74de00f  5 months ago  960 B

## Craft an installation sequence

This is probably where I'm being naïve. I found an [article by Jonathan
Bergnoff](http://jonathan.bergknoff.com/journal/building-better-docker-images)
that basically suggests to merge all operations into one single run,
possibly in a shell script.

Creating a container is easy, as well as starting it:

    $ docker create -it --name myapp alpine /bin/sh
    674d65a22af0917d7ffcd23640fbf66c9b3b17facfab4a443dadc99dc335f478
    $ docker start 674d65a22af0

I packed my stuff in app.sh, a script that will do all that I need. I take the
chance to transfer it into the new container:

    $ docker cp app.sh 674d65a22af0:/tmp/

To figure out what I need to do next, I get into the container interactively:

    $ docker attach 674d65a22af0
    / # 

You might need to hit `enter` another time after issuing the command above,
just to get the shell.

In my example, I need to run a fairly recent base Perl, because I'll be
installing modules by myself. So, I'm going to use the perl that is shipped by
default, because it's... fairly recent!

    # this is something run by app.sh --hopefully!
    apk update
    apk --update add perl
    apk --update add build-base perl-dev

    # do what I have to do with my stuff in the container

    # remove stuff that's no more needed
    apk del build-base perl-dev
    rm -rf /tmp/app.sh


I neeed to install some Perl modules using cpanm, so I placed it into /

## Resulting Dockerfile

    FROM alpine
    MAINTAINER polettix
    COPY install.sh /tmp/install.sh




Sfank

    apk --update add libxml2 expat
    apk --update add libxml2-dev expat-dev

    apk del libxml2-dev expat-dev
