# frozen_string_literal: true

require "securerandom"

RSpec.describe GraphQL::Relay::Identifier::GlobalObjectIdentifier do
  before do
    GraphQL::Schema::UniqueWithinType.default_id_separator = ":"
  end

  describe "when no custom mapping exists" do
    before do
      stub_const(
        "SomeDatabaseModel",
        Class.new do
          def id
            @id ||= SecureRandom.uuid
          end

          def self.find_by!(id:)
            new.tap { |obj| obj.instance_variable_set(:@id, id) }
          end
        end
      )
    end

    let(:schema_class) do
      Class.new(GraphQL::Schema) do
        const_set(:SomeDatabaseModelType, Class.new(GraphQL::Schema::Object))
      end
    end

    describe ".to_relay_id" do
      subject(:result) { described_class.to_relay_id(object, type) }

      let(:object) { SomeDatabaseModel.new }
      let(:type) { schema_class::SomeDatabaseModelType }
      let(:object_json) { { v: 1, klass: SomeDatabaseModel.name, id: object.id }.to_json }
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "produces a base64 encoded string with a : delimited graphql type name & jsonified klass + id" do
        expect(result).to eq(relay_id)
      end
    end

    describe ".unsafe_to_relay_id" do
      subject(:result) do
        described_class.unsafe_to_relay_id(object, graphql_name: type.graphql_name,
                                                   object_class_name: object.class.name)
      end

      let(:object) { SomeDatabaseModel.new }
      let(:type) { schema_class::SomeDatabaseModelType }
      let(:object_json) { { v: 1, klass: SomeDatabaseModel.name, id: object.id }.to_json }
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "produces a base64 encoded string with a : delimited graphql type name & jsonified klass + id" do
        expect(result).to eq(relay_id)
      end
    end

    describe ".from_relay_id" do
      subject(:result) { described_class.from_relay_id(relay_id) }

      let(:object) { SomeDatabaseModel.new }
      let(:type) { schema_class::SomeDatabaseModelType }
      let(:object_json) { { v: 1, klass: SomeDatabaseModel.name, id: object.id }.to_json }
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "decodes the base64 encoded string and returns the object" do
        expect(result.id).to eq(object.id)
      end

      describe "when the relay_id is invalid" do
        let(:relay_id) { SecureRandom.uuid }

        it "returns nil" do
          expect(result).to be_nil
        end
      end

      describe "when the relay_id does not contain a json object" do
        let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{SecureRandom.uuid}") }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end

    describe ".parse" do
      subject(:result) { described_class.parse(relay_id) }

      let(:object) { SomeDatabaseModel.new }
      let(:type) { schema_class::SomeDatabaseModelType }
      let(:object_json) { { v: 1, klass: SomeDatabaseModel.name, id: object.id }.to_json }
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "decodes the base64 encoded string and returns an identifier object" do
        expect(result).to be_a(described_class::Identifier::SomeDatabaseModel)
        expect(result.attributes.keys).to eq(%i[id])
        expect(result.id).to eq(object.id)
      end

      describe "when the relay_id is invalid" do
        let(:relay_id) { SecureRandom.uuid }

        it "returns nil" do
          expect(result).to be_nil
        end
      end

      describe "when the relay_id does not contain a json object" do
        let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{SecureRandom.uuid}") }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end
  end

  describe "when there is a custom mapping" do
    before do
      stub_const(
        "SomeDatabaseModelWithCustomMapping",
        Class.new do
          def id
            @id ||= SecureRandom.uuid
          end

          def initialize(**args)
            # @name = name
            # @other = other
          end

          attr_accessor :name
          attr_writer :other

          def other
            @other || false
          end

          def self.find_by!(name:)
            new.tap do |obj|
              obj.name = name
            end
          end
        end
      )

      described_class.add_identifier SomeDatabaseModelWithCustomMapping.name, :name,
                                     virtual_attribute_names: %i[other]
    end

    after do
      described_class.remove_identifier SomeDatabaseModelWithCustomMapping.name
    end

    let(:schema_class) do
      Class.new(GraphQL::Schema) do
        const_set(:SomeDatabaseModelWithCustomMappingType, Class.new(GraphQL::Schema::Object))
      end
    end

    describe ".to_relay_id" do
      subject(:result) { described_class.to_relay_id(object, type) }

      let(:object) do
        SomeDatabaseModelWithCustomMapping.new.tap do |obj|
          obj.name = "My model"
          obj.other = true
        end
      end
      let(:type) { schema_class::SomeDatabaseModelWithCustomMappingType }
      let(:object_json) do
        { v: 1, klass: SomeDatabaseModelWithCustomMapping.name, name: object.name, other: object.other }.to_json
      end
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "produces a base64 encoded string with a : delimited graphql type name & jsonified klass + custom mapping attributes" do
        expect(result).to eq(relay_id)
      end
    end

    describe ".from_relay_id" do
      subject(:result) { described_class.from_relay_id(relay_id) }

      let(:object) do
        SomeDatabaseModelWithCustomMapping.new.tap do |obj|
          obj.name = "My model"
          obj.other = true
        end
      end
      let(:type) { schema_class::SomeDatabaseModelWithCustomMappingType }
      let(:object_json) do
        { v: 1, klass: SomeDatabaseModelWithCustomMapping.name, name: object.name, other: object.other }.to_json
      end
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "decodes the base64 encoded string and returns the object" do
        expect(result).to be_a(SomeDatabaseModelWithCustomMapping)
        expect(result.name).to eq(object.name)
        expect(result.other).to eq(object.other)
      end

      describe "when the relay_id is invalid" do
        let(:relay_id) { SecureRandom.uuid }

        it "returns nil" do
          expect(result).to be_nil
        end
      end

      describe "when the relay_id does not contain a json object" do
        let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{SecureRandom.uuid}") }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end

    describe ".parse" do
      subject(:result) { described_class.parse(relay_id) }

      let(:other) { true }
      let(:object) do
        SomeDatabaseModelWithCustomMapping.new.tap do |obj|
          obj.name = "My model"
          obj.other = other
        end
      end
      let(:type) { schema_class::SomeDatabaseModelWithCustomMappingType }
      let(:object_json) { { v: 1, klass: SomeDatabaseModelWithCustomMapping.name, name: object.name, other: }.to_json }
      let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{object_json}") }

      it "decodes the base64 encoded string and returns an identifer object with custom attributes" do
        expect(result).to be_a(described_class::Identifier::SomeDatabaseModelWithCustomMapping)
        expect(result.attributes.keys).to eq(%i[name])
        expect(result.virtual_attributes.keys).to eq(%i[other])
        expect(result.name).to eq(object.name)
        expect(result.other).to eq(object.other)
      end

      describe "when the relay_id is invalid" do
        let(:relay_id) { SecureRandom.uuid }

        it "returns nil" do
          expect(result).to be_nil
        end
      end

      describe "when the relay_id does not contain a json object" do
        let(:relay_id) { Base64.strict_encode64("#{type.graphql_name}:#{SecureRandom.uuid}") }

        it "returns nil" do
          expect(result).to be_nil
        end
      end
    end
  end
end
