---
layout: default
title: ChunkyPNG
---

### ChunkyPNG

ChunkyPNG is a pure Ruby library to read and write PNG images.

### Creating a simple image from scratch

{% highlight ruby %}
get '/dynamic_smile.png' do
  # Create a 600x400 image with transparent background
  image = ChunkyPNG::Image.new(15, 15)

  # Draw some stuff
  image.circle(7, 7, 7, ChunkyPNG::Color::BLACK, ChunkyPNG::Color.rgb(255, 255, 0))
  image.rect(4, 5,  5, 6, ChunkyPNG::Color::BLACK)
  image.rect(9, 5, 10, 6, ChunkyPNG::Color::BLACK)
  image.line(5, 10, 9, 10, ChunkyPNG::Color::BLACK)
  image[ 4, 9] = ChunkyPNG::Color::BLACK
  image[10, 9] = ChunkyPNG::Color::BLACK

  # Return the result as a PNG file
  content_type 'image/png'
  image.to_blob
end
{% endhighlight %}

### Modifying an existing image

{% highlight ruby %}
post '/watermark_image' do
  # Load the uploaded image
  image = ChunkyPNG::Image.from_io(params[:uploaded_file][:tempfile])
  watermark = ChunkyPNG::Image.from_file('watermark.png')

  # Compose the watermark onto the image
  watermark_x = image.width  - watermark.width  - 5
  watermark_y = image.height - watermark.height - 5
  image.compose!(watermark, watermark_x, watermark_y)

  # Return the watermarked image 
  content_type "image/png"
  filename params[:uploaded_file][:filename].sub(/\.png$/, "_watermarked.png")
  image.to_blob
end
{% endhighlight %}
