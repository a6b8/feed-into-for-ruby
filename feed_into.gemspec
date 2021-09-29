# frozen_string_literal: true

require_relative "lib/feed_into/version"

Gem::Specification.new do |spec|
  spec.name          = "feed_into"
  spec.version       = FeedInto::VERSION
  spec.authors       = ["a6b8"]
  spec.email         = ["hello@13plus4.com"]

  spec.summary       = "Merge multiple different data streams into a custom structure."
  spec.description   = "Merge multiple different data streams into a custom structure. Also easy to expand by a custom module system."
  spec.homepage      = "https://github.com/a6b8/feed-parser-for-ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/a6b8/feed-parser-for-ruby"
  spec.metadata["changelog_uri"] = "https://raw.githubusercontent.com/a6b8/feed-parser-for-ruby/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'net/http'
  spec.add_dependency 'time'
  spec.add_dependency 'tzinfo'
  spec.add_dependency 'active_support/core_ext/hash'
  spec.add_dependency 'cgi'
  spec.add_dependency 'json'
  spec.add_dependency 'rss'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
