# frozen_string_literal: true

RSpec.describe Legion::Extensions::Dissonance::Helpers::DissonanceEvent do
  let(:event) do
    described_class.new(
      belief_a_id:        'uuid-a',
      belief_b_id:        'uuid-b',
      domain:             'ethics',
      magnitude:          0.6,
      contradiction_type: :direct
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns belief_a_id' do
      expect(event.belief_a_id).to eq('uuid-a')
    end

    it 'assigns belief_b_id' do
      expect(event.belief_b_id).to eq('uuid-b')
    end

    it 'assigns domain' do
      expect(event.domain).to eq('ethics')
    end

    it 'assigns magnitude' do
      expect(event.magnitude).to eq(0.6)
    end

    it 'assigns contradiction_type' do
      expect(event.contradiction_type).to eq(:direct)
    end

    it 'starts as unresolved' do
      expect(event.resolved).to be false
    end

    it 'starts with nil resolution_strategy' do
      expect(event.resolution_strategy).to be_nil
    end

    it 'assigns timestamp as UTC Time' do
      expect(event.timestamp).to be_a(Time)
    end

    it 'clamps magnitude above 1.0' do
      ev = described_class.new(belief_a_id: 'a', belief_b_id: 'b', domain: 'd', magnitude: 1.5)
      expect(ev.magnitude).to eq(1.0)
    end

    it 'clamps magnitude below 0.0' do
      ev = described_class.new(belief_a_id: 'a', belief_b_id: 'b', domain: 'd', magnitude: -0.5)
      expect(ev.magnitude).to eq(0.0)
    end

    it 'defaults contradiction_type to :direct' do
      ev = described_class.new(belief_a_id: 'a', belief_b_id: 'b', domain: 'd', magnitude: 0.5)
      expect(ev.contradiction_type).to eq(:direct)
    end
  end

  describe '#resolve!' do
    it 'marks the event as resolved' do
      event.resolve!(:belief_revision)
      expect(event.resolved).to be true
    end

    it 'records the resolution strategy' do
      event.resolve!(:rationalization)
      expect(event.resolution_strategy).to eq(:rationalization)
    end

    it 'returns self for chaining' do
      result = event.resolve!(:avoidance)
      expect(result).to be(event)
    end

    it 'can be resolved with any valid strategy' do
      Legion::Extensions::Dissonance::Helpers::Constants::RESOLUTION_STRATEGIES.each do |strategy|
        ev = described_class.new(belief_a_id: 'a', belief_b_id: 'b', domain: 'd', magnitude: 0.5)
        ev.resolve!(strategy)
        expect(ev.resolution_strategy).to eq(strategy)
      end
    end
  end

  describe '#to_h' do
    it 'returns hash with all fields when unresolved' do
      h = event.to_h
      expect(h[:id]).to eq(event.id)
      expect(h[:belief_a_id]).to eq('uuid-a')
      expect(h[:belief_b_id]).to eq('uuid-b')
      expect(h[:domain]).to eq('ethics')
      expect(h[:magnitude]).to eq(0.6)
      expect(h[:contradiction_type]).to eq(:direct)
      expect(h[:resolved]).to be false
      expect(h[:resolution_strategy]).to be_nil
      expect(h[:timestamp]).to be_a(Time)
    end

    it 'reflects resolved state in to_h' do
      event.resolve!(:belief_revision)
      h = event.to_h
      expect(h[:resolved]).to be true
      expect(h[:resolution_strategy]).to eq(:belief_revision)
    end
  end
end
