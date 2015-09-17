require "simplecov"
require 'timecop'
require "coveralls"
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start { add_filter "/spec/" }

require "lita-totems"
require "lita/rspec"
Lita.version_3_compatibility_mode = false
