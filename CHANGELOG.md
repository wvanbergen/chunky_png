# Change Log

## 1.3.3 - 2014-10-24

## 1.3.2 - 2014-10-18

## 1.3.1 - 2014-04-28

## 1.3.0 - 2014-02-10

## 1.2.9 - 2013-10-17

## 1.2.8 - 2013-03-30

## 1.2.7 - 2013-01-07

## 1.2.6 - 2012-08-07

## 1.2.5 - 2011-09-23

- Edge case bugfix in `Color.decompose_alpha_component` that could get triggered in the `change_theme_color! ` method.

## 1.2.4 - 2011-09-14

- Added data URL importing `Canvas.from_data_url`.

## 1.2.3 - 2011-09-14

- Added data URL exporting `Canvas#to_data_url` to easily use PNGs inline in CSS or HTML.

## 1.2.2 - 2011-09-14

- Workaround for performance bug in REE.

## 1.2.1 - 2011-08-10

- Added bicubic resampling of images.
- Update resampling code to use integer math instead of floating points.

## 1.2.0 - 2011-05-08

- Properly read PNG files with a tRNS chunk in color mode 0 (grayscale) or 2 (true color).

## 1.1.2 - 2011-05-06

- Added `Color.to_grayscale` and `Canvas#grayscale!` to convert colors and canvases to grayscale.
- Memory footprint improvement of `Canvas#resample!`

## 1.1.1 - 2011-04-22

- Added `Canvas#to_alpha_channel_bytes` and `Canvas#to_grayscale_stream` to export raw pixel data.
- Spec suite cleanup

## 1.1.0 - 2011-03-19

- Add bezier curve drawing: `Canvas#bezier_curve`.
- RDoc fixes & improvements.

## 1.0.1 - 2011-03-08

- Performance improvements.

## 1.0.0 - 2011-03-06

*Note*: the are some API changes for this release. If you are using `Canvas#compose` or `Canvas#replace`, these methods will no longer operate in place, but will return a new canvas instance instead. The in place versions have been renamed to `compose!` and `replace!` to be more consistent with the rest of the API.

- Added image resampling using the nearest neighbor algorithm: `Canvas#resample`.
- Added circle and polygon drawing methods: `Canvas#circle` and `Canvas#polygon`.
- Added in place version of `Canvas#crop`, `Canvas#rotate_180`, `Canvas#flip_horizontally` and `Canvas#flip_vertically`. Just add a bang to the method name (e.g. `Canvas#crop!`) and it will change the current canvas instead of returning a new one. These implementations are also more memory and CPU efficient.
- Added geometry helper classes: `ChunkyPNG::Point`, `ChunkyPNG::Dimension` and  `ChunkyPNG::Vector`.
- Added a list of HTML named colors. Get them by calling `ChunkyPNG::Color(:teal)` or `ChunkyPNG::Color('red @ 0.8')`
- Added encoding support for 1-, 2-, and 4-bit grayscale images.
- Cleaned up auto-detection of color mode settings. It will now choose 1 bit grayscale mode if an image only contains black and white. (The other low bitrate grayscale modes are never chosen automatically.)
- RDoc improvements. See http://rdoc.info/gems/chunky_png/frames.
- ChunkyPNG is now also tested on Ruby 1.8.6.

## 0.12.0 - 2010-12-12

- Added support for encoding indexed images with a low bitrate. It will automatically use less bits per pixel if possible.
- Improved testing setup. ChunkyPNG is now tested on Ruby 1.8.7, 1.9.2, JRuby and Rubinius.

## 0.11.0 - 2010-11-16

- Decoding of 1, 2 and 4 bit indexed color images.
- Decoding of 1, 2 and 4 bit grayscale images.
- Decoding 16 bit images. The extra bits will be discarded, so the image will be loaded as 8 bit.
- Used the official PNG suite to build a more complete test suite.

## 0.10.5 - 2010-10-21

- Bugfix: allow 256 instead of 255 colors for indexed images.

## 0.10.4 - 2010-10-17

- Improved handling of binary encoding for strings in Ruby 1.9.

## 0.10.3 - 2010-10-07

- Small fix to make grayscale use the B byte consistently.

## 0.10.2 - 2010-10-04

- Another small fix for OilyPNG compatibility

## 0.10.1 - 2010-10-03

- Small fix for OilyPNG compatibility

## 0.10.0 - 2010-10-03

- Refactored decoding and encoding to work on binary strings instead of arrays of integers. This gives a nice speedup and uses less memory. Thanks to Yehuda Katz for the idea.

## 0.9.2 - 2010-09-16

- Fixed an issue with interlaced images.

## 0.9.1 - 2010-09-15

- Fixed image metadata issue when duplicating images.

## 0.9.0 - 2010-08-18

- Added `flip_horizontally`, `flip_vertically`, `rotate_left`, `rotate_right` and `rotate_180` to `ChunkyPNG::Canvas`.
- Now raises `ChunkyPNG::OutOfBounds` exceptions when referencing coordinates outside the image bounds.
- Added Gemfile for development dependency management.

## 0.8.0 - 2010-06-30

- Added `ChunkyPNG::Image#rect` to draw simple rectangles.
- Fixed composing a transparent color on a fully transparent background.

## 0.7.3 - 2010-04-28

- Based on the suggestion of [Dirkjan Bussink](http://github.com/dbussink), introduced custom exception classes:
  - `ChunkyPNG::SignatureMismatch` is raised when the PNG signature could not be found. Usually this means the the file is not a PNG image.
  - `ChunkyPNG::CRCMismatch` is raised when the a CRC check for a chunk in the PNG file fails.
  - `ChunkyPNG::NotSupported` is raised when the PNG image uses a feature that ChunkyPNG does not support.
  - `ChunkyPNG::ExpectationFailed` is raised when a required expectation failed.

## 0.7.2 - 2010-04-28 [YANKED]

## 0.7.1 - 2010-03-23

- Some fixes for 32-bit systems.

## 0.7.0 - 2010-03-15

- Added `:best_compression` saving routine to allow creating the smallest images possible.
- Added option to control Zlib compression level while saving.

## 0.6.0 - 2010-02-25

- Added methods to easily create different color variants of an image with a color theme. See [[Images with a color theme]] for more information.

## 0.5.8 - 2010-02-24

- Ruby 1.8.6 compatibility fixes
- Improved API documentation.

## 0.5.5 - 2010-02-15

- Added alpha decomposition to extract a color mask from a themed image.
- Improved API documentation.

## 0.5.4 - 2010-01-17

- Added `point` and `line` anti-aliased drawing functions.

## 0.5.3 - 2010-01-16

- Removed last occurrences of floating math to speed up the library.
- Added importing of ABGR and BGR streams.
- Added exporting an image as  ABGR stream.

## 0.5.2 - 2010-01-15

- Ruby 1.9 compatibility fixes.
- Improved speed of PNG decoding.
- Bugfix in *average* scanline decoding filter.

## 0.5.1 - 2010-01-15

- Added `:fast_rgba` and `:fast_rgb` saving routines, which yield a 1500% speedup when saving an image.

## 0.5.0 - 2010-01-15

- Complete rewrite of the earlier versions, now including awesomeness and unicorns.
