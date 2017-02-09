---
# vim: ts=4 sw=4 expandtab syn=off :
layout: post
title: Markdown to HTML in Windows Explorer
image:
   feature: yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
comments: true
---

At work we have [SharePoint][] but I don't really like its editor in the
Wiki (at least how it is setup in our local installation). Well, actually
I like using [Markdown][] for editing most of the stuff, so here's what
I managed to setup.

## Table of Contents

- TOC
{:toc}

## Use Case

I wanted all of this to be as hassle-free as possible. Our [SharePoint][]
Wiki editor allows me to easily set the whole HTML for the article. So the
high level workflow is the following:

1. Write Markdown
2. Turn Markdown to HTML
3. Put HTML in clipboard 
4. Paste HTML

I eventually landed on this high-level workflow for the two middle steps:

> Right-click on the [Markdown][] file in Explorer, select an option
> called `HTML to clipboard...`, let it work and enjoy the HTML in the
> clipboard, ready to be pasted.

It should probably be easy to also tie the same *transform-then-copy*
routine to some editor hook.

## Install a Markdown Converter

First thing I needed a Markdown Converter. There's a few good out there,
two that I tried are:

- [Pandoc][]: has a nice self-contained installer for Windows, so it's
  probably the most hassle-free solution;
- [Kramdown][]: requires a [Ruby][] installation but provides you what
  [GitHub Pages][] use by default.

It's really your call to this regard. We'll assume in the following that
you settled for `pandoc`, but it's just a word change.

## Run `regedit`

There will be some `regedit` magic to do, so you have to be comfortable
with it. To run it, open the *Windows* menu and type `regedit` in the
`Search programs and files` box (focused by default, so you might just
start typing), then select program `regedit.exe` in the list of results
(it should be the only one, but your mileage may vary).

## Ensure `md` Extension Handling

In my case, I like to use extension `md` for [Markdown][] files. I already
had [MarkdownPad][] installed, which means that this file extension was
already *known* to the Windows system. Anyway, whatever the case, in
`regedit`:

1. Open `HKEY_CLASSES_ROOT` and scroll down to see if you already have
   `.md` defined (or whatever other extension you want to associate to
   [Markdown][] files, of course).

    - If you have it, skip to step 2 below.

    - Otherwise, right-clik on `HKEY_CLASSES_ROOT` at the top and
    select `New`, then `Key` and name the new key `.md` (don't forget the
    leading dot!).

    - In the right pane, double-click on `(Default)` and set a value,
    like `mymarkdown` or so. This is the *type* associated to the
    extension.

2. Take note of the value associated to `(Default)`. It will either be
   what you found there already, or whatever you set in the previous step.
   We will assume it's `mymarkdown` (but, for example, I have
   `markdownpad2` because `.md` is associated with [MarkdownPad][]).


## Set Command for Conversion

After the previous section, you now have the *type*, which we will assume
to be `mymarkdown`. Still in `regedit`:

1. Inside `HKEY_CLASSES_ROOT` again, locate the handler for `mymarkdown`
   (or whatever you set/found in the previous step).

    - If you already have it, skip to step 2 below.

    - Otherwise, right-clik on `HKEY_CLASSES_ROOT` at the top and select
      `New`, then `Key` and name the new key `mymarkdown` (or
      whatever...).

2. If there is no `shell` sub-key, create with right-click, `New`, `Key`
   like before. There is no need to associate a value here.

3. Create a new key inside `shell` from step 4, and name it `toHTML`.
   Select it and, in the right pane, double-click on `(Default)` and set
   it to `HTML to clipboard...` - this is the message you will see in
   Explorer.

4. Create a new key inside `toHTML`, named `command`. Select it and, in
   the right pane, double click on `(Default)` and set the value to:

        cmd /C "chcp 65001 & pandoc '%1' | clip"

    Set it to `kramdown` or any other converter of your choice if you
    want, of course.

## Use it!

This is it! Head over to Explorer, right-click on any file with `.md`
extension and you're ready to paste shiny HTML!

The input files are assumed to be [UTF-8][] encoded, as well as what you
will eventually end up with in the clipboard (it's the reason why we put
the `chcp 65001` command before the real conversion). If you want to
adventure into different encodings... let us know!


[Pandoc]: http://pandoc.org/
[Kramdown]: https://kramdown.gettalong.org/
[MarkdownPad]: http://markdownpad.com/
[SharePoint]: https://en.wikipedia.org/wiki/SharePoint
[Markdown]: https://en.wikipedia.org/wiki/Markdown
[UTF-8]: https://en.wikipedia.org/wiki/UTF-8
[Ruby]: https://www.ruby-lang.org/
[GitHub Pages]: https://pages.github.com/
