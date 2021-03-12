# frozen_string_literal: true

require "rails_helper"

RSpec.describe Complexity, type: :model do
  let(:complexity) { build(:complexity) }
  let(:event_type) {
    {
    string_value: "complexity-of-need.level.changed",
    data_type: "String",
  }
  }
  let(:message) {
    {
      offenderNo: complexity.offender_no,
      level: complexity.level,
    }.to_json
  }
  let(:version) {
    {
      string_value: "1",
      data_type: "Number",
    }
  }
  let(:url) {
    {
      string_value: Rails.application.routes.url_helpers.complexity_of_need_single_url(complexity.offender_no),
      data_type: "String",
    }
  }
  let(:topic) { instance_double("topic", publish: nil) }

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  it "sends a complexity SNS message after save" do
    complexity.save!
    expect(topic).to have_received(:publish).with(
      message: message,
      message_attributes: hash_including(eventType: event_type, version: version, detailURL: url),
      )
  end

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

  describe ".latest_for_offenders" do
    subject { described_class.latest_for_offenders(offenders) }

    let(:offenders) { [offender_with_multiple_levels, offender_with_one_level, offender_without_levels] }
    let(:offender_with_multiple_levels) { "Offender1" }
    let(:offender_with_one_level) { "Offender2" }
    let(:offender_without_levels) { "Offender3" }
    let(:some_other_offender) { "Offender4" } # we don't want get this offender's complexity level

    before do
      # Create 10 entries for offender_with_multiple_levels
      create_list(:complexity, 10, :random_date, offender_no: offender_with_multiple_levels)

      # Create 1 entry for offender_with_one_level
      create(:complexity, :random_date, offender_no: offender_with_one_level)

      # Create nothing for offender_without_levels

      # Create entries for some_other_offender
      create_list(:complexity, 5, :random_date, offender_no: some_other_offender)
    end

    it "only returns offenders who have a Complexity level" do
      returned_offenders = subject.map(&:offender_no)
      expect(returned_offenders).not_to include(offender_without_levels)
      expect(returned_offenders).to contain_exactly(offender_with_multiple_levels, offender_with_one_level)
    end

    it "returns the latest/current Complexity level for each offender" do
      offenders.each do |offender|
        most_recent = described_class.where(offender_no: offender).order(created_at: :desc).limit(1)
        actual = subject.select { |complexity| complexity.offender_no == offender }
        expect(actual).to eq(most_recent)
      end
    end
  end
end
