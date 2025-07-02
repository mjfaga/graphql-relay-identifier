[![Gem Version](https://badge.fury.io/rb/graphql_relay_identifier.svg)](https://badge.fury.io/rb/graphql_relay_identifier)
[![Build](https://github.com/mjfaga/graphql_relay_identifier/actions/workflows/main.yml/badge.svg)](https://github.com/mjfaga/graphql_relay_identifier/actions/workflows/main.yml)

# GraphQL::Relay::Identifier

This gem provides an implementation the Relay Global Object Identification specification in Ruby,
ensuring compatibility with GraphQL Federation. It allows you to define and resolve global
identifiers for your GraphQL objects, making it easier to work with Relay and GraphQL Federation in
your applications.

For more information on the Relay Global Object Identification specification, check out:

- The [Relay Global Object Identification](https://relay.dev/graphql/objectidentification.htm)
  documentation.
- The latter half of my talk on
  [Building Relay Spec Compliance in Federation](https://www.apollographql.com/events/building-relay-spec-compliance-in-federation).

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'graphql_relay_identifier'
```

And then execute:

```bash
bundle install
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install graphql_relay_identifier
```

## Usage

1. Update your schema to overide the `id_from_object` and `object_from_id` methods and use the
   `GraphQL::Relay::Identifier::GlobalObjectIdentifier` module to handle global identifiers.

   ```ruby
   class ApplicationSchema < GraphQL::Schema
     # ... other configuration

     def self.id_from_object(object, type, _query_ctx)
       GraphQL::Relay::Identifier::GlobalObjectIdentifier.to_relay_id(object, type)
     end

     def self.object_from_id(node_id, _query_ctx)
       GraphQL::Relay::Identifier::GlobalObjectIdentifier.from_relay_id(node_id)
     end
   end
   ```

2. _RECOMMENDED_: Set the `GraphQL::Schema::UniqueWithinType.default_id_separator` to a `:` (colon).
   This is used to deliminate the GraphQL type name from the identifier fields in the global object
   identifier.

   ```ruby
   # config/initializers/graphql.rb
    GraphQL::Schema::UniqueWithinType.default_id_separator = ':'
   ```

3. _ADVANCED CONFIGURATION_: Introduce an initializer to set up any custom identifier configurations
   for your models and types, as needed.

   _NOTE: This is only necessary if you have models that do not use the default `id` field as their
   primary key._

   ```ruby
   # config/initializers/graphql_relay_identifier.rb
   GraphQL::Relay::Identifier::GlobalObjectIdentifier.add_identifier 'BlogPost', :slug
   GraphQL::Relay::Identifier::GlobalObjectIdentifier.add_identifier 'ModelWithComplexKey', :field1, :field2,
   GraphQL::Relay::Identifier::GlobalObjectIdentifier.add_identifier 'ModelWithVirtualAttribute', :id, virtual_attribute_names: %i[some_virtual_attribute]
   ```

### `GraphQL::Relay::Identifier::GlobalObjectIdentifier.add_identifier`

This method allows you to define a global identifier for a specific model when the default (`id`) is
not suitable.

You can specify one or more fields to be used as the identifier, and optionally, you can define
virtual attributes that should be included in the identifier. Virtual attributes are not persisted
in the database but play a role in how a model instance behaves and is identified.

### Format of a GraphQL Relay Identifier

Suppose you have a model `BlogPost` with a `slug` field that is used as the primary key for the
model. Assuming the GraphQL Type for this model is `BlogPost`, the identifier for a specific
instance of this model with a `slug` value of `my-awesome-blog-post` would be represented as:

```
Base64.strict_encode64('BlogPost:{"v":1,"klass":"BlogPost","slug":"my-awesome-blog-post"}')
```

This identifier can be used in GraphQL queries to uniquely identify the `BlogPost` instance with:

- An encoding version of 1 (the default version)
- A model name of `BlogPost`
- A single field `slug` with the unique value `my-awesome-blog-post`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run
the tests. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`, which
will create a git tag for the version, push git commits and the created tag, and push the `.gem`
file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/mjfaga/graphql_relay_identifier. This project is intended to be a safe, welcoming
space for collaboration, and contributors are expected to adhere to the
[code of conduct](https://github.com/mjfaga/graphql_relay_identifier/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](./LICENSE.txt).

## Code of Conduct

Everyone interacting in the GraphQL::Relay::Identifier project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/mjfaga/graphql_relay_identifier/blob/main/CODE_OF_CONDUCT.md).
