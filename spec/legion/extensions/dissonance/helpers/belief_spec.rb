# frozen_string_literal: true

RSpec.describe Legion::Extensions::Dissonance::Helpers::Belief do
  let(:belief) { described_class.new(domain: 'ethics', content: 'honesty is required', confidence: 0.9, importance: :core) }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(belief.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns domain' do
      expect(belief.domain).to eq('ethics')
    end

    it 'assigns content' do
      expect(belief.content).to eq('honesty is required')
    end

    it 'assigns confidence' do
      expect(belief.confidence).to eq(0.9)
    end

    it 'assigns importance' do
      expect(belief.importance).to eq(:core)
    end

    it 'assigns created_at as UTC Time' do
      expect(belief.created_at).to be_a(Time)
    end

    it 'clamps confidence to 0-1 range (above)' do
      b = described_class.new(domain: 'd', content: 'c', confidence: 1.5)
      expect(b.confidence).to eq(1.0)
    end

    it 'clamps confidence to 0-1 range (below)' do
      b = described_class.new(domain: 'd', content: 'c', confidence: -0.5)
      expect(b.confidence).to eq(0.0)
    end

    it 'defaults confidence to 0.7' do
      b = described_class.new(domain: 'd', content: 'c')
      expect(b.confidence).to eq(0.7)
    end

    it 'defaults importance to :moderate' do
      b = described_class.new(domain: 'd', content: 'c')
      expect(b.importance).to eq(:moderate)
    end
  end

  describe '#contradicts?' do
    let(:other_same) do
      described_class.new(domain: 'ethics', content: 'honesty is required', confidence: 0.8, importance: :moderate)
    end

    let(:other_different) do
      described_class.new(domain: 'ethics', content: 'deception is acceptable', confidence: 0.6, importance: :moderate)
    end

    let(:other_domain) do
      described_class.new(domain: 'safety', content: 'honesty is required', confidence: 0.8, importance: :moderate)
    end

    it 'returns false for same content' do
      expect(belief.contradicts?(other_same)).to be false
    end

    it 'returns true for different content in same domain' do
      expect(belief.contradicts?(other_different)).to be true
    end

    it 'returns false for different domain' do
      expect(belief.contradicts?(other_domain)).to be false
    end

    it 'returns false when compared to itself' do
      expect(belief.contradicts?(belief)).to be false
    end

    it 'is case-insensitive for content comparison' do
      upper = described_class.new(domain: 'ethics', content: 'HONESTY IS REQUIRED', confidence: 0.8, importance: :moderate)
      expect(belief.contradicts?(upper)).to be false
    end

    it 'ignores leading/trailing whitespace in content comparison' do
      padded = described_class.new(domain: 'ethics', content: '  honesty is required  ', confidence: 0.8, importance: :moderate)
      expect(belief.contradicts?(padded)).to be false
    end
  end

  describe '#to_h' do
    it 'returns a hash with all fields' do
      h = belief.to_h
      expect(h[:id]).to eq(belief.id)
      expect(h[:domain]).to eq('ethics')
      expect(h[:content]).to eq('honesty is required')
      expect(h[:confidence]).to eq(0.9)
      expect(h[:importance]).to eq(:core)
      expect(h[:created_at]).to be_a(Time)
    end
  end
end
