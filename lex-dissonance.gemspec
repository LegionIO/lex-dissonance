# frozen_string_literal: true

require_relative 'lib/legion/extensions/dissonance/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-dissonance'
  spec.version       = Legion::Extensions::Dissonance::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Dissonance'
  spec.description   = 'Cognitive dissonance modeling — contradiction detection, belief tracking, and resolution strategies for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-dissonance'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-dissonance'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-dissonance'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-dissonance'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-dissonance/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-dissonance.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
