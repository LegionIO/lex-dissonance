# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Dissonance
      module Helpers
        class DissonanceEvent
          attr_reader :id, :belief_a_id, :belief_b_id, :domain, :magnitude,
                      :contradiction_type, :resolved, :resolution_strategy, :timestamp

          def initialize(belief_a_id:, belief_b_id:, domain:, magnitude:, contradiction_type: :direct)
            @id                  = SecureRandom.uuid
            @belief_a_id         = belief_a_id
            @belief_b_id         = belief_b_id
            @domain              = domain
            @magnitude           = magnitude.clamp(0.0, 1.0)
            @contradiction_type  = contradiction_type
            @resolved            = false
            @resolution_strategy = nil
            @timestamp           = Time.now.utc
          end

          def resolve!(strategy)
            @resolved            = true
            @resolution_strategy = strategy
            self
          end

          def to_h
            {
              id:                  id,
              belief_a_id:         belief_a_id,
              belief_b_id:         belief_b_id,
              domain:              domain,
              magnitude:           magnitude,
              contradiction_type:  contradiction_type,
              resolved:            resolved,
              resolution_strategy: resolution_strategy,
              timestamp:           timestamp
            }
          end
        end
      end
    end
  end
end
