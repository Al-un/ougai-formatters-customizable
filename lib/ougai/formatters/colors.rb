# frozen_string_literal: true

module Ougai
  module Formatters
    # List of useful ANSI escape sequences for terminal font formatting. Source
    # is https://gist.github.com/chrisopedia/8754917.
    module Colors
      # -- Comments compared to Ougai initial coloring --
      # Non-bold font colors do not use \e[0;{value}m because it seems to be
      # incompatible with background colors: \e[41m\e[0;34mtext\e[0m does not print
      # background red while \e[41m\e[34mtext\e[0m works. However, to put font in
      # bold/bright mode, \e[41m\e[1;34mtext\e[0m works
      # => Tested on Windows PowerShell and MinGW64
      #
      # Colors values cannot be frozen as .concat is called upon them

      # Reset formatting. To be appended after every formatted text
      RESET             = "\e[0m"
      # Foreground colors
      BLACK             = "\e[30m"
      RED               = "\e[31m"
      GREEN             = "\e[32m"
      YELLOW            = "\e[33m"
      BLUE              = "\e[34m"
      PURPLE            = "\e[35m"
      CYAN              = "\e[36m"
      WHITE             = "\e[37m"
      BOLD_RED          = "\e[1;31m"
      BOLD_GREEN        = "\e[1;32m"
      BOLD_YELLOW       = "\e[1;33m"
      BOLD_BLUE         = "\e[1;34m"
      BOLD_MAGENTA      = "\e[1;35m"
      BOLD_CYAN         = "\e[1;36m"
      BOLD_WHITE        = "\e[1;37m"
      # Background colors
      BG_BLACK          = "\e[40m"
      BG_RED            = "\e[41m"
      BG_GREEN          = "\e[42m"
      BG_YELLOW         = "\e[43m"
      BG_BLUE           = "\e[44m"
      BG_MAGENTA        = "\e[45m"
      BG_CYAN           = "\e[46m"
      BG_WHITE          = "\e[47m"

      class << self
        # Color a text by prepending a font styling escape sequence and
        # appending a reset sequence. This method does a pure String concatenation
        # and does not check the values are properly escaped. This allows
        # customization, depending on user's terminal, to use custom escape
        # sequences.
        # 
        # @param [String] color color to prepend. Color can be from the list
        #         above or have a complete custom String value depending on the
        #         terminal. If +nil+, text is not modified.
        # @param [String] text text to be colored
        # @param [String] reset reset font styling escape sequence. Default
        #         to +\e[0m+
        def color_text(color, text, reset = Ougai::Formatters::Colors::RESET)
          return text if color.nil?

          # .concat is preferred in Ruby:
          # https://coderwall.com/p/ac5j9g/or-concat-what-is-faster-for-appending-string-in-ruby
          ''.dup.concat(color).concat(text).concat(reset)
        end
      end

    end
  end
end
