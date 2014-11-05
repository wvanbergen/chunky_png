---
layout: default
title: ChunkyPNG
---


ChunkyPNG a pure Ruby library that can read and write PNG files. It aims to be able to read any image conforms to, the PNG standard, give read/write access to the image's pixels and metadata, and efficiently encode images.

The name of this library is intentionally similar to Chunky Bacon and Chunky GIF. Use Google if you want to know _why. :-)

## Basic usage

Install the library using `[sudo] gem install chunky_png`.

<iframe width="560" height="315" src="//www.youtube.com/embed/zRVVbnhswH0" frameborder="0" allowfullscreen></iframe>

This screencast by John Davison shows how to create an image using basic operations in ChunkyPNG. The follow Ruby snippet will also give you an overview on how to use the library.

{% highlight ruby %}
require 'chunky_png'

# Creating an image from scratch, save as an interlaced PNG
png = ChunkyPNG::Image.new(16, 16, ChunkyPNG::Color::TRANSPARENT)
png[1,1] = ChunkyPNG::Color.rgba(10, 20, 30, 128)
png[2,1] = ChunkyPNG::Color('black @ 0.5')
png.save('filename.png', :interlace => true)

# Compose images using alpha blending.
avatar = ChunkyPNG::Image.from_file('avatar.png')
badge  = ChunkyPNG::Image.from_file('no_ie_badge.png')
avatar.compose!(badge, 10, 10)
avatar.save('composited.png', :fast_rgba) # Force the fast saving routine.

# Accessing metadata
image = ChunkyPNG::Image.from_file('with_metadata.png')
puts image.metadata['Title']
image.metadata['Author'] = 'Willem van Bergen'
image.save('with_metadata.png') # Overwrite file

# Low level access to PNG chunks
png_stream = ChunkyPNG::Datastream.from_file('filename.png')
png_stream.each_chunk { |chunk| p chunk.type }
{% endhighlight %}

For more information on the API, see the project's [RDoc documentation](http://www.rubydoc.info/gems/chunky_png/frames)

## Articles

{% for post in site.posts %}
- [{{ post.title }}]({{ post.url }})
{% endfor %}

## Notes and caveats

**Performance:** ChunkyPNG keeps memory usage and speed in mind. As it is a pure Ruby library, it will not be able to match the performance of a native library. To partially overcome this issue, [OilyPNG](http://github.com/wvanbergen/oily_png) implements some of the ChunkyPNG algorithms in C, which provides a massive speed boost to encoding and decoding and some other operations, without any API changes.

**Security:** ChunkyPNG is vulnerable to decompression bombs, which means that ChunkyPNG is vulnerable to DOS attacks by running out of memory when loading a specifically crafted PNG file. Because of the pure-Ruby nature of the library it is very hard to fix this problem in the library itself.

In order to safely deal with untrusted images, you should make sure to do the image processing using ChunkyPNG in a separate process, e.g. by using `fork` or a background processing library.

## About

The library was written by Willem van Bergen for Floorplanner.com.

- Check out the [changelog](https://github.com/wvanbergen/chunky_png/blob/master/CHANGELOG.rdoc) to see what changed in all versions.
- Report bugs on the project's [issue tracker](https://github.com/wvanbergen/chunky_png/issues)
- Want to contribute? Please do! [CONTRIBUTING.rdoc](https://github.com/wvanbergen/chunky_png/blob/master/CONTRIBUTING.rdoc) has the information you need to get started.
- [MIT licensed](https://github.com/wvanbergen/chunky_png/blob/master/LICENSE).
