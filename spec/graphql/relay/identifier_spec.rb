# frozen_string_literal: true

RSpec.describe GraphQL::Relay::Identifier do
  it "has a version number" do
    expect(GraphQL::Relay::Identifier::VERSION).not_to be_nil
  end
end
