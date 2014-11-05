---
layout: post
author: Willem van Bergen
title: The value of pure Ruby libraries
---

I started working on ChunkyPNG [early 2010](https://github.com/wvanbergen/chunky_png/commit/aa8a9378eedfc02aa1d0d1e05c313badc76594a7). At the time, my employer [Floorplanner](http://www.floorplanner.com) was struggling with memory leaks and stability issues of [RMagick](http://www.imagemagick.org/RMagick/doc/), the Ruby wrapper aorund [ImageMagick](http://www.imagemagick.org/). Because our needs were pretty simple (saving a stream of pixels into a PNG files), I thought I could write a simple library to do that for us, so we could get rid of RMagick. Not much later, ChunkyPNG was born.

Even though ChunkyPNG has grown in scope and complexity, it still is a pure Ruby library. Initially, this was purely for practical reasons: I had no idea how to write Ruby C extensions. Performance was not an important concern for the problem at hand, and wasn't RMagick being a C extension not the cause of the memory leaks? By writing pure Ruby, I could get results faster and let the Ruby interpreter do the hard work of managing memory for me. <sup>[1]</sup>

### Performance becomes important

As ChunkyPNG turned into a more full implementation of the PNG standard, more people started using it for a broader set of problems. Performance becomes more important. I put a decent effort into optimizing the [memory efficiency]({% post_url 2010-01-14-memory-efficiency-when-using-ruby %}) and [performance]({% post_url 2010-01-17-ode-to-array-pack-and-string-unpack %}) of the library, with some noticable gains for both.

However, it becomes clear that there are limits on how far you can push performance in Ruby. The fact that I am implementing a library that by nature requires a lot of memory and computation is not going to change.

So what are the options? I could start telling people asking for more performance to use RMagick instead. But that is not going to happen after all my ImageMagick bashing. <sup>[2]</sup> In the end, I would have to do some C programming.

### Being pure Ruby is a feature

I had the options of either implementing the C extension as part of ChunkyPNG, or build a separate library. <sup>[3]</sup> Because ChunkyPNG was becoming popular, I wanted people to enjoy the performance boost without having to update their code. So my initial thought was to add a C extension to ChunyPNG. However, even though ChunkyPNG was pure Ruby for pragmatic reasons, for many people this was the reason why they were using the library.

First of all, C extensions are MRI specific. This means that many C extensions won't work on Rubinius or JRuby, and I wanted my library to be useful for people on these environments as well. <sup>[4]</sup> Also, I am resposible to overcome platform differences, even though `ruby.h` contains some nice helpers for this.

But more importantly, this would require everybody that wants to install to have a C compiler toolchain installed. OSX comes with Ruby and Rubygems installed, but lacks a compiler out of the box. While installing a compiler toolchain may be a very normal thing for a Ruby developer, it turns out that many of the users of the library were not Ruby developers at all. [Compass](http://compass-style.org/), a popular CSS authoring framework, uses ChunkyPNG to generate sprite images. Most Compass users are front-end developers, which primaily use HTML, CSS and Javascript, and not Ruby.

Telling them to install a C compiler chain, just to be able to install Compass is simply unacceptable. Libraries that do require a C compiler inevitably get a lot of bug reports or support requests of people that are having issues installing the library, because of differences in development environments. <sup>[5]</sup>

In short: being pure Ruby can be a feature, and is not just an implementation detail.

### OilyPNG: a mixin library

So instead of adding a C extension, I started working on a separate library, [OilyPNG](https://github.com/wvanbergen/oily_png). Instead of making this a standalone library, I designed it to be a mixin module that depends on ChunkyPNG.

The approach is simple: OilyPNG contains some modules that implement some of the methods of ChunkyPNG in C. When  OilyPNG is loaded with `require 'oily_png'`, is first loads ChunkyPNG and uses `Module#include` and `Module#extend` to [overwrite some methods in ChunkyPNG with OilyPNG's faster implementation](https://github.com/wvanbergen/oily_png/blob/master/lib/oily_png.rb).

This approach allows us to keep ChunkyPNG pure Ruby, and make OilyPNG 100% API comptaible with ChunkyPNG. It is even possible to make OilyPNG optional in your project:

{% highlight ruby %}
begin
  require 'oily_png'
rescue LoadError
  require 'chunky_png'
end
{% endhighlight %}

This approach has some other advantages as well. Instead of having to implement everything at once to get to a library that implements most of ChunkyPNG, we can do this step by step while always providing 100% functional parity. Profile ChunkyPNG, find a slow method, implement it in OilyPNG, and iterate. This way OilyPNG doesn't suffer from a bootstrapping problem, and can grow the scope of the library organically.

And because we have a well tested, pure Ruby implementation available to which OilyPNG is supposed to be 100% compatible, testing OilyPNG is simple. We just call a method on ChunkyPNG, and do the exact same call on an OilyPNG-enhanced ChunkyPNG, and compare the results.

### To conclude

Being pure Ruby can be a feature of a library, don't give it up too easily, even though performance may be an issue. Using a hybrid approach of a pure Ruby library, with a native companion library is feasible. <sup>[6]</sup>

---------------------------------------

#### Footnotes

1. This is also why I avoided using the [png gem](https://github.com/seattlerb/png), an "almost-pure-ruby" library that was available at the time. It uses [inline C](https://github.com/seattlerb/rubyinline) to speed up some of the algorithms.
2. I should note that I haven't used ImageMagick and RMagick since 2010. SO my knowledge about the current state of these libraries is extremely outdated at this point.
3. I could have leveraged the work of [libpng](http://www.libpng.org/pub/png/libpng.html) instead of implementing the algorithms myself. I decided not to, because libpng's API doesn't lend itself very well for the cherry-picking of hotspots approach I took with OilyPNG. You basically have to go all in if you want to use libpng. I think a Ruby PNG library that simply wraps libpng still has potential, but because of the reasons outlined in this article, I will leave that as an exercise to the reader. :)
4. As an interesting side note: the Rubinius and JRuby developers have used ChunkyPNG as a performance benchmarking tool, because it contains a non-trivial amount of code and is computation heavy.
5. Unfortunately, OilyPNG is [not an exception](https://github.com/wvanbergen/oily_png/issues/12) to this rule.
6. I am happy that my current employer is using the same approach with [Liquid](http://liquidmarkup.org/), and it's C extension library [liquid-c](https://github.com/Shopify/liquid-c). Even though this requires copying Liquid's quirky parsing behavior in certain edge cases.
