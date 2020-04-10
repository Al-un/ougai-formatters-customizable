# frozen_string_literal: true

require 'ougai/formatters/base'
require 'ougai/formatters/colors/configuration'

module Ougai
  module Formatters
    # Ougai log printing can be split in three components:
    # 1. Main log message: usually with timestamp, log severity and a single
    #    line message
    # 2. Log data: the structured logging component. Can be represented by
    #    a Hash
    # 3. Errors: errors require specific log formatting
    #
    # Customizable offers a flexible way to handle each component
    # independently by assigning a proc to the following keys:
    #
    # 1. +:format_msg+ Format message. Proc arguments are +|level, datetime, progname, data|+. This block must remove the key +:msg+ from +data+
    # 2. +:format_data+ Format data. Proc argument is +|data|+.
    # 3. +:format_err+ Format err. Proc argument is +|data|+. The proc must  remove the key +:err+
    class Customizable < Ougai::Formatters::Base
      class << self
        # Define the default main log message formatting to use. A non-null
        # color configuration has to be provided. The configuration can however
        # be empty
        #
        # @param [Ougai::Formatters::Colors::Configuration] color_config the
        #         color configuration to use
        #
        # @return [Proc] main message formatter
        def default_msg_format(color_config)
          proc do |severity, datetime, _progname, data|
            msg = data.delete(:msg)
            severity  = color_config.color(:severity, severity, severity)
            datetime  = color_config.color(:datetime, datetime, severity)
            msg       = color_config.color(:msg, msg, severity)

            "[#{datetime}] #{severity}: #{msg}"
          end
        end

        # Define the default error formatting to use which handles field
        # exclusion and plain mode for amazing-print
        #
        # @param [Array<Symbol>] excluded_fields list of key to exclude from
        #         +data+ before printing logs
        # @param [Boolean] plain parameter to define if Amazing-Print renders
        #         in plain mode or not
        #
        # @return [Proc] data formatter
        def default_data_format(excluded_fields, plain)
          proc do |data|
            excluded_fields.each { |field| data.delete(field) }
            next nil if data.empty?

            data.ai(plain: plain)
          end
        end

        # Define the default error formatting to use.
        #
        # @param [Integer] trace_indent space indentation to prepend before
        #         trace content
        #
        # @return [Proc] error formatter
        def default_err_format(trace_indent = 4)
          proc do |data|
            next nil unless data.key?(:err)

            err = data.delete(:err)
            err_str = "  #{err[:name]} (#{err[:message]}):"
            err_str += "\n" + (' ' * trace_indent) + err[:stack] if err.key?(:stack)
            err_str
          end
        end
      end

      # Intialize a formatter
      #
      # @param [String] app_name application name (execution program name if nil)
      # @param [String] hostname hostname (hostname if nil)
      # @param [Hash] opts the initial values of attributes
      # @option opts [String] :trace_max_lines (100) the value of
      #         trace_max_lines attribute
      # @option opts [String] :plain (false) the value of plain attribute
      # @option opts [String] :excluded_fields ([]) the value of
      #         excluded_fields attribute
      # @option opts [Ougai::Formatters::Colors::Configuration] :color_config
      #         assign a color configuration.
      # @option opts [Proc] :format_msg main message formatter
      # @option opts [Proc] :format_data data formatter
      # @option opts [Proc] :format_err error formatter
      def initialize(app_name = nil, hostname = nil, opts = {})
        aname, hname, opts = Base.parse_new_params([app_name, hostname, opts])
        super(aname, hname, opts)

        # Message logging
        color_config = opts.fetch(:color_config) {
          color_config = Ougai::Formatters::Colors::Configuration.new({})
        }
        @format_msg = opts.fetch(:format_msg) {
          Customizable.default_msg_format(color_config)
        }

        # Data logging
        plain = opts.fetch(:plain) { false }
        excluded_fields = opts[:excluded_fields] || []
        @format_data = opts.fetch(:format_data) {
          Customizable.default_data_format(excluded_fields, plain)
        }

        # Error logging
        trace_indent = opts.fetch(:trace_indent) { 4 }
        @format_err = opts.fetch(:format_err) {
          Customizable.default_err_format(trace_indent)
        }

        # Ensure dependency are present
        load_dependent
      end

      # Format a log entry
      #
      # @param [String] severity log severity, in capital letters
      # @param [Time] time timestamp of the log. Is formatted by +strftime+
      # @param [String] progname optional program name
      # @param [Hash] data log data. Main message is stored under the key +:msg+
      #         while errors are logged under the key +:err+.
      #
      # @return [String] log text, ready to be printed out
      def _call(severity, time, progname, data)
        strs = ''.dup
        # Main message
        dt =  format_datetime(time)
        msg_str = @format_msg.call(severity, dt, progname, data)
        strs.concat(msg_str)

        # Error: displayed before additional data
        err_str = @format_err.call(data)
        strs.concat("\n").concat(err_str) unless err_str.nil?

        # Additional data
        data_str = @format_data.call(data)
        strs.concat("\n").concat(data_str) unless data_str.nil?

        strs.concat("\n")
      end

      protected

      # Ensure +awesompe_print+ is loaded
      def load_dependent
        require 'amazing_print'
      rescue LoadError
        puts 'You must install the amazing_print gem to use this output.'
        raise
      end
    end
  end
end
