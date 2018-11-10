# frozen_string_literal: true

require 'ougai/formatters/colors'

module Ougai
  module Formatters
    module Colors
      # Handle the colorization of output, mainly aimed at console formatting.
      # The configuration,split by subject such as +level+, +msg+,
      # or +datetime+ is basically a Hash: +config+ with the subject as key
      # and values. Values can be have three types:
      #   - String: the color escape sequence for the subject
      #   - Hash: the color escape sequence per severity. If not all severities
      #     are defined, a +:default+ value must be defined
      #   - Symbol: refers to another key and same coloring is applied
      class Configuration
        class << self
          # list default color configuration
          # @note 'any' severity label decided in 
          #       +Ougai::Logging::Severity#to_label+
          # @note values are copied from +Ougai::Formatters::Readable+ coloring
          #       values
          def default_configuration
            {
              severity: {
                trace:  Ougai::Formatters::Colors::BLUE,
                debug:  Ougai::Formatters::Colors::WHITE,
                info:   Ougai::Formatters::Colors::CYAN,
                warn:   Ougai::Formatters::Colors::YELLOW,
                error:  Ougai::Formatters::Colors::RED,
                fatal:  Ougai::Formatters::Colors::PURPLE,
                any:    Ougai::Formatters::Colors::GREEN
              }
            }
          end
        end

        # @param [Hash] configuration Color configuration mapping. Cannot be nil
        # @param [Boolean] load_default_config If true, then default configuration
        #         values is fetched to fill missing value from the provided 
        #         configuration. Default is true.
        def initialize(configuration = {})
          # check if loading or not from default configuration
          if configuration.fetch(:load_default_config) { true }
            @config = Configuration.default_configuration
          else
            @config = {}
          end

          configuration.each do |key, val|
            default_val = @config[key]
            # default value is a Hash AND input value is a Hash => merge
            if val.is_a?(Hash) && default_val.is_a?(Hash)
              @config[key] = default_val.merge(val)
            # Input value is assigned because one of the follow
            # 1) input value is not defined in default configuration
            # 2) input value is not a Hash which overrides the default value
            # 3) default value is not a Hash and input is a Hash => Arbitrary
            else
              @config[key] = val
            end
          end
        end

        # @param [Symbol] subject_key to fetch the color to color the text
        # @param [String] text to be colored text
        # @param [Symbol] severity log level
        # @return a colored text depending on the subject
        def color(subject_key, text, severity)
          color = get_color_for(subject_key, severity)
          Ougai::Formatters::Colors.color_text(color, text)
        end

        # Return the color for a given suject and a given severity. This color
        # can then be applied to any text via
        # +Ougai::Formatters::Colors.color_text+
        #
        # +get_color_for+ handles color inheritance: if a subject inherit color
        # from another subject, subject value is the symbol refering to the
        # other subject.
        # !!WARNING!!: Circular references are not checked and lead to infinite
        # loop  
        #
        # @param [Symbol] subject_key: to define the color to color the text
        # @param [Symbol] severity: log level
        # @return requested color String value or +nil+ if not colored
        def get_color_for(subject_key, severity)
          # no colorization
          return nil unless @config.key?(subject_key)

          # no severity dependence nor inheritance
          color = @config[subject_key]
          return color if color.is_a? String

          # inheritance from another subject
          return get_color_for(color, severity) if color.is_a? Symbol

          # severity dependent but not inherited value or return +nil+ if
          # configuration is incorrect
          severity = severity.downcase.to_sym
          color.fetch(severity) { color[:default] }
        end

      end

    end
  end
end
