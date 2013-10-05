require 'celluloid'

class Foo
  include Celluloid
  def do(n)
    puts "in do with #{n}"
    #Kernel.sleep 2
    sleep 2
    puts "exiting do with #{n}"
  end

  def blah
    puts 'blah'
  end
end

f = Foo.spawn
f.async.do(4)
#f.blah

f.do(5)
#f.do!
#sleep