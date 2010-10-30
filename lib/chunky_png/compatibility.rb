
class String
  alias_method :getbyte, :[]    unless method_defined?(:getbyte)
  alias_method :setbyte, :[]=   unless method_defined?(:setbyte)
  alias_method :bytesize, :size unless method_defined?(:bytesize)
end

class Object
  unless method_defined?(:tap)
    def tap(&block)
      yield(self) if block_given?
      return self
    end
  end
end
