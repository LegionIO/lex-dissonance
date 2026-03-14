# frozen_string_literal: true

module Legion
  module Extensions
    module Dissonance
      module Runners
        module Dissonance
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def add_belief(domain:, content:, confidence: 0.7, importance: :moderate, **)
            unless Helpers::Constants::IMPORTANCE_WEIGHTS.key?(importance)
              return { success: false, error: :invalid_importance,
                       valid: Helpers::Constants::IMPORTANCE_WEIGHTS.keys }
            end

            result  = dissonance_model.add_belief(domain: domain, content: content,
                                                  confidence: confidence, importance: importance)
            belief  = result[:belief]
            new_evs = result[:new_dissonance_events]

            Legion::Logging.debug "[dissonance] add_belief: id=#{belief.id[0..7]} domain=#{domain} importance=#{importance} new_events=#{new_evs.size}"

            {
              success:               true,
              belief_id:             belief.id,
              domain:                domain,
              new_dissonance_events: new_evs.map(&:to_h),
              dissonance_triggered:  new_evs.any? { |ev| ev.magnitude >= Helpers::Constants::DISSONANCE_THRESHOLD }
            }
          end

          def update_dissonance(**)
            dissonance_model.detect_contradictions
            new_stress = dissonance_model.decay
            unresolved = dissonance_model.unresolved_events

            Legion::Logging.debug "[dissonance] update: stress=#{new_stress.round(3)} unresolved=#{unresolved.size}"

            {
              success:          true,
              stress:           new_stress,
              unresolved_count: unresolved.size,
              above_threshold:  unresolved.any? { |ev| ev.magnitude >= Helpers::Constants::DISSONANCE_THRESHOLD }
            }
          end

          def resolve_dissonance(event_id:, strategy: :belief_revision, **)
            unless Helpers::Constants::RESOLUTION_STRATEGIES.include?(strategy)
              return { success: false, error: :invalid_strategy,
                       valid: Helpers::Constants::RESOLUTION_STRATEGIES }
            end

            event = dissonance_model.resolve(event_id, strategy: strategy)
            if event
              Legion::Logging.debug "[dissonance] resolved: id=#{event_id[0..7]} strategy=#{strategy}"
              { success: true, resolved: true, strategy: strategy, event: event.to_h }
            else
              Legion::Logging.debug "[dissonance] resolve failed: id=#{event_id[0..7]} not_found_or_already_resolved"
              { success: false, error: :not_found_or_already_resolved }
            end
          end

          def dissonance_status(**)
            model    = dissonance_model
            snapshot = model.to_h

            Legion::Logging.debug "[dissonance] status: stress=#{snapshot[:stress].round(3)} " \
                                  "beliefs=#{snapshot[:total_beliefs]} unresolved=#{snapshot[:unresolved_count]}"

            {
              success:          true,
              stress:           snapshot[:stress],
              total_beliefs:    snapshot[:total_beliefs],
              total_events:     snapshot[:total_events],
              unresolved_count: snapshot[:unresolved_count]
            }
          end

          def domain_dissonance(domain:, **)
            stress = dissonance_model.domain_stress(domain)
            unresolved = dissonance_model.unresolved_events.select { |ev| ev.domain == domain }

            Legion::Logging.debug "[dissonance] domain_dissonance: domain=#{domain} stress=#{stress.round(3)} unresolved=#{unresolved.size}"

            {
              success:          true,
              domain:           domain,
              stress:           stress,
              unresolved_count: unresolved.size,
              events:           unresolved.map(&:to_h)
            }
          end

          def beliefs_for(domain:, **)
            beliefs = dissonance_model.beliefs.values.select { |b| b.domain == domain }

            Legion::Logging.debug "[dissonance] beliefs_for: domain=#{domain} count=#{beliefs.size}"

            {
              success: true,
              domain:  domain,
              count:   beliefs.size,
              beliefs: beliefs.map(&:to_h)
            }
          end

          def unresolved(**)
            events = dissonance_model.unresolved_events

            Legion::Logging.debug "[dissonance] unresolved: count=#{events.size}"

            {
              success: true,
              count:   events.size,
              events:  events.map(&:to_h)
            }
          end

          def dissonance_stats(**)
            model    = dissonance_model
            snapshot = model.to_h

            domains = model.beliefs.values.map(&:domain).uniq
            domain_stresses = domains.to_h { |d| [d, model.domain_stress(d)] }

            unresolved = model.unresolved_events
            resolved   = model.events.values.select(&:resolved)

            resolution_breakdown = Helpers::Constants::RESOLUTION_STRATEGIES.to_h do |s|
              [s, resolved.count { |ev| ev.resolution_strategy == s }]
            end

            Legion::Logging.debug "[dissonance] stats: beliefs=#{snapshot[:total_beliefs]} " \
                                  "events=#{snapshot[:total_events]} stress=#{snapshot[:stress].round(3)}"

            {
              success:              true,
              stress:               snapshot[:stress],
              total_beliefs:        snapshot[:total_beliefs],
              total_events:         snapshot[:total_events],
              unresolved_count:     unresolved.size,
              resolved_count:       resolved.size,
              domain_stresses:      domain_stresses,
              resolution_breakdown: resolution_breakdown,
              above_threshold:      unresolved.any? { |ev| ev.magnitude >= Helpers::Constants::DISSONANCE_THRESHOLD }
            }
          end

          private

          def dissonance_model
            @dissonance_model ||= Helpers::DissonanceModel.new
          end
        end
      end
    end
  end
end
