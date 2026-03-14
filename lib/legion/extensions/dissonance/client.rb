# frozen_string_literal: true

require 'legion/extensions/dissonance/helpers/constants'
require 'legion/extensions/dissonance/helpers/belief'
require 'legion/extensions/dissonance/helpers/dissonance_event'
require 'legion/extensions/dissonance/helpers/dissonance_model'
require 'legion/extensions/dissonance/runners/dissonance'

module Legion
  module Extensions
    module Dissonance
      class Client
        include Runners::Dissonance

        attr_reader :model

        def initialize(model: nil, **)
          @model            = model || Helpers::DissonanceModel.new
          @dissonance_model = @model
        end

        private

        attr_accessor :dissonance_model
      end
    end
  end
end
