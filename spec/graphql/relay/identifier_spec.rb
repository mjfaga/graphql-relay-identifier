# frozen_string_literal: true

RSpec.describe Graphql::Relay::Identifier do
  it "has a version number" do
    expect(Graphql::Relay::Identifier::VERSION).not_to be_nil
  end
end
