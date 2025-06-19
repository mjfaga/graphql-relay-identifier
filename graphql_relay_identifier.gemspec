# frozen_string_literal: true

require_relative "lib/graphql/relay/identifier/version"

Gem::Specification.new do |spec|
  spec.name = "graphql_relay_identifier"
  spec.version = GraphQL::Relay::Identifier::VERSION
  spec.authors = ["Mark Faga"]
  spec.email = ["mjfaga@gmail.com"]

  spec.summary = "A GraphQL Relay Global Object Identification implementation for Ruby that is Federation compatible."
  spec.description = "This gem provides an implementation the Relay Global Object Identification specification in Ruby, ensuring compatibility with GraphQL Federation. It allows you to define and resolve global identifiers for your GraphQL objects, making it easier to work with Relay and Federation in your applications."
  spec.homepage = "https://github.com/mjfaga/graphql_relay_identifier"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mjfaga/graphql_relay_identifier"
  spec.metadata["changelog_uri"] = "https://github.com/mjfaga/graphql_relay_identifier/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/mjfaga/graphql_relay_identifier/issues"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).select do |f|
      f.start_with?(*%w[lib/ sig/ CHANGELOG.md LICENSE README.md])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "graphql", "~> 2.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rspec"
end
