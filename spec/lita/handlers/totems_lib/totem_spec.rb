require "spec_helper"

describe Lita::Handlers::TotemsLib::Totem do
  it "should have a name" do
    expect(described_class.new('foo').name).to eq('foo')
  end
end
