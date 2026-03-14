# frozen_string_literal: true

module Legion
  module Extensions
    module Dissonance
      module Helpers
        class DissonanceModel
          include Constants

          attr_reader :beliefs, :events, :stress

          def initialize
            @beliefs = {}
            @events  = {}
            @stress  = STRESS_FLOOR
          end

          def add_belief(domain:, content:, confidence: 0.7, importance: :moderate)
            prune_beliefs if @beliefs.size >= MAX_BELIEFS

            belief = Belief.new(domain: domain, content: content,
                                confidence: confidence, importance: importance)
            @beliefs[belief.id] = belief

            new_events = detect_contradictions_for(belief)
            new_events.each { |ev| @events[ev.id] = ev }

            { belief: belief, new_dissonance_events: new_events }
          end

          def detect_contradictions
            new_events = []
            belief_list = @beliefs.values

            belief_list.each_with_index do |bel_a, idx|
              belief_list[(idx + 1)..].each do |bel_b|
                next unless bel_a.contradicts?(bel_b)
                next if contradiction_tracked?(bel_a.id, bel_b.id)

                ev = build_event(bel_a, bel_b)
                @events[ev.id] = ev
                new_events << ev
              end
            end

            new_events
          end

          def resolve(event_id, strategy:)
            event = @events[event_id]
            return nil unless event
            return nil if event.resolved
            return nil unless RESOLUTION_STRATEGIES.include?(strategy)

            event.resolve!(strategy)
            relief = compute_relief(strategy)
            @stress = (@stress - relief).clamp(STRESS_FLOOR, STRESS_CEILING)
            event
          end

          def stress_level
            @stress
          end

          def domain_stress(domain)
            unresolved = unresolved_events.select { |ev| ev.domain == domain }
            return STRESS_FLOOR if unresolved.empty?

            raw = unresolved.sum(&:magnitude) / MAX_DISSONANCE_EVENTS.to_f
            raw.clamp(STRESS_FLOOR, STRESS_CEILING)
          end

          def unresolved_events
            @events.values.reject(&:resolved)
          end

          def decay
            unresolved = unresolved_events
            if unresolved.any?
              increment = DECAY_RATE * unresolved.size
              @stress   = (@stress + increment).clamp(STRESS_FLOOR, STRESS_CEILING)
            else
              @stress = (@stress - DECAY_RATE).clamp(STRESS_FLOOR, STRESS_CEILING)
            end
            @stress
          end

          def to_h
            {
              beliefs:          @beliefs.values.map(&:to_h),
              events:           @events.values.map(&:to_h),
              stress:           @stress,
              unresolved_count: unresolved_events.size,
              total_beliefs:    @beliefs.size,
              total_events:     @events.size
            }
          end

          private

          def detect_contradictions_for(new_belief)
            new_events = []

            @beliefs.each_value do |existing|
              next if existing.id == new_belief.id
              next unless new_belief.contradicts?(existing)
              next if contradiction_tracked?(new_belief.id, existing.id)

              ev = build_event(new_belief, existing)
              new_events << ev
            end

            new_events
          end

          def build_event(bel_a, bel_b)
            magnitude = compute_magnitude(bel_a, bel_b)
            DissonanceEvent.new(
              belief_a_id:        bel_a.id,
              belief_b_id:        bel_b.id,
              domain:             bel_a.domain,
              magnitude:          magnitude,
              contradiction_type: :direct
            )
          end

          def compute_magnitude(bel_a, bel_b)
            weight_a       = IMPORTANCE_WEIGHTS.fetch(bel_a.importance, 0.5)
            weight_b       = IMPORTANCE_WEIGHTS.fetch(bel_b.importance, 0.5)
            avg_weight     = (weight_a + weight_b) / 2.0
            avg_confidence = (bel_a.confidence + bel_b.confidence) / 2.0
            (avg_weight * avg_confidence).clamp(0.0, 1.0)
          end

          def compute_relief(strategy)
            base = RESOLUTION_RELIEF
            strategy == :rationalization ? base * RATIONALIZATION_FACTOR : base
          end

          def contradiction_tracked?(id_a, id_b)
            @events.values.any? do |ev|
              (ev.belief_a_id == id_a && ev.belief_b_id == id_b) ||
                (ev.belief_a_id == id_b && ev.belief_b_id == id_a)
            end
          end

          def prune_beliefs
            oldest = @beliefs.values.min_by(&:created_at)
            @beliefs.delete(oldest.id) if oldest
          end
        end
      end
    end
  end
end
