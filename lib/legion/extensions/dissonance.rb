# frozen_string_literal: true

require 'legion/extensions/dissonance/version'
require 'legion/extensions/dissonance/helpers/constants'
require 'legion/extensions/dissonance/helpers/belief'
require 'legion/extensions/dissonance/helpers/dissonance_event'
require 'legion/extensions/dissonance/helpers/dissonance_model'
require 'legion/extensions/dissonance/runners/dissonance'

module Legion
  module Extensions
    module Dissonance
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
