# frozen_string_literal: true

require 'legion/extensions/dissonance/client'

RSpec.describe Legion::Extensions::Dissonance::Runners::Dissonance do
  let(:client) { Legion::Extensions::Dissonance::Client.new }

  describe '#add_belief' do
    it 'returns success true with a belief_id' do
      result = client.add_belief(domain: 'ethics', content: 'honesty is required')
      expect(result[:success]).to be true
      expect(result[:belief_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the domain' do
      result = client.add_belief(domain: 'ethics', content: 'test')
      expect(result[:domain]).to eq('ethics')
    end

    it 'returns empty new_dissonance_events for first belief in domain' do
      result = client.add_belief(domain: 'ethics', content: 'honesty is required')
      expect(result[:new_dissonance_events]).to be_empty
    end

    it 'returns dissonance events when contradiction detected' do
      client.add_belief(domain: 'safety', content: 'always ask permission')
      result = client.add_belief(domain: 'safety', content: 'act without asking')
      expect(result[:new_dissonance_events].size).to eq(1)
    end

    it 'sets dissonance_triggered when magnitude >= threshold' do
      client.add_belief(domain: 'ethics', content: 'tell the truth', confidence: 1.0, importance: :core)
      result = client.add_belief(domain: 'ethics', content: 'lie when convenient', confidence: 1.0, importance: :core)
      expect(result[:dissonance_triggered]).to be true
    end

    it 'returns success false for invalid importance' do
      result = client.add_belief(domain: 'ethics', content: 'test', importance: :invalid)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_importance)
    end

    it 'returns valid importance levels on error' do
      result = client.add_belief(domain: 'ethics', content: 'test', importance: :invalid)
      expect(result[:valid]).to contain_exactly(:core, :significant, :moderate, :peripheral)
    end

    it 'accepts all valid importance levels' do
      %i[core significant moderate peripheral].each do |imp|
        result = client.add_belief(domain: 'test', content: "content_#{imp}", importance: imp)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#update_dissonance' do
    it 'returns success true' do
      result = client.update_dissonance
      expect(result[:success]).to be true
    end

    it 'returns current stress' do
      result = client.update_dissonance
      expect(result[:stress]).to be_a(Float)
      expect(result[:stress]).to be_between(0.0, 1.0)
    end

    it 'returns unresolved_count' do
      result = client.update_dissonance
      expect(result[:unresolved_count]).to eq(0)
    end

    it 'above_threshold is false when no unresolved events' do
      result = client.update_dissonance
      expect(result[:above_threshold]).to be false
    end

    it 'above_threshold is true when high-magnitude unresolved events exist' do
      client.add_belief(domain: 'x', content: 'a', confidence: 1.0, importance: :core)
      client.add_belief(domain: 'x', content: 'b', confidence: 1.0, importance: :core)
      result = client.update_dissonance
      expect(result[:above_threshold]).to be true
    end

    it 'increases unresolved_count after adding contradictions' do
      client.add_belief(domain: 'y', content: 'claim1')
      client.add_belief(domain: 'y', content: 'claim2')
      result = client.update_dissonance
      expect(result[:unresolved_count]).to eq(1)
    end
  end

  describe '#resolve_dissonance' do
    let(:event_id) do
      client.add_belief(domain: 'ethics', content: 'be honest')
      result = client.add_belief(domain: 'ethics', content: 'deceive when convenient')
      result[:new_dissonance_events].first[:id]
    end

    it 'returns success true on valid resolution' do
      result = client.resolve_dissonance(event_id: event_id, strategy: :belief_revision)
      expect(result[:success]).to be true
      expect(result[:resolved]).to be true
    end

    it 'returns the strategy used' do
      result = client.resolve_dissonance(event_id: event_id, strategy: :rationalization)
      expect(result[:strategy]).to eq(:rationalization)
    end

    it 'returns the event hash' do
      result = client.resolve_dissonance(event_id: event_id, strategy: :belief_revision)
      expect(result[:event]).to be_a(Hash)
      expect(result[:event][:resolved]).to be true
    end

    it 'returns success false for invalid strategy' do
      result = client.resolve_dissonance(event_id: event_id, strategy: :magic)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_strategy)
    end

    it 'returns valid strategies on invalid strategy error' do
      result = client.resolve_dissonance(event_id: event_id, strategy: :magic)
      expect(result[:valid]).to eq(Legion::Extensions::Dissonance::Helpers::Constants::RESOLUTION_STRATEGIES)
    end

    it 'returns success false for unknown event_id' do
      result = client.resolve_dissonance(event_id: 'no-such-id', strategy: :belief_revision)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found_or_already_resolved)
    end

    it 'returns success false when event already resolved' do
      client.resolve_dissonance(event_id: event_id, strategy: :belief_revision)
      result = client.resolve_dissonance(event_id: event_id, strategy: :rationalization)
      expect(result[:success]).to be false
    end

    it 'defaults strategy to belief_revision' do
      result = client.resolve_dissonance(event_id: event_id)
      expect(result[:strategy]).to eq(:belief_revision)
    end

    it 'works with all three resolution strategies' do
      %i[belief_revision rationalization avoidance].each_with_index do |strategy, i|
        c = Legion::Extensions::Dissonance::Client.new
        c.add_belief(domain: 'domain', content: "a#{i}")
        inner_result = c.add_belief(domain: 'domain', content: "b#{i}")
        ev_id = inner_result[:new_dissonance_events].first[:id]
        result = c.resolve_dissonance(event_id: ev_id, strategy: strategy)
        expect(result[:success]).to be true
      end
    end
  end

  describe '#dissonance_status' do
    it 'returns success true' do
      result = client.dissonance_status
      expect(result[:success]).to be true
    end

    it 'returns stress value' do
      result = client.dissonance_status
      expect(result[:stress]).to be_a(Float)
    end

    it 'returns total_beliefs count' do
      client.add_belief(domain: 'x', content: 'test')
      result = client.dissonance_status
      expect(result[:total_beliefs]).to eq(1)
    end

    it 'returns total_events count' do
      client.add_belief(domain: 'x', content: 'a')
      client.add_belief(domain: 'x', content: 'b')
      result = client.dissonance_status
      expect(result[:total_events]).to eq(1)
    end

    it 'returns unresolved_count' do
      result = client.dissonance_status
      expect(result[:unresolved_count]).to eq(0)
    end
  end

  describe '#domain_dissonance' do
    it 'returns success true' do
      result = client.domain_dissonance(domain: 'ethics')
      expect(result[:success]).to be true
    end

    it 'returns the domain' do
      result = client.domain_dissonance(domain: 'ethics')
      expect(result[:domain]).to eq('ethics')
    end

    it 'returns 0.0 stress for domain with no beliefs' do
      result = client.domain_dissonance(domain: 'ethics')
      expect(result[:stress]).to eq(0.0)
    end

    it 'returns positive stress for domain with contradictions' do
      client.add_belief(domain: 'ethics', content: 'be honest')
      client.add_belief(domain: 'ethics', content: 'hide truth')
      result = client.domain_dissonance(domain: 'ethics')
      expect(result[:stress]).to be > 0.0
    end

    it 'returns unresolved events for the domain' do
      client.add_belief(domain: 'ethics', content: 'be honest')
      client.add_belief(domain: 'ethics', content: 'hide truth')
      result = client.domain_dissonance(domain: 'ethics')
      expect(result[:events].size).to eq(1)
      expect(result[:events].first[:domain]).to eq('ethics')
    end

    it 'does not include events from other domains' do
      client.add_belief(domain: 'ethics', content: 'be honest')
      client.add_belief(domain: 'ethics', content: 'hide truth')
      client.add_belief(domain: 'safety', content: 'claim x')
      client.add_belief(domain: 'safety', content: 'claim y')
      result = client.domain_dissonance(domain: 'ethics')
      expect(result[:events].all? { |ev| ev[:domain] == 'ethics' }).to be true
    end
  end

  describe '#beliefs_for' do
    it 'returns success true' do
      result = client.beliefs_for(domain: 'ethics')
      expect(result[:success]).to be true
    end

    it 'returns empty beliefs for unknown domain' do
      result = client.beliefs_for(domain: 'unknown')
      expect(result[:beliefs]).to be_empty
      expect(result[:count]).to eq(0)
    end

    it 'returns beliefs for a domain' do
      client.add_belief(domain: 'ethics', content: 'test belief')
      result = client.beliefs_for(domain: 'ethics')
      expect(result[:count]).to eq(1)
      expect(result[:beliefs].first[:content]).to eq('test belief')
    end

    it 'does not include beliefs from other domains' do
      client.add_belief(domain: 'ethics', content: 'ethics belief')
      client.add_belief(domain: 'safety', content: 'safety belief')
      result = client.beliefs_for(domain: 'ethics')
      expect(result[:count]).to eq(1)
    end

    it 'returns the domain in the result' do
      result = client.beliefs_for(domain: 'ethics')
      expect(result[:domain]).to eq('ethics')
    end
  end

  describe '#unresolved' do
    it 'returns success true' do
      result = client.unresolved
      expect(result[:success]).to be true
    end

    it 'returns empty events initially' do
      result = client.unresolved
      expect(result[:events]).to be_empty
      expect(result[:count]).to eq(0)
    end

    it 'returns unresolved events after contradiction' do
      client.add_belief(domain: 'x', content: 'claim a')
      client.add_belief(domain: 'x', content: 'claim b')
      result = client.unresolved
      expect(result[:count]).to eq(1)
    end

    it 'does not include resolved events' do
      client.add_belief(domain: 'x', content: 'claim a')
      inner_result = client.add_belief(domain: 'x', content: 'claim b')
      ev_id = inner_result[:new_dissonance_events].first[:id]
      client.resolve_dissonance(event_id: ev_id, strategy: :belief_revision)
      result = client.unresolved
      expect(result[:count]).to eq(0)
    end
  end

  describe '#dissonance_stats' do
    it 'returns success true' do
      result = client.dissonance_stats
      expect(result[:success]).to be true
    end

    it 'returns comprehensive stats hash' do
      result = client.dissonance_stats
      expect(result).to include(:stress, :total_beliefs, :total_events, :unresolved_count,
                                :resolved_count, :domain_stresses, :resolution_breakdown, :above_threshold)
    end

    it 'resolution_breakdown contains all three strategies' do
      result = client.dissonance_stats
      expect(result[:resolution_breakdown].keys).to contain_exactly(:belief_revision, :rationalization, :avoidance)
    end

    it 'counts resolved events by strategy' do
      client.add_belief(domain: 'x', content: 'a')
      inner_result = client.add_belief(domain: 'x', content: 'b')
      ev_id = inner_result[:new_dissonance_events].first[:id]
      client.resolve_dissonance(event_id: ev_id, strategy: :rationalization)
      result = client.dissonance_stats
      expect(result[:resolution_breakdown][:rationalization]).to eq(1)
      expect(result[:resolved_count]).to eq(1)
    end

    it 'domain_stresses includes all domains with beliefs' do
      client.add_belief(domain: 'domain_a', content: 'alpha')
      client.add_belief(domain: 'domain_b', content: 'beta')
      result = client.dissonance_stats
      expect(result[:domain_stresses].keys).to include('domain_a', 'domain_b')
    end
  end
end
