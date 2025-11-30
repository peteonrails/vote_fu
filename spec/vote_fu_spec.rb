# frozen_string_literal: true

RSpec.describe VoteFu do
  it "has a version number" do
    expect(VoteFu::VERSION).not_to be_nil
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(VoteFu::Configuration)
    end

    it "memoizes the configuration" do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }
        .to yield_with_args(VoteFu::Configuration)
    end

    it "allows setting configuration options" do
      described_class.configure do |config|
        config.allow_recast = false
        config.hot_ranking_gravity = 2.0
      end

      expect(described_class.configuration.allow_recast).to be false
      expect(described_class.configuration.hot_ranking_gravity).to eq 2.0
    end
  end

  describe ".reset_configuration!" do
    it "resets to default values" do
      described_class.configure { |c| c.allow_recast = false }
      described_class.reset_configuration!

      expect(described_class.configuration.allow_recast).to be true
    end
  end
end
