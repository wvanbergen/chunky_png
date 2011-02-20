# Define the byte-operators on a string if they're not defined (Ruby 1.8)
class String
  alias_method :getbyte, :[]    unless method_defined?(:getbyte)
  alias_method :setbyte, :[]=   unless method_defined?(:setbyte)
  alias_method :bytesize, :size unless method_defined?(:bytesize)
end
