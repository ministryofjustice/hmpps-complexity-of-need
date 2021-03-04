# frozen_string_literal: true

require "rails_helper"

RSpec.describe Complexity, type: :model do
  describe "VALID_LEVELS" do
    it "is array: low, medium and high" do
      expect(described_class::VALID_LEVELS).to eq(%w[low medium high])
    end
  end

  describe "validation" do
    describe "#level" do
      it "can only be: low, medium or high" do
        described_class::VALID_LEVELS.each do |level|
          expect(build(:complexity, level: level)).to be_valid
        end

        %w[any other value].each do |bad_level|
          expect(build(:complexity, level: bad_level)).not_to be_valid
        end
      end

      it "cannot be blank" do
        expect(build(:complexity, level: nil)).not_to be_valid
        expect(build(:complexity, level: "")).not_to be_valid
      end
    end

    describe "#offender_no" do
      it "cannot be blank" do
        expect(build(:complexity, offender_no: nil)).not_to be_valid
        expect(build(:complexity, offender_no: "")).not_to be_valid
      end
    end
  end
end
