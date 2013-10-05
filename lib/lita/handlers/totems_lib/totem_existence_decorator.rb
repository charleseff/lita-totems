require 'method_decorators'

class TotemExistenceDecorator < MethodDecorators::Decorator
  def call(wrapped, this, *args, &blk)
    puts "HELLO"
    wrapped.call(*args, &blk)
    #end
  end

end


class Foo
  extend MethodDecorators

  +TotemExistenceDecorator

  def blah
    puts "in blah"
  end
end

Foo.new.blah