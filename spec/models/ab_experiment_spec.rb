require "rails_helper"

RSpec.describe AbExperiment do
  let(:controller) { ApplicationController.new }
  let(:user) { double }

  describe ".register_conversions_for" do
    it "forwards delegates to Converter.call" do
      allow(described_class::GoalConversionHandler).to receive(:call)
      described_class.register_conversions_for(user: user, goal: "goal")
      expect(described_class::GoalConversionHandler)
        .to have_received(:call).with(user: user, goal: "goal", experiments: FieldTest.config["experiments"])
    end
  end

  describe ".get_feed_variant_for" do
    before do
      allow(controller).to receive(:field_test).with(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT,
                                                     participant: user).and_return("special")
    end

    it "returns an inquirable string" do
      result = described_class.get_feed_variant_for(user: user, controller: controller)
      expect(result).to eq("special")
      expect(result).to be_special
    end
  end

  describe ".get" do
    before do
      allow(controller).to receive(:field_test).with(AbExperiment::CURRENT_FEED_STRATEGY_EXPERIMENT,
                                                     participant: user).and_return("special")
    end

    context "with :feed_strategy_round_3 experiment" do
      it "repurposes the :feed_strategy experiment" do
        expect(described_class.get(experiment: described_class::CURRENT_FEED_STRATEGY_EXPERIMENT,
                                   user: user,
                                   controller: controller,
                                   default_value: "default")).to eq("special")
      end
    end

    context "with :feed_strategy experiment" do
      before do
        allow(controller).to receive(:field_test).with(:feed_strategy, participant: user).and_return("special")
      end

      let(:experiment) { :feed_strategy }

      it "returns an inquirable string" do
        result = described_class.get(experiment: :feed_strategy,
                                     user: user,
                                     controller: controller,
                                     default_value: "default")
        expect(result).to eq("special")
        expect(result).to be_special
      end

      it "allows for an config override" do
        result = described_class.get(experiment: :feed_strategy,
                                     user: user,
                                     controller: controller,
                                     default_value: "special",
                                     config: { "AB_EXPERIMENT_FEED_STRATEGY" => "not_special" })
        expect(result).to eq("not_special")
        expect(result).to be_not_special
      end

      it "returns the default value when the FeatureFlipper is off" do
        allow(FeatureFlag).to receive(:accessible?).with(:ab_experiment_feed_strategy).and_return(false)

        result = described_class.get(experiment: :feed_strategy,
                                     user: user,
                                     controller: controller,
                                     default_value: "special",
                                     config: { "AB_EXPERIMENT_FEED_STRATEGY" => "not_special" })
        expect(result).to eq("special")
        expect(result).to be_special
      end
    end
  end
end
