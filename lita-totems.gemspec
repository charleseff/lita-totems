Gem::Specification.new do |spec|
  spec.name          = "lita-totems"
  spec.version       = "0.0.1"
  spec.authors       = ["Charles Finkel"]
  spec.email         = ["cf@dropbox.com"]
  spec.description   = %q{Totems handler for Lita)}
  spec.summary       = %q{Adds support to Lita for Totems}
  spec.homepage      = "TODO: Add a homepage"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", "~> 2.3"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", ">= 2.14"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end