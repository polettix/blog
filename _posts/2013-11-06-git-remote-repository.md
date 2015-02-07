---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: Set up a remote git repository
image:
   feature: yellow-river.jpg
---

I sometimes happen to start a local repository that then I want to
replicate on my server, here's what I use.

{% highlight bash %}
#!/bin/bash

basedirname=$(basename "$PWD")
repository=${1:-"perl/$basedirname"}
remote=${2:-origin}

remote_hostname=example.com
remote_base="ssh://user@$remote_hostname/path/to/git"

ssh "$remote_hostname" "
      cd git &&
      mkdir -p '$repository' &&
      cd '$repository' &&
      git init --bare
   " &&
   git remote add "$remote" "$remote_base/$repository" &&
   git push -u --all origin
{% endhighlight %}

I call this script `remotise`. When I want to set up the remote
repository, I hop into the relevant repository for the directory and issue:

{% highlight bash %}
cd /path/to/project

# Option 1: DWIM
remotise

# Option 2: set the path in the repository (I don't do Perl only)
remotise web/someproject

# Option 3, set the name of the repository (shown by git memo) as well:
remotise web/someproject upstream
{% endhighlight %}

That's all folks!
