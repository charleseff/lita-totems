Gem::Specification.new do |spec|
  spec.name          = "lita-totems"
  spec.version       = "0.1.0"
  spec.authors       = ["Charles Finkel"]
  spec.email         = ["cf@dropbox.com"]
  spec.description   = %q{Totems handler for Lita)}
  spec.summary       = %q{Adds support to Lita for Totems}
  spec.homepage      = "https://github.com/charleseff/lita-totems"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", "~> 2.4"
  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "chronic_duration"
  spec.add_runtime_dependency "redis-semaphore"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.14"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "coveralls"
end
