# frozen_string_literal: true

require "rails_helper"

RSpec.describe Complexity, type: :model do
  let(:complexity) { build(:complexity) }
  let(:event_type) do
    {
      string_value: "complexity-of-need.level.changed",
      data_type: "String",
    }
  end
  let(:message) do
    {
      offenderNo: complexity.offender_no,
      level: complexity.level,
      active: true,
    }.to_json
  end
  let(:version) do
    {
      string_value: "1",
      data_type: "Number",
    }
  end
  let(:url) do
    {
      string_value: Rails.application.routes.url_helpers.complexity_of_need_single_url(complexity.offender_no),
      data_type: "String",
    }
  end
  let(:topic) { instance_double("topic", publish: nil) }

  before do
    allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)
  end

  it "sends a complexity SNS message after save" do
    complexity.save!
    expect(topic).to have_received(:publish).with(
      message:,
      message_attributes: hash_including(eventType: event_type, version:, detailURL: url),
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
          expect(build(:complexity, level:)).to be_valid
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

    let(:offenders) { [offender1, offender2, offender3, offender4] }

    let(:offender1) { "A0001BC" }
    let(:offender2) { "A0002BC" }
    let(:offender3) { "A0003BC" }
    let(:offender4) { "A0004BC" }
    let(:offender5) { "A0005BC" }

    before do
      # Offender 1 has multiple historical levels, but currently no level
      create(:complexity, :inactive, offender_no: offender1, created_at: Time.zone.today - 5.days)
      create(:complexity, :inactive, offender_no: offender1, created_at: Time.zone.today - 4.days)
      create(:complexity,            offender_no: offender1, created_at: Time.zone.today - 3.days)
      create(:complexity, :inactive, offender_no: offender1, created_at: Time.zone.today - 2.days)

      # Offender 2 has multiple historical levels, and a current level
      create(:complexity, :inactive, offender_no: offender2, created_at: Time.zone.today - 5.days)
      create(:complexity, :inactive, offender_no: offender2, created_at: Time.zone.today - 4.days)
      create(:complexity,            offender_no: offender2, created_at: Time.zone.today - 3.days)
      create(:complexity,            offender_no: offender2, created_at: Time.zone.today - 2.days, notes: "2 current")

      # Offender 3 has one level, which is current
      create(:complexity,            offender_no: offender3, created_at: Time.zone.today - 5.days, notes: "3 current")

      # Offender 4 has never had a level

      # Offender 5 has one level, which is current, but is not part of the lookup
      create(:complexity,            offender_no: offender5, created_at: Time.zone.today - 5.days)
    end

    it "only returns offenders who have a Complexity level" do
      returned_offenders = subject.map(&:offender_no)
      expect(returned_offenders).to contain_exactly(offender2, offender3)
    end

    it "returns the latest/current Complexity level for each offender" do
      returned_offenders = subject.map(&:notes)
      expect(returned_offenders).to contain_exactly("2 current", "3 current")
    end
  end
end
