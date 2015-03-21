---
# vim: ts=4 sw=4 expandtab syn=off
layout: post
title: Perspective According To Me
image:
   feature: kakadu-on-yellow-river.jpg
   credit: Yellow Water al Kakadu National Park, Australia
   creditlink: https://en.wikipedia.org/wiki/Kakadu_National_Park
---

I tried to read about perspective in various texts (e.g. Loomis), but
there was always something that didn't tick in the right way. This
is my attempt at setting something on paper... for my future
reference.

In particular, I was a bit shocked that in Loomis' text the determination
of Measuring Points is (at least apparently) arbitrary. My analysis shows
that in 2-points perspective the two focal points FP1 and FP2 are not
independent from the measuring point MP, or in other terms you can set
two of them arbitrarily but the third will somehow be implied.

We start with a rectangle on the floor and our eye that looks in a
direction. This arbitrary choice of the eye position and the direction
will determine the position of the measuring point, as we will see
later. The following picture provides a view from the top of this
situation.

![Figure and Eye](/images/perspective-according-to-me/perspective-01-figure-and-eye.png){: style="border: 1px gray solid"}

Now we set the position of the projection plane. It will be orthogonal to
the direction the eye is looking at, so from our top view it will appear
as a line. For convenience, we will make this plane touch the nearest
corner of the picture we want to project, so we will refer to it as the
*Near Plane*.

![Figure and Eye](/images/perspective-according-to-me/perspective-02-projection-plane.png){: style="border: 1px gray solid"}

We now start to draw the scene for the perspective projection. The first
two things will be the *Horizon Line* and the *Near Line*. This line
is the intersection between the horizontal plane where the rectangle
is placed and the *Near Plane" discussed before.

![Figure and Eye](/images/perspective-according-to-me/perspective-03-near-and-horizon.png){: style="border: 1px gray solid"}

We can determine the position of our *Measuring Point* MP by simply
extending the direction of view until we hit the *Horizon Line*.

![Figure and Eye](/images/perspective-according-to-me/perspective-04-measuring-point-determination.png){: style="border: 1px gray solid"}

In the perspective projection, the MP is a point to the infinite that
represents a direction, that is the same direction as where the eye
is looking at and is represented by vertical lines in our view from
the top. We report the four corners of our rectangle to both the
*Near Plane* on the bottom of the picture, and the corresponding
*Near Line* in the middle.

![Figure and Eye](/images/perspective-according-to-me/perspective-05-measuring-point-reports.png){: style="border: 1px gray solid"}

Vertical lines in the top view are parallel lines that converge
towards the MP in the perspective projection. Only three such lines
are actually needed, because the point touching the *Near Plane* is
already known. The other three corners will lie somewhere in these
three lines converging towards the MP, but we still don't know
where exactly.

![Figure and Eye](/images/perspective-according-to-me/perspective-06-measuring-point-projection.png){: style="border: 1px gray solid"}

We can now consider at this point that we're actually dealing with
a two-points perspective projection, where the two focal points will
be given by the projection towards the *Horizon Line* of the segments
of our rectangle. So, in our top view we can detect these two
directions FP1 and FP2 as parallels to the segments. We also extend
the segments in order to find where their continuation would intersect
the *Near Plane*.

![Figure and Eye](/images/perspective-according-to-me/perspective-07-focal-points-starter.png){: style="border: 1px gray solid"}

This intersection, of course, determines the intersection on the
*Near Line* too.

![Figure and Eye](/images/perspective-according-to-me/perspective-08-focal-points-reports.png){: style="border: 1px gray solid"}

It's time now to choose where we want to place one of the focal points
in the *Horizon Line*. We arbitrarily set FP1 to the position in the
following picture.

![Figure and Eye](/images/perspective-according-to-me/perspective-09-focal-point-1-assignment.png){: style="border: 1px gray solid"}

At this point we can draw the projections of the two lines that
include the segments parallel to the direction of FP1.

![Figure and Eye](/images/perspective-according-to-me/perspective-10-focal-point-1-projection.png){: style="border: 1px gray solid"}

By using the intersections between these two lines and the ones
determined by the MP we can find where the four corners of our
rectangle are placed in the projected part of our drawing.

![Figure and Eye](/images/perspective-according-to-me/perspective-11-figure-points-determination.png){: style="border: 1px gray solid"}

We are now ready to draw the projected rectangle.

![Figure and Eye](/images/perspective-according-to-me/perspective-12-figure-drawing.png){: style="border: 1px gray solid"}

By continuing the lines that include the segments parallel to FP2 we
can determine the position of FP2 on the *Horizon Line* and complete our
excercise.

![Figure and Eye]

[Figure and Eye]:/images/perspective-according-to-me/perspective-13-focal-point-2-projection.png
{: style="border: 1px gray solid"}

    ![Figure and Eye](/images/perspective-according-to-me/perspective-13-focal-point-2-projection.png){: style="border: 1px gray solid"}

To summarize:

* the position of the eye and the *Near Plane* eventually determine the
  position of the Measuring Point;
* the position of one of the two focal points is determined arbitarily
* the position of the other focal point in the two-points perspective
  is a consequence of the MP, FP1 and the distance between the
  *Near Line* and the *Horizon Line*.
