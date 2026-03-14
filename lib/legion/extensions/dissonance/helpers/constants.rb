# frozen_string_literal: true

module Legion
  module Extensions
    module Dissonance
      module Helpers
        module Constants
          DISSONANCE_THRESHOLD  = 0.4
          MAX_BELIEFS           = 200
          MAX_DISSONANCE_EVENTS = 100
          DECAY_RATE            = 0.03
          RESOLUTION_RELIEF     = 0.3
          RATIONALIZATION_FACTOR = 0.5
          IMPORTANCE_WEIGHTS    = { core: 1.0, significant: 0.7, moderate: 0.5, peripheral: 0.25 }.freeze
          RESOLUTION_STRATEGIES = %i[belief_revision rationalization avoidance].freeze
          STRESS_CEILING        = 1.0
          STRESS_FLOOR          = 0.0
          CONTRADICTION_TYPES   = %i[direct inverse conditional temporal].freeze
        end
      end
    end
  end
end
