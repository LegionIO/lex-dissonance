# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module Dissonance
      module Helpers
        class Belief
          attr_reader :id, :domain, :content, :confidence, :importance, :created_at

          def initialize(domain:, content:, confidence: 0.7, importance: :moderate)
            @id         = SecureRandom.uuid
            @domain     = domain
            @content    = content
            @confidence = confidence.clamp(0.0, 1.0)
            @importance = importance
            @created_at = Time.now.utc
          end

          def contradicts?(other)
            return false if id == other.id
            return false unless domain == other.domain

            content.strip.downcase != other.content.strip.downcase
          end

          def to_h
            {
              id:         id,
              domain:     domain,
              content:    content,
              confidence: confidence,
              importance: importance,
              created_at: created_at
            }
          end
        end
      end
    end
  end
end
