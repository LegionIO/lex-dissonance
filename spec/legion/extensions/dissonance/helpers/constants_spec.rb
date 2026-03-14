# frozen_string_literal: true

RSpec.describe Legion::Extensions::Dissonance::Helpers::Constants do
  it 'defines DISSONANCE_THRESHOLD' do
    expect(described_class::DISSONANCE_THRESHOLD).to eq(0.4)
  end

  it 'defines MAX_BELIEFS' do
    expect(described_class::MAX_BELIEFS).to eq(200)
  end

  it 'defines MAX_DISSONANCE_EVENTS' do
    expect(described_class::MAX_DISSONANCE_EVENTS).to eq(100)
  end

  it 'defines DECAY_RATE' do
    expect(described_class::DECAY_RATE).to eq(0.03)
  end

  it 'defines RESOLUTION_RELIEF' do
    expect(described_class::RESOLUTION_RELIEF).to eq(0.3)
  end

  it 'defines RATIONALIZATION_FACTOR' do
    expect(described_class::RATIONALIZATION_FACTOR).to eq(0.5)
  end

  it 'defines IMPORTANCE_WEIGHTS with four levels' do
    weights = described_class::IMPORTANCE_WEIGHTS
    expect(weights[:core]).to eq(1.0)
    expect(weights[:significant]).to eq(0.7)
    expect(weights[:moderate]).to eq(0.5)
    expect(weights[:peripheral]).to eq(0.25)
  end

  it 'defines RESOLUTION_STRATEGIES' do
    expect(described_class::RESOLUTION_STRATEGIES).to contain_exactly(:belief_revision, :rationalization, :avoidance)
  end

  it 'defines STRESS_CEILING and STRESS_FLOOR' do
    expect(described_class::STRESS_CEILING).to eq(1.0)
    expect(described_class::STRESS_FLOOR).to eq(0.0)
  end

  it 'defines CONTRADICTION_TYPES' do
    expect(described_class::CONTRADICTION_TYPES).to contain_exactly(:direct, :inverse, :conditional, :temporal)
  end

  it 'freezes IMPORTANCE_WEIGHTS' do
    expect(described_class::IMPORTANCE_WEIGHTS).to be_frozen
  end

  it 'freezes RESOLUTION_STRATEGIES' do
    expect(described_class::RESOLUTION_STRATEGIES).to be_frozen
  end

  it 'freezes CONTRADICTION_TYPES' do
    expect(described_class::CONTRADICTION_TYPES).to be_frozen
  end
end
