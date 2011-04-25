module ChunkyPNG

  # Methods for doing edge detection. Current implementations include Sobel and Pre-Witt 
  # operators only
  #
  # @example
  #
  #    require 'chunky_png/edge_detect'
  #    
  #    image = ChunkyPNG::Image.from_file('filename.png')
  #    edge_detected = image.edge_detect_with(:sobel)
  #
  class Image

    SOBEL_X = [[-1,0,1], [-2,0,2], [-1,0,1]]
    SOBEL_Y = [[-1,-2,-1], [0,0,0], [1,2,1]]

    def edge_detect_with(algo=:sobel)      
      al_x, al_y = SOBEL_X, SOBEL_Y if algo == :sobel
      edge = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
      for x in 1..width-2
        for y in 1..height-2
          pixel_x = (al_x[0][0] * at(x-1,y-1)) + (al_x[0][1] * at(x,y-1)) + (al_x[0][2] * at(x+1,y-1)) +
                    (al_x[1][0] * at(x-1,y))   + (al_x[1][1] * at(x,y))   + (al_x[1][2] * at(x+1,y)) +
                    (al_x[2][0] * at(x-1,y+1)) + (al_x[2][1] * at(x,y+1)) + (al_x[2][2] * at(x+1,y+1))

          pixel_y = (al_y[0][0] * at(x-1,y-1)) + (al_y[0][1] * at(x,y-1)) + (al_y[0][2] * at(x+1,y-1)) +
                    (al_y[1][0] * at(x-1,y))   + (al_y[1][1] * at(x,y))   + (al_y[1][2] * at(x+1,y)) +
                    (al_y[2][0] * at(x-1,y+1)) + (al_y[2][1] * at(x,y+1)) + (al_y[2][2] * at(x+1,y+1))

          val = Math.sqrt((pixel_x * pixel_x) + (pixel_y * pixel_y)).ceil
          edge[x,y] = ChunkyPNG::Color.grayscale(val)
        end
      end    
      edge
    end

    private
    def at(x,y)
      ChunkyPNG::Color.to_grayscale_bytes(self[x,y]).first
    end    
  end
end
