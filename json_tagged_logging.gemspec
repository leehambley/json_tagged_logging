require_relative 'lib/json_tagged_logging/version'

Gem::Specification.new do |spec|
  spec.name          = "json_tagged_logging"
  spec.version       = JsonTaggedLogging::VERSION
  spec.authors       = ["Lee Hambley"]
  spec.email         = ["lee.hambley@gmail.com"]

  spec.summary       = %q{Modified ActiveSupport::TaggedLogging, works with JSON}
  spec.description   = %q{Copy of ActiveSupport::TaggedLogging for structured logging with JSON. Works with lograge. I don't support this, don't use it.}
  spec.homepage      = "https://github.com/leehambley/json_tagged_logging"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "http://nowhere.com/i/do/not/support/this/gem"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/leehambley/json_tagged_logging"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
