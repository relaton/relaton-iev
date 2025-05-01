lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "relaton_iev/version"

Gem::Specification.new do |spec|
  spec.name          = "relaton-iev"
  spec.version       = RelatonIev::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "RelatonIev: manipulates IEV references to IEC 60050."
  spec.description   = "RelatonIev: manipulates IEV references to IEC 60050."
  spec.homepage      = "https://github.com/metanorma/relaton-iev"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = Gem::Requirement.new(">= 2.5.0")

  # spec.add_development_dependency "debase"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  # spec.add_development_dependency "ruby-debug-ide"
  spec.add_development_dependency "equivalent-xml", "~> 0.6"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"

  spec.add_dependency "htmlentities", "~> 4.3.4"
  spec.add_dependency "nokogiri", ">= 1.13.0"
  spec.add_dependency "relaton", ">= 1.15"
  spec.add_dependency "uuidtools"
end
