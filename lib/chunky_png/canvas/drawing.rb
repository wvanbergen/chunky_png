module Skalp
  module ChunkyPNG
    class Canvas

      # Module that adds some primitive drawing methods to {ChunkyPNG::Canvas}.
      #
      # All of these methods change the current canvas instance and do not create a new one,
      # even though the method names do not end with a bang.
      #
      # @note Drawing operations will not fail when something is drawn outside of the bounds
      #       of the canvas; these pixels will simply be ignored.
      # @see ChunkyPNG::Canvas
      module Drawing

        # Composes a pixel on the canvas by alpha blending a color with its background color.
        # @param [Integer] x The x-coordinate of the pixel to blend.
        # @param [Integer] y The y-coordinate of the pixel to blend.
        # @param [Integer] color The foreground color to blend with
        # @return [Integer] The composed color.
        def compose_pixel(x, y, color)
          return unless include_xy?(x, y)
          compose_pixel_unsafe(x, y, ChunkyPNG::Color.parse(color))
        end

        # Composes a pixel on the canvas by alpha blending a color with its background color,
        # without bounds checking.
        # @param (see #compose_pixel)
        # @return [Integer] The composed color.
        def compose_pixel_unsafe(x, y, color)
          set_pixel(x, y, ChunkyPNG::Color.compose(color, get_pixel(x, y)))
        end

        # Draws a Bezier curve
        # @param [Array, Point] A collection of control points
        # @return [Chunky:PNG::Canvas] Itself, with the curve drawn
        def bezier_curve(points, stroke_color = ChunkyPNG::Color::BLACK)

          points = ChunkyPNG::Vector(*points)
          case points.length
            when 0, 1; return self
            when 2; return line(points[0].x, points[0].y, points[1].x, points[1].y, stroke_color)
          end

          curve_points = Array.new

          t = 0
          n = points.length - 1
          bicof = 0

          while t <= 100
            cur_p = ChunkyPNG::Point.new(0,0)

            # Generate a float of t.
            t_f = t / 100.00

            cur_p.x += ((1 - t_f) ** n) * points[0].x
            cur_p.y += ((1 - t_f) ** n) * points[0].y

            for i in 1...points.length - 1
              bicof = binomial_coefficient(n , i)

              cur_p.x += (bicof * (1 - t_f) ** (n - i)) *  (t_f ** i) * points[i].x
              cur_p.y += (bicof * (1 - t_f) ** (n - i)) *  (t_f ** i) * points[i].y
              i += 1
            end

            cur_p.x += (t_f ** n) * points[n].x
            cur_p.y += (t_f ** n) * points[n].y

            curve_points << cur_p

            bicof = 0
            t += 1
          end

          curve_points.each_cons(2) do |p1, p2|
            line_xiaolin_wu(p1.x.round, p1.y.round, p2.x.round, p2.y.round, stroke_color)
          end

          return self
        end


        def plot(x, y, c, stroke_color)
          #plot the pixel at (x, y) with brightness c (where 0 ≤ c ≤ 255)
          #stroke_color = ChunkyPNG::Color.r(ChunkyPNG::Color::PREDEFINED_COLORS[:orange])
          #compose_pixel(x, y, ChunkyPNG::Color.fade(stroke_color, (c * 255).round))     #origineel
          alpha =  (c).round
          fg = ChunkyPNG::Color.rgba(ChunkyPNG::Color.r(stroke_color),
                                     ChunkyPNG::Color.g(stroke_color),
                                     ChunkyPNG::Color.b(stroke_color),
                                     ChunkyPNG::Color.a(alpha) )
          compose_pixel(x, y, fg)
        end

        def ipart(x)
          x < 0.0 ? x -= 1.0 : x
          x.to_i
        end

        def round(x)
          return ipart(x + 0.5)
        end

        def fpart(x)
          return x - x.to_i #'fractional part of x'
        end

        def rfpart(x)
          return 1 - fpart(x)
        end


        def line_xiaolin_wu_float(x0, y0, x1, y1, stroke_color, inclusive = true)
          steep = (y1 - y0).abs > (x1 - x0).abs
          if steep
            x0, y0 = y0, x0
            x1, y1 = y1, x1
          end

          if x0 > x1
            x0, x1 = x1, x0
            y0, y1 = y1, y0
          end

          dx = x1 - x0
          dy = y1 - y0
          gradient = dy / dx
          # handle first endpoint
          xend = round(x0)
          yend = y0 + gradient * (xend - x0)
          xgap = rfpart(x0 + 0.5)
          xpxl1 = xend   #this will be used in the main loop
          ypxl1 = ipart(yend)

          if steep
            plot(ypxl1, xpxl1, rfpart(yend) * xgap * 255, stroke_color)
            plot(ypxl1+1, xpxl1, fpart(yend) * xgap * 255, stroke_color)
          else
            plot(xpxl1, ypxl1, rfpart(yend) * xgap * 255, stroke_color)
            plot(xpxl1, ypxl1+1, fpart(yend) * xgap * 255, stroke_color)
          end

          intery = yend + gradient # first y-intersection for the main loop

          # handle second endpoint
          xend = round(x1)
          yend = y1 + gradient * (xend - x1)
          xgap = fpart(x1 + 0.5)
          xpxl2 = xend #this will be used in the main loop
          ypxl2 = ipart(yend)

          if steep
            plot(ypxl2  , xpxl2, rfpart(yend) * xgap * 255, stroke_color)
            plot(ypxl2+1, xpxl2,  fpart(yend) * xgap * 255, stroke_color)
          else
            plot(xpxl2, ypxl2,  rfpart(yend) * xgap * 255, stroke_color)
            plot(xpxl2, ypxl2+1, fpart(yend) * xgap * 255, stroke_color)
          end

          # main loop
          for x in (xpxl1 + 1)..(xpxl2 - 1)
            if  steep
              plot(ipart(intery)  , x, rfpart(intery) * 255, stroke_color)
              plot(ipart(intery)+1, x,  fpart(intery) * 255, stroke_color)
            else
              plot(x, ipart(intery),  rfpart(intery) * 255, stroke_color)
              plot(x, ipart(intery)+1, fpart(intery) * 255, stroke_color)
            end
            intery = intery + gradient
          end
        end
        alias_method :line_float, :line_xiaolin_wu_float

        # Draws an anti-aliased line using Xiaolin Wu's algorithm.
        #
        # @param [Integer] x0 The x-coordinate of the first control point.
        # @param [Integer] y0 The y-coordinate of the first control point.
        # @param [Integer] x1 The x-coordinate of the second control point.
        # @param [Integer] y1 The y-coordinate of the second control point.
        # @param [Integer] stroke_color The color to use for this line.
        # @param [true, false] inclusive Whether to draw the last pixel.
        #    Set to false when drawing multiple lines in a path.
        # @return [ChunkyPNG::Canvas] Itself, with the line drawn.
        def line_xiaolin_wu(x0, y0, x1, y1, stroke_color, inclusive = true)

          stroke_color = ChunkyPNG::Color.parse(stroke_color)
          dx = x1 - x0
          sx = dx < 0 ? -1 : 1
          dx *= sx
          dy = y1 - y0
          sy = dy < 0 ? -1 : 1
          dy *= sy

          if dy == 0 # vertical line
            x0.step(inclusive ? x1 : x1 - sx, sx) do |x|
              compose_pixel(x, y0, stroke_color)
            end

          elsif dx == 0 # horizontal line
            y0.step(inclusive ? y1 : y1 - sy, sy) do |y|
              compose_pixel(x0, y, stroke_color)
            end

          elsif dx == dy # diagonal
            x0.step(inclusive ? x1 : x1 - sx, sx) do |x|
              compose_pixel(x, y0, stroke_color)
              y0 += sy
            end

          elsif dy > dx  # vertical displacement
            compose_pixel(x0, y0, stroke_color)
            e_acc = 0
            e = ((dx << 16) / dy.to_f).round
            (dy - 1).downto(0) do |i|
              e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xffff
              x0 += sx if (e_acc <= e_acc_temp)
              w = 0xff - (e_acc >> 8)
              compose_pixel(x0, y0, ChunkyPNG::Color.fade(stroke_color, w))
              compose_pixel(x0 + sx, y0 + sy, ChunkyPNG::Color.fade(stroke_color, 0xff - w)) if inclusive || i > 0
              y0 += sy
            end
            compose_pixel(x1, y1, stroke_color) if inclusive

          else # horizontal displacement
            compose_pixel(x0, y0, stroke_color)
            e_acc = 0
            e = ((dy << 16) / dx.to_f).round
            (dx - 1).downto(0) do |i|
              e_acc_temp, e_acc = e_acc, (e_acc + e) & 0xffff
              y0 += sy if (e_acc <= e_acc_temp)
              w = 0xff - (e_acc >> 8)
              compose_pixel(x0, y0, ChunkyPNG::Color.fade(stroke_color, w))
              compose_pixel(x0 + sx, y0 + sy, ChunkyPNG::Color.fade(stroke_color, 0xff - w)) if inclusive || i > 0
              x0 += sx
            end
            compose_pixel(x1, y1, stroke_color) if inclusive
          end

          return self
        end

        alias_method :line, :line_xiaolin_wu


        # Draws a polygon on the canvas using the stroke_color, filled using the fill_color if any.
        #
        # @param [Array, String] The control point vector. Accepts everything {ChunkyPNG.Vector} accepts.
        # @param [Integer] stroke_color The stroke color to use for this polygon.
        # @param [Integer] fill_color The fill color to use for this polygon.
        # @return [ChunkyPNG::Canvas] Itself, with the polygon drawn.
        def polygon(path, stroke_color = ChunkyPNG::Color::BLACK, fill_color = stroke_color)

          if path.length == 2
            x0, y0 = path[0].x, path[0].y
            x1, y1 = path[0].x, path[0].y
            line_float(x0, y0, x1, y1, stroke_color, inclusive = true)
          else
            vector = ChunkyPNG::Vector(*path)
            raise ArgumentError, "A polygon requires at least 3 points" if path.length < 3

            stroke_color = ChunkyPNG::Color.parse(stroke_color)
            fill_color   = ChunkyPNG::Color.parse(fill_color)

            # Fill
            unless fill_color == ChunkyPNG::Color::TRANSPARENT

              vector.y_range_float.each do |y|
                intersections = []
                vector.edges.each do |p1, p2|
                  if (p1.y < y && p2.y >= y) || (p2.y < y && p1.y >= y)
                    intersections << (p1.x + (y - p1.y).to_f / (p2.y - p1.y) * (p2.x - p1.x)).round
                  end
                end

                intersections.sort!
                0.step(intersections.length - 1, 2) do |i|
                  intersections[i].upto(intersections[i + 1]) do |x|
                    compose_pixel(x, y, fill_color)
                  end
                end
              end
            end
          end

          # Stroke
          vector.each_edge do |(from_x, from_y), (to_x, to_y)|
            line_float(from_x, from_y, to_x, to_y, stroke_color, false)
          end

          return self
        end

        # Draws a rectangle on the canvas, using two control points.
        #
        # @param [Integer] x0 The x-coordinate of the first control point.
        # @param [Integer] y0 The y-coordinate of the first control point.
        # @param [Integer] x1 The x-coordinate of the second control point.
        # @param [Integer] y1 The y-coordinate of the second control point.
        # @param [Integer] stroke_color The line color to use for this rectangle.
        # @param [Integer] fill_color The fill color to use for this rectangle.
        # @return [ChunkyPNG::Canvas] Itself, with the rectangle drawn.
        def rect(x0, y0, x1, y1, stroke_color = ChunkyPNG::Color::BLACK, fill_color = ChunkyPNG::Color::TRANSPARENT)

          stroke_color = ChunkyPNG::Color.parse(stroke_color)
          fill_color   = ChunkyPNG::Color.parse(fill_color)

          # Fill
          unless fill_color == ChunkyPNG::Color::TRANSPARENT
            [x0, x1].min.upto([x0, x1].max) do |x|
              [y0, y1].min.upto([y0, y1].max) do |y|
                compose_pixel(x, y, fill_color)
              end
            end
          end

          # Stroke
          line(x0, y0, x0, y1, stroke_color, false)
          line(x0, y1, x1, y1, stroke_color, false)
          line(x1, y1, x1, y0, stroke_color, false)
          line(x1, y0, x0, y0, stroke_color, false)

          return self
        end

        def circle_float(centerpoint, radius, stroke_color = ChunkyPNG::Color::BLACK, feather = 1)
          #procedure DrawDisk(png, centerx, centery, radius, feather)
          # Draw a disk on Bitmap. Bitmap must be a 256 color (pf8bit)
          # palette bitmap, and parts outside the disk will get palette
          # index 0, parts inside will get palette index 255, and in the
          # antialiased area (feather), the pixels will get values
          # inbetween.
          # ***Parameters***
          # Bitmap:
          #   The bitmap to draw on
          # CenterX, CenterY:
          #   The center of the disk (float precision). Note that [0, 0]
          #   would be the center of the first pixel. To draw in the
          #   exact middle of a 100x100 bitmap, use CenterX = 49.5 and
          #   CenterY = 49.5
          # Radius:
          #   The radius of the drawn disk in pixels (float precision)
          # Feather:
          #   The feather area. Use 1 pixel for a 1-pixel antialiased
          #   area. Pixel centers outside 'Radius + Feather / 2' become
          #   0, pixel centers inside 'Radius - Feather/2' become 255.
          #   Using a value of 0 will yield a bilevel image.
          # Copyright (c) 2003 Nils Haeck M.Sc. www.simdesign.nl
          # http://www.simdesign.nl/tips/tip002.html
          #var
          # x, y: integer;
          #LX, RX, LY, RY: integer;
          #Fact: integer;
          #RPF2, RMF2: single;
          #P: PByteArray;
          #SqY, SqDist: single;
          #sqX: array of single;
          #feather =  radius * 0.05

          #return if centerpoint.y  < 0 - radius || centerpoint.y > height + radius || centerpoint.x < 0 - radius || centerpoint.x > width + radius


          centerx = centerpoint.x
          centery = centerpoint.y
          # Determine some helpful values (singles)
          rpf2 = (radius + feather/2)**2
          rmf2 = (radius - feather/2)**2

          # Determine bounds:
          lx = [(centerx - rpf2).floor, 0].max
          rx = [(centerx + rpf2).ceil, width - 1].min
          ly = [(centery - rpf2).floor, 0].max
          ry = [(centery + rpf2).ceil, height - 1].min

          # Optimization run: find squares of X first
          sqX=[]
          #set_length(sqX, rx - lx + 1)
          for n in 0..(rx-lx+1)
            sqX[n]=nil
          end

          for x in lx..rx
            sqX[x - lx] = (x - centerx)**2
          end

          # Loop through Y values
          for y in ly..ry
            sqY = (y - centery)**2

            # Loop through X values
            for x in lx..rx
              # determine squared distance from center for this pixel
              sqdist = sqY.to_f + sqX[x - lx].to_f

              # inside inner circle? Most often..
              if sqdist < rmf2
                # inside the inner circle.. just give the scanline the
                # new color
                #p[x] = 255
                plot(x, y, 255, stroke_color)
              elsif sqdist < rpf2 # inside outer circle?
                # We are inbetween the inner and outer bound, now
                # mix the color
                fact = (((radius - Math.sqrt(sqdist)) * 2 / feather) * 127.5 + 127.5).round
                # just in case limit to [0, 255]
                #p[x] = [0, [fact, 255].min].max`
                #plot(x, y, SkalpHatch.max(0, SkalpHatch.min(fact, 255))/255, stroke_color)
                plot(x, y, fact, stroke_color)
              else
                #p[x] = 0
                #plot(x, y, 0, stroke_color) #plotpoints outside  of circle
              end
            end
          end
        end

        # Draws a circle on the canvas.
        #
        # @param [Integer] x0 The x-coordinate of the center of the circle.
        # @param [Integer] y0 The y-coordinate of the center of the circle.
        # @param [Integer] radius The radius of the circle from the center point.
        # @param [Integer] stroke_color The color to use for the line.
        # @param [Integer] fill_color The color to use that fills the circle.
        # @return [ChunkyPNG::Canvas] Itself, with the circle drawn.
        def circle(x0, y0, radius, stroke_color = ChunkyPNG::Color::BLACK, fill_color = ChunkyPNG::Color::TRANSPARENT)
          x0 = x0.to_i  #TODO implement new anti aliased circle algorithm
          y0 = y0.to_i

          stroke_color = ChunkyPNG::Color.parse(stroke_color)
          fill_color   = ChunkyPNG::Color.parse(fill_color)

          f = 1 - radius
          ddF_x = 1
          ddF_y = -2 * radius
          x = 0
          y = radius

          compose_pixel(x0, y0 + radius, stroke_color)
          compose_pixel(x0, y0 - radius, stroke_color)
          compose_pixel(x0 + radius, y0, stroke_color)
          compose_pixel(x0 - radius, y0, stroke_color)

          lines = [radius - 1] unless fill_color == ChunkyPNG::Color::TRANSPARENT

          while x < y

            if f >= 0
              y -= 1
              ddF_y += 2
              f += ddF_y
            end

            x += 1
            ddF_x += 2
            f += ddF_x

            unless fill_color == ChunkyPNG::Color::TRANSPARENT
              lines[y] = lines[y] ? [lines[y], x - 1].min : x - 1
              lines[x] = lines[x] ? [lines[x], y - 1].min : y - 1
            end

            compose_pixel(x0 + x, y0 + y, stroke_color)
            compose_pixel(x0 - x, y0 + y, stroke_color)
            compose_pixel(x0 + x, y0 - y, stroke_color)
            compose_pixel(x0 - x, y0 - y, stroke_color)

            unless x == y
              compose_pixel(x0 + y, y0 + x, stroke_color)
              compose_pixel(x0 - y, y0 + x, stroke_color)
              compose_pixel(x0 + y, y0 - x, stroke_color)
              compose_pixel(x0 - y, y0 - x, stroke_color)
            end
          end

          unless fill_color == ChunkyPNG::Color::TRANSPARENT
            lines.each_with_index do |length, y|
              line(x0 - length, y0 - y, x0 + length, y0 - y, fill_color) if length > 0
              line(x0 - length, y0 + y, x0 + length, y0 + y, fill_color) if length > 0 && y > 0
            end
          end

          return self
        end

        private

        # Calculates the binomial coefficient for n over k.
        #
        # @param [Integer] n first parameter in coeffient (the number on top when looking at the mathematic formula)
        # @param [Integer] k k-element, second parameter in coeffient (the number on the bottom when looking at the mathematic formula)
        # @return [Integer] The binomial coeffcient of (n,k)
        def binomial_coefficient(n, k)
          return  1 if n == k || k == 0
          return  n if k == 1
          return -1 if n < k

          # calculate factorials
          fact_n = (2..n).inject(1) { |carry, i| carry * i }
          fact_k = (2..k).inject(1) { |carry, i| carry * i }
          fact_n_sub_k = (2..(n - k)).inject(1) { |carry, i| carry * i }

          fact_n / (fact_k * fact_n_sub_k)
        end
      end
    end
  end
end
