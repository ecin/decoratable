lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "decoratable"
  spec.version       = "0.0.1"
  spec.authors       = ["ecin"]
  spec.email         = ["ecin@copypastel.com"]
  spec.description   = "Decorate your methods."
  spec.summary       = "Easily define decorations for your methods. Put a bow on it."
  spec.homepage      = "https://github.com/ecin/decoratable"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", ">= 10.0.0"
end
