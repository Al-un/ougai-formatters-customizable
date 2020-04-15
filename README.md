# Ougai-formatters-customizable

[![Gem Version](https://badge.fury.io/rb/ougai-formatters-customizable.svg)](https://badge.fury.io/rb/ougai-formatters-customizable)
[![Build Status](https://travis-ci.com/Al-un/ougai-formatters-customizable.svg?branch=master)](https://travis-ci.com/Al-un/ougai-formatters-customizable)
[![Maintainability](https://api.codeclimate.com/v1/badges/eaf20e90252260db1b68/maintainability)](https://codeclimate.com/github/Al-un/ougai-formatters-customizable/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/eaf20e90252260db1b68/test_coverage)](https://codeclimate.com/github/Al-un/ougai-formatters-customizable/test_coverage)

A fully customizable formatters for [Ougai](https://github.com/tilfin/ougai)
library. Customization is about formatting and colorization

**Formatting**

Ougai log printing can be split in three components:

 1. Main log message: usually timestamp, log severity and a message
 2. Data: the structured logging, represented by a Hash
 3. Errors

**Colorization**

Each part of the main log message can be colored independently. Colorization can
be extended to custom formatters as well.

## Usage

In your Gemfile, add *ougai-formatters-customizable* and its dependencies:

```ruby
gem 'amazing_print'
gem 'ougai'
gem 'ougai-formatters-customizable'
```

Then initialize a formatter and assign it to your logger:

```ruby
formatter           = Ougai::Formatters::Customizable.new
# See Ougai documentation about how to initialize a Ougai logger
logger.formatter    = formatter
```

The default *Customizable* configuration is exactly identical to a
*Ougai::Formatters::Readable* as-of Ougai 1.7.0.

#### Datetime format

Inherited from Ruby logger formatters, you can assign a datetime format:

```ruby
formatter.datetime_format = '%H:%M:%S.%L' # print time only such as '15:42:36.246'
```

#### Message formatter: `format_msg`

Main log message formatter is a `proc` which takes four arguments:

 - [String] severity: log severity. Is in capital letters
 - [String] datetime: log timestamp. Is already formatted according to `datetime_format`.
   Has to be treated like a String
 - [String] progname: optional program name
 - [Hash] data: structured log data. The main message is logged under the `:msg` key.

Custom message formatter can be assigned at initialization via the key `format_msg`:

```ruby
formatter = Ougai::Formatters::Customizable.new(
    format_msg: proc do |severity, datetime, _progname, data|
        msg = data.delete(:msg)
        format('%s %s: %s', severity, datetime, msg)
    end
)
```

**Notes**

 - It is recommended that this proc removes the `:msg` key from `data` to avoid
   duplicates
 - Although not mandatory, this formatter aims at outputting a single line String

#### Data formatter: `format_data`

Data formatter is a `proc` which takes only `data` as argument. Custom data
formatter can be assigned at initialization via `format_data` key:

```ruby
formatter = Ougai::Formatters::Customizable.new(
    format_data: proc do |data|
        data.ai # Amazing-print printing
    end
)
```

**Notes**

 - Data formatter must return `nil` if `data` is empty.
 - Default data formatter takes the `excluded_fields` option into account. You
   need to add it to your custom formatter if you want to keep it.

#### Error formatter: `format_err`

Error formatter is a `proc` with only `data` as argument and can be assigned at
initialization via the `format_err` key:

```ruby
formatter = Ougai::Formatters::Customizable.new(
    format_err: proc do |data|
        next nil unless data.key?(:err)

        err = data.delete(:err)
        "  #{err[:name]} (#{err[:message]})"
    end
)
```

**Notes**

 - Error formatter must return `nil` if `data` does not contain the `:err` key
 - Error formatter must remove `:err` key
 - Default error formatter takes the `trace_indent` option into account. You need
   to add it to your custom formatter if you want to keep it

#### Colorization

Colorization is handled by an instance of `Ougai::Formatters::Colors::Configuration`
and is basically a mapping *subject => value* to define the colors. Default subject
are:

 - `:severity`: log severity coloring
 - `:datetime`: datetime coloring
 - `:msg`: log main message coloring

You can add your own subject if you need it in your custom formatters.

Values can have three types:

 - String: this color is applied to the subject regardless the situation
 - Hash: the color is defined by log severity. Non defined severity colors are
   fetched from the `default` severity
 - Symbol: the color is copied from the referenced symbol

Example:

```ruby
color_configuration = Ougai::Formatters::Colors::Configuration.new(
    severity: {
      trace:    Ougai::Formatters::Colors::WHITE,
      debug:    Ougai::Formatters::Colors::GREEN,
      info:     Ougai::Formatters::Colors::CYAN,
      warn:     Ougai::Formatters::Colors::YELLOW,
      error:    Ougai::Formatters::Colors::RED,
      fatal:    Ougai::Formatters::Colors::PURPLE
    },
    msg: :severity,
    datetime: {
      default:  Ougai::Formatters::Colors::PURPLE,
      error:    Ougai::Formatters::Colors::RED,
      fatal:    Ougai::Formatters::Colors::RED
    },
    custom:     Ougai::Formatters::Colors::BLUE
)
```

 - *Severity* has a different color dependending on log severity
 - Main log *message* color is identical to severity color
 - *Datetime* has a red color for *error* and *fatal* logs. Otherwise it is
   colored in purple.
 - A *custom* subject is always colored in blue regardless log severity

**Notes**

 - If `:severity` is not defined, it is loaded from a default configuration
 - If `:severity` is partially defined, missing severities are fetched from
   default configuration
 - Circular references are not checked and infinite loops can then be triggered.

## Integration

#### Lograge / Lograge-sql

I initially made this gem to couple Ougai with [lograge](https://github.com/roidrage/lograge)/[lograge-sql](https://github.com/iMacTia/lograge-sql). Lograge logs has to be
formatted in a way so that our custom formatters can catch it:

```ruby
# config/initializers/lograge.rb
config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
        { request: data }
    end
end
```

I chose this format because I am also using Loggly and it is pretty convenient
to filter by `json.request.*` to fetch Lograge logs.

If using lograge-sql, make sure that Lograge format it as a Hash so that we can
leverage our main message formatter and data formatter:

```ruby
# config/initializers/lograge.rb
  config.lograge_sql.extract_event = proc do |event|
    {
      name: event.payload[:name],
      duration: event.duration.to_f.round(2),
      sql: event.payload[:sql]
    }
  end
  config.lograge_sql.formatter = proc do |sql_queries|
    sql_queries
  end
```

Wrap everything together example:

```ruby
# Define our colors
color_configuration = Ougai::Formatters::Colors::Configuration.new(
    severity: {
      trace:    Ougai::Formatters::Colors::WHITE,
      debug:    Ougai::Formatters::Colors::GREEN,
      info:     Ougai::Formatters::Colors::CYAN,
      warn:     Ougai::Formatters::Colors::YELLOW,
      error:    Ougai::Formatters::Colors::RED,
      fatal:    Ougai::Formatters::Colors::PURPLE
    },
    msg: :severity,
    datetime: {
      default:  Ougai::Formatters::Colors::PURPLE,
      error:    Ougai::Formatters::Colors::RED,
      fatal:    Ougai::Formatters::Colors::RED
    }
)

# Lograge specific configuration
EXCLUDED_FIELD = [:credit_card] # example only
LOGRAGE_REJECT = [:sql_queries, :sql_queries_count]

# Console formatter configuration
console_formatter = Ougai::Formatters::Customizable.new(
    format_msg: proc do |severity, datetime, _progname, data|
        # Remove :msg regardless the outcome
        msg = data.delete(:msg)
        # Lograge specfic stuff: do not print sql queries in main log message
        if data.key?(:request)
            lograge = data[:request].reject { |k, _v| LOGRAGE_REJECT.include?(k) }
                                    .map { |key, val| "#{key}: #{val}" }
                                    .join(', ')
            msg = color_config.color(:msg, lograge, severity)
        # Standard text
        else
            msg = color_config.color(:msg, msg, severity)
        end

        # Standardize output
        format('%s %s: %s',
                color_config.color(:severity, severity, severity),
                color_config.color(:datetime, datetime, severity),
                msg)
    end,
    format_data: proc do |data|
        # Lograge specfic stuff: main controller output handled by msg formatter
        if data.key?(:request)
            lograge_data = data[:request]
            # concatenate SQL queries
            if lograge_data.key?(:sql_queries)
                lograge_data[:sql_queries].map do |sql_query|
                    format('%<duration>6.2fms %<name>25s %<sql>s', sql_query)
                end
                .join("\n")
            # no queries: nothing to print
            else
                nil
            end
        # Default styling
        else
            # report excluded field parameter here: no need to add it to options
            EXCLUDED_FIELD.each { |field| data.delete(field) }
            next nil if data.empty?

            # report plain parameter here: no need to add it to options
            data.ai(plain: false)
        end
    end
)
console_formatter.datetime_format = '%H:%M:%S.%L' # local development: need only time

# Define console logger
console_logger            = Log::Ougai::Logger.new(STDOUT)
console_logger.formatter  = console_formatter

# Not this gem related: define file logger
file_logger               = Log::Ougai::Logger.new(Rails.root.join('log/ougai.log'))
file_logger.formatter     = Ougai::Formatters::Bunyan.new

# Extend console logger to file logger
console_logger.extend(Ougai::Logger.broadcast(file_logger))

# Assign Ougai logger
config.logger = console_logger
```

Output looks like
![Screenshot](https://raw.githubusercontent.com/Al-un/ougai-formatters-customizable/master/images/screenshot.png)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Al-un/ougai-formatters-customizable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
