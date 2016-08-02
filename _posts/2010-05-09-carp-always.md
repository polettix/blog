---
# vim: ts=4 sw=4 expandtab syn=off tw=72
layout: post
title: 'Carp::Always would have helped'
keywords: 'perl, debugging'
image:
   feature: tramonto.jpg
   credit: Tramonto in Australia
   creditlink: https://en.wikipedia.org/wiki/Australia
comments: false
---

Yesterday I wrote an [article](dist-zilla) about [Dist::Zilla] and,
at a certain point, I had issues with a missing `Changes` file,
that triggered an error whose source was not evident:

[Dist::Zilla]: https://metacpan.org/pod/Dist::Zilla

{% highlight text %}
~/dzilla/Sample-Module$ dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.3 to 0.1.4
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.4
[DZ] writing archive to Sample-Module-0.1.4.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] ...
...
[@Filter/TestRelease] all's well; removing .build/OIeyjyhBZd
[FakeRelease] Fake release happening (nothing was really done)
can't open Changes for reading: No such file or directory\
 at /opt/perl-5.8.8/lib/site_perl/5.8.8/Dist/Zilla/File/OnDisk.pm line 31.
{% endhighlight %}


To find out the offending plugin I decided to hack
`Dist::Zilla::File::OnDisk`, turning a `die()` into a `Carp::confess()`
to see what was going wrong:

<pre>
<em style="color:red">--- src.OnDisk.pm</em>
<em style="color:green">+++ dst.OnDisk.pm</em>
@@ -28,7 +28,8 @@
 sub _read_file {
   my ($self) = @_;
 
   my $fname = $self->_original_name;
<em style="color:red">-  open my $fh, '<', $fname or die "can't open $fname for reading: $!";</em>
<em style="color:green">+  use Carp;
+  open my $fh, '<', $fname or Carp::confess "can't open $fname for reading: $!";</em>
   my $content = do { local $/; <$fh> };
 }

</pre>

Had I read the *title* of [Tokuhiro Matsuno](http://d.hatena.ne.jp/tokuhirom/)'s post
[Carp::Always::Color](http://d.hatena.ne.jp/tokuhirom/20100508/1273279912)
(well, I can't read Japanese, so I can't go beyond an
English title!), I would have avoided all the editing mess to just
use [Adriano Ferreira](http://search.cpan.org/~ferreira/)'s
[Carp::Always].

[Carp::Always]: https://metacpan.org/pod/Carp::Always

So, instead of editing the file, I should have find out where
`dzil` is installed in my system:

{% highlight text %}
~/dzilla/Sample-Module$ which dzil
/opt/perl/bin/dzil
{% endhighlight %}

This way, the `perl` executable can be called directly to add [Carp::Always]
in the command line:

{% highlight text %}
~/dzilla/Sample-Module$ perl -MCarp::Always /opt/perl/bin/dzil release
[DZ] beginning to build Sample-Module
[BumpVersionFromGit] Bumping version from 0.1.3 to 0.1.4
[DZ] guessing dist's main_module is lib/Sample/Module.pm
[DZ] extracting distribution abstract from lib/Sample/Module.pm
[DZ] writing Sample-Module in Sample-Module-0.1.4
[DZ] writing archive to Sample-Module-0.1.4.tar.gz
[@Filter/Check] branch master is in a clean state
[@Filter/TestRelease] ...
...
[@Filter/TestRelease] all's well; removing .build/dE1qIIQWEG
[FakeRelease] Fake release happening (nothing was really done)
can't open Changes for reading: No such file or directory\
 at /opt/perl-5.8.8/lib/site_perl/5.8.8/Dist/Zilla/File/OnDisk.pm line 31
   Dist::Zilla::File::OnDisk::_read_file(...
   Dist::Zilla::File::OnDisk::__ANON__(...
   Class::MOP::Attribute::default(...
   Dist::Zilla::File::OnDisk::content(...
   <em style="color:red">Dist::Zilla::Plugin::Git::Commit</em>::_get_changes(...
   Dist::Zilla::Plugin::Git::Commit::__ANON__(...
   String::Formatter::method_replace(...
   String::Formatter::format(...
   String::Formatter::__ANON__(...
   Dist::Zilla::Plugin::Git::Commit::get_commit_message(...
   Dist::Zilla::Plugin::Git::Commit::after_release(...
   Dist::Zilla::release(...
   Dist::Zilla::App::Command::release::execute(...
   App::Cmd::execute_command(...
   App::Cmd::run(...
{% endhighlight %}

*Voilà*, a perfect stack trace with the info I was after!
