# frozen_string_literal: true

require "graphql"

module GraphQL
  module Relay
    module Identifier
      # GlobalObjectIdentifier is a utility class that provides a way to create and manage unique identifiers for
      # entities implementing a Node in a GraphQL schema.
      #
      # This implementation is ORM-agnostic but assumes certain methods like find_by! are available
      # on your model classes. You may need to customize the find method based on your actual ORM.
      class GlobalObjectIdentifier
        class << self
          private

          def identifiers
            @identifiers ||= Hash.new { |h, klass| h[klass] = Identifier.build_for(klass) }
          end

          attr_writer :identifiers
        end

        # Identifier is a class that represents a unique identifier for a specific class in the GraphQL schema.
        class Identifier
          class << self
            attr_writer :attribute_names, :virtual_attribute_names, :version

            attr_accessor :klass

            def attribute_names
              @attribute_names ||= %i[id]
            end

            def version
              @version ||= 1
            end

            def virtual_attribute_names
              @virtual_attribute_names ||= %i[]
            end
          end

          def self.as_json(object)
            attributes = attribute_names.each_with_object({}) do |key, hash|
              hash[key] = object.public_send(key)
              hash
            end
            virtual_attributes = virtual_attribute_names.each_with_object({}) do |key, hash|
              hash[key] = object.public_send(key)
              hash
            end

            {
              v: version,
              klass:,
              **attributes,
              **virtual_attributes
            }
          end

          def self.build_for(klass, *args)
            const_set(klass.gsub("::", ""), Class.new(self)).tap do |identifier_class|
              attribute_names = []
              virtual_attribute_names = []
              args.each do |attribute_name|
                if attribute_name.is_a?(Symbol)
                  attribute_names << attribute_name
                elsif attribute_name.is_a?(Hash) && attribute_name.key?(:virtual_attribute_names)
                  virtual_attr_names = attribute_name[:virtual_attribute_names]
                  virtual_attr_names = [virtual_attr_names] unless virtual_attr_names.is_a?(Array)
                  virtual_attr_names.each do |inner_attribute_name|
                    virtual_attribute_names << inner_attribute_name
                  end
                end
              end

              identifier_class.klass = klass
              identifier_class.attribute_names = attribute_names unless attribute_names.empty?
              identifier_class.virtual_attribute_names = virtual_attribute_names unless virtual_attribute_names.empty?
              identifier_class.define_attribute_methods
            end
          end

          def self.define_attribute_methods
            attribute_names.each do |attribute_name|
              define_method(attribute_name) { @hash[attribute_name.to_s] }
            end

            virtual_attribute_names.each do |attribute_name|
              define_method(attribute_name) { @hash[attribute_name.to_s] }
            end
          end

          def self.remove_for(klass)
            remove_const(klass.gsub("::", ""))
          end

          def initialize(hash)
            @hash = hash
          end

          def attributes
            self.class.attribute_names.each_with_object({}) do |key, hash|
              hash[key] = public_send(key)
              hash
            end
          end

          def find
            # Convert string class name to actual constant
            klass_constant = self.class.klass.split("::").inject(Object) do |mod, class_name|
              mod.const_get(class_name)
            end

            # This implementation assumes the class has a find_by! method that accepts
            # attributes as keyword arguments. If using a different ORM or data access
            # pattern, you'll need to customize this method.
            instance = klass_constant.find_by!(**attributes)

            # Assign virtual attributes if any exist
            unless virtual_attributes.empty?
              virtual_attributes.each do |key, value|
                instance.public_send("#{key}=", value) if instance.respond_to?("#{key}=")
              end
            end

            instance
          end

          def virtual_attributes
            self.class.virtual_attribute_names.each_with_object({}) do |key, hash|
              hash[key] = public_send(key)
              hash
            end
          end
        end

        class << self
          def add_identifier(klass, *attribute_names)
            identifiers[klass] = Identifier.build_for(klass, *attribute_names)
          end

          def from_relay_id(node_id)
            parse(node_id)&.find
          end

          def parse(node_id)
            _typename, json = GraphQL::Schema::UniqueWithinType.decode(node_id)

            return unless json

            hash = JSON.parse(json)
            klass = hash["klass"]

            identifiers[klass].new(hash)
          rescue JSON::ParserError, GraphQL::ExecutionError
            nil
          end

          def remove_identifier(klass)
            identifiers.delete(klass)
            Identifier.remove_for(klass)
          end

          def to_relay_id(object, type)
            unsafe_to_relay_id(object, graphql_name: type.graphql_name, object_class_name: object.class.name)
          end

          def unsafe_to_relay_id(object, graphql_name:, object_class_name:)
            # This allows us to get relay ids for types without having to access the GraphQL type, but without the safety
            # or consistency of the GraphQL type. Used by external callers (e.g. the API) to generate relay ids.
            GraphQL::Schema::UniqueWithinType.encode(
              graphql_name,
              identifiers[object_class_name].as_json(object).to_json
            )
          end
        end
      end
    end
  end
end
