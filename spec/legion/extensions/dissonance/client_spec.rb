# frozen_string_literal: true

require 'legion/extensions/dissonance/client'

RSpec.describe Legion::Extensions::Dissonance::Client do
  describe '#initialize' do
    it 'creates a default DissonanceModel when none provided' do
      client = described_class.new
      expect(client.model).to be_a(Legion::Extensions::Dissonance::Helpers::DissonanceModel)
    end

    it 'accepts a custom model' do
      custom_model = Legion::Extensions::Dissonance::Helpers::DissonanceModel.new
      client = described_class.new(model: custom_model)
      expect(client.model).to be(custom_model)
    end
  end

  describe 'responds to all runner methods' do
    let(:client) { described_class.new }

    it { expect(client).to respond_to(:add_belief) }
    it { expect(client).to respond_to(:update_dissonance) }
    it { expect(client).to respond_to(:resolve_dissonance) }
    it { expect(client).to respond_to(:dissonance_status) }
    it { expect(client).to respond_to(:domain_dissonance) }
    it { expect(client).to respond_to(:beliefs_for) }
    it { expect(client).to respond_to(:unresolved) }
    it { expect(client).to respond_to(:dissonance_stats) }
  end

  describe 'state isolation between instances' do
    it 'two clients do not share belief state' do
      client1 = described_class.new
      client2 = described_class.new
      client1.add_belief(domain: 'x', content: 'some belief')
      result = client2.beliefs_for(domain: 'x')
      expect(result[:count]).to eq(0)
    end
  end

  describe 'custom model integration' do
    it 'uses the beliefs already in a pre-populated model' do
      model = Legion::Extensions::Dissonance::Helpers::DissonanceModel.new
      model.add_belief(domain: 'shared', content: 'a shared belief')
      client = described_class.new(model: model)
      result = client.beliefs_for(domain: 'shared')
      expect(result[:count]).to eq(1)
    end
  end
end
