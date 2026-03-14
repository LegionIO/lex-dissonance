# frozen_string_literal: true

RSpec.describe Legion::Extensions::Dissonance::Helpers::DissonanceModel do
  subject(:model) { described_class.new }

  describe '#initialize' do
    it 'starts with empty beliefs' do
      expect(model.beliefs).to be_empty
    end

    it 'starts with empty events' do
      expect(model.events).to be_empty
    end

    it 'starts with zero stress' do
      expect(model.stress).to eq(0.0)
    end
  end

  describe '#add_belief' do
    it 'adds a belief to the model' do
      model.add_belief(domain: 'ethics', content: 'honesty matters', confidence: 0.8, importance: :core)
      expect(model.beliefs.size).to eq(1)
    end

    it 'returns the new belief and empty events for first belief in domain' do
      result = model.add_belief(domain: 'ethics', content: 'honesty matters')
      expect(result[:belief]).to be_a(Legion::Extensions::Dissonance::Helpers::Belief)
      expect(result[:new_dissonance_events]).to be_empty
    end

    it 'detects contradiction between beliefs in the same domain' do
      model.add_belief(domain: 'safety', content: 'always ask permission')
      result = model.add_belief(domain: 'safety', content: 'act autonomously')
      expect(result[:new_dissonance_events].size).to eq(1)
    end

    it 'does not detect contradiction for same content' do
      model.add_belief(domain: 'safety', content: 'always ask permission')
      result = model.add_belief(domain: 'safety', content: 'always ask permission')
      expect(result[:new_dissonance_events]).to be_empty
    end

    it 'does not create duplicate contradiction events for the same pair' do
      model.add_belief(domain: 'safety', content: 'always ask permission')
      result1 = model.add_belief(domain: 'safety', content: 'act autonomously')
      ev_id = result1[:new_dissonance_events].first.id
      # Artificially call detect_contradictions again — no new events since pair is tracked
      new_evs = model.detect_contradictions
      expect(new_evs).to be_empty
      expect(model.events.size).to eq(1)
      expect(model.events.key?(ev_id)).to be true
    end

    it 'does not create contradiction across different domains' do
      model.add_belief(domain: 'ethics', content: 'be transparent')
      result = model.add_belief(domain: 'safety', content: 'act differently')
      expect(result[:new_dissonance_events]).to be_empty
    end

    it 'stores the belief with the correct importance weight' do
      result = model.add_belief(domain: 'ethics', content: 'test', importance: :significant)
      expect(result[:belief].importance).to eq(:significant)
    end
  end

  describe '#detect_contradictions' do
    it 'returns empty array when no contradictions exist' do
      model.add_belief(domain: 'ethics', content: 'honesty matters')
      expect(model.detect_contradictions).to be_empty
    end

    it 'finds untracked contradictions among existing beliefs' do
      b1 = Legion::Extensions::Dissonance::Helpers::Belief.new(domain: 'ethics', content: 'be honest')
      b2 = Legion::Extensions::Dissonance::Helpers::Belief.new(domain: 'ethics', content: 'deceive when needed')
      model.beliefs[b1.id] = b1
      model.beliefs[b2.id] = b2
      new_events = model.detect_contradictions
      expect(new_events.size).to eq(1)
    end

    it 'does not re-detect already tracked contradictions' do
      model.add_belief(domain: 'ethics', content: 'tell truth')
      model.add_belief(domain: 'ethics', content: 'lie sometimes')
      model.detect_contradictions
      second_run = model.detect_contradictions
      expect(second_run).to be_empty
    end
  end

  describe '#resolve' do
    let(:event_id) do
      model.add_belief(domain: 'ethics', content: 'be honest')
      result = model.add_belief(domain: 'ethics', content: 'deceive when useful')
      result[:new_dissonance_events].first.id
    end

    it 'returns the resolved event' do
      event = model.resolve(event_id, strategy: :belief_revision)
      expect(event).to be_a(Legion::Extensions::Dissonance::Helpers::DissonanceEvent)
      expect(event.resolved).to be true
    end

    it 'reduces stress after belief_revision resolution' do
      model.add_belief(domain: 'ethics', content: 'be honest')
      result = model.add_belief(domain: 'ethics', content: 'deceive when useful')
      ev_id = result[:new_dissonance_events].first.id
      model.decay
      stress_before = model.stress
      model.resolve(ev_id, strategy: :belief_revision)
      expect(model.stress).to be < stress_before
    end

    it 'reduces stress less with rationalization than belief_revision' do
      model2 = described_class.new
      model.add_belief(domain: 'domain', content: 'claim a')
      ev_id_m1 = model.add_belief(domain: 'domain', content: 'claim b')[:new_dissonance_events].first.id
      model2.add_belief(domain: 'domain', content: 'claim a')
      ev_id_m2 = model2.add_belief(domain: 'domain', content: 'claim b')[:new_dissonance_events].first.id
      # Build up enough stress so that relief amounts differ meaningfully after clamping
      15.times { model.decay }
      15.times { model2.decay }
      model.resolve(ev_id_m1, strategy: :belief_revision)
      model2.resolve(ev_id_m2, strategy: :rationalization)
      expect(model.stress).to be < model2.stress
    end

    it 'returns nil for unknown event_id' do
      expect(model.resolve('non-existent-id', strategy: :belief_revision)).to be_nil
    end

    it 'returns nil if already resolved' do
      model.add_belief(domain: 'ethics', content: 'be honest')
      result = model.add_belief(domain: 'ethics', content: 'deceive when useful')
      ev_id = result[:new_dissonance_events].first.id
      model.resolve(ev_id, strategy: :belief_revision)
      expect(model.resolve(ev_id, strategy: :rationalization)).to be_nil
    end

    it 'returns nil for invalid strategy' do
      model.add_belief(domain: 'x', content: 'a')
      result = model.add_belief(domain: 'x', content: 'b')
      ev_id = result[:new_dissonance_events].first.id
      expect(model.resolve(ev_id, strategy: :invalid_strategy)).to be_nil
    end
  end

  describe '#stress_level' do
    it 'returns 0.0 initially' do
      expect(model.stress_level).to eq(0.0)
    end

    it 'increases after decay with unresolved events' do
      model.add_belief(domain: 'x', content: 'a')
      model.add_belief(domain: 'x', content: 'b')
      model.decay
      expect(model.stress_level).to be > 0.0
    end
  end

  describe '#domain_stress' do
    it 'returns 0.0 for a domain with no unresolved events' do
      expect(model.domain_stress('ethics')).to eq(0.0)
    end

    it 'returns positive stress for domain with unresolved events' do
      model.add_belief(domain: 'ethics', content: 'be honest')
      model.add_belief(domain: 'ethics', content: 'hide truth')
      expect(model.domain_stress('ethics')).to be > 0.0
    end

    it 'returns 0.0 for a domain after all events resolved' do
      model.add_belief(domain: 'ethics', content: 'be honest')
      result = model.add_belief(domain: 'ethics', content: 'hide truth')
      ev_id = result[:new_dissonance_events].first.id
      model.resolve(ev_id, strategy: :belief_revision)
      expect(model.domain_stress('ethics')).to eq(0.0)
    end
  end

  describe '#unresolved_events' do
    it 'returns empty list when no events' do
      expect(model.unresolved_events).to be_empty
    end

    it 'returns only unresolved events' do
      model.add_belief(domain: 'x', content: 'a')
      result = model.add_belief(domain: 'x', content: 'b')
      ev_id = result[:new_dissonance_events].first.id
      model.resolve(ev_id, strategy: :belief_revision)

      model.add_belief(domain: 'y', content: 'p')
      model.add_belief(domain: 'y', content: 'q')

      unresolved = model.unresolved_events
      expect(unresolved.all? { |ev| !ev.resolved }).to be true
    end
  end

  describe '#decay' do
    it 'increases stress when there are unresolved events' do
      model.add_belief(domain: 'x', content: 'a')
      model.add_belief(domain: 'x', content: 'b')
      initial_stress = model.stress
      model.decay
      expect(model.stress).to be > initial_stress
    end

    it 'decreases stress when there are no unresolved events' do
      model.instance_variable_set(:@stress, 0.5)
      model.decay
      expect(model.stress).to be < 0.5
    end

    it 'does not exceed STRESS_CEILING' do
      model.instance_variable_set(:@stress, 0.99)
      100.times { model.add_belief(domain: 'x', content: "belief_#{rand}") }
      model.decay
      expect(model.stress).to be <= 1.0
    end

    it 'does not go below STRESS_FLOOR' do
      model.decay
      expect(model.stress).to be >= 0.0
    end

    it 'returns the current stress value' do
      result = model.decay
      expect(result).to eq(model.stress)
    end
  end

  describe '#to_h' do
    it 'returns a snapshot hash' do
      model.add_belief(domain: 'ethics', content: 'test')
      h = model.to_h
      expect(h[:beliefs]).to be_an(Array)
      expect(h[:events]).to be_an(Array)
      expect(h[:stress]).to eq(model.stress)
      expect(h[:total_beliefs]).to eq(1)
      expect(h[:total_events]).to eq(0)
      expect(h[:unresolved_count]).to eq(0)
    end

    it 'counts unresolved events correctly' do
      model.add_belief(domain: 'x', content: 'a')
      model.add_belief(domain: 'x', content: 'b')
      h = model.to_h
      expect(h[:unresolved_count]).to eq(1)
    end
  end
end
