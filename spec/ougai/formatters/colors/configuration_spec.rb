RSpec.describe Ougai::Formatters::Colors::Configuration do
  include Ougai::Logging::Severity

  # Configuration for initialization
  let!(:default_cfg) do 
    Ougai::Formatters::Colors::Configuration.default_configuration
  end
  let(:partial_severity_cfg) do
    { severity: { info: 'some_value', warn: 'some_value' } } 
  end
  let(:complete_cfg) do
    {
      severity: {
        trace: 'trace_value', debug: 'debug_value', info: 'info_value',
        warn: 'warn_value', error: 'error_value', fatal: 'fatal_value',
        any: 'any_value'
      },
      datetime: 'some same color',
      msg: :severity,
      invalid: :an_invalid_inheritance,
      partial_severity: {
        trace: 'some_trace_value', debug: 'some_debug_value',
        default: 'some_default_value'
      }
    }
  end
  let(:uniq_value) { 'an unique color' }
  # Log severities
  let!(:trace)          { 'TRACE' }
  let!(:debug)          { 'DEBUG' }
  let!(:info)           { 'INFO' }
  let!(:warn)           { 'WARN' }
  let!(:error)          { 'ERROR' }
  let!(:fatal)          { 'FATAL' }
  let!(:any)            { 'ANY' }
  let!(:severities)     { [trace, debug, info, warn, error, fatal, any] }
  let!(:severities_sym) { [:trace, :debug, :info, :warn, :error, :fatal, :any] }

  describe 'default configuration' do
    it 'defines color for all severities' do
      expect(default_cfg[:severity]).to be_a(Hash)
      severities_sym.each do |level|
        # Ensure value is present. Value is not checked
        expect(default_cfg[:severity][level]).to be_a(String)
      end
    end
  end

  describe '#initialize' do
    context 'with no configuration input' do
      subject { Ougai::Formatters::Colors::Configuration.new }

      it 'has default configuration' do
        expect(subject.instance_variable_get(:@config)).to eq(default_cfg)
      end
    end

    context 'with a complete configuration' do
      subject { Ougai::Formatters::Colors::Configuration.new(complete_cfg) }

      it 'has input as configuration' do
        expect(subject.instance_variable_get(:@config)).to eq(complete_cfg)
      end
    end

    context 'with an severity color' do
      subject { Ougai::Formatters::Colors::Configuration.new(severity: uniq_value) }
      let(:cfg) { subject.instance_variable_get(:@config) }
  
      it 'has severity configuration reduced to a single value' do
        expect(cfg[:severity]).to be_a(String)
        expect(cfg[:severity]).to eq(uniq_value)
      end
    end

    context 'without severity configuration' do
      let(:no_severity_cfg) do
        { datetime: :severity, msg: 'some irrelevant value' }
      end
      subject { Ougai::Formatters::Colors::Configuration.new(no_severity_cfg) }
      let(:cfg) { subject.instance_variable_get(:@config) }
  
      it 'has default severity values' do
        expect(cfg[:severity]).to eq(default_cfg[:severity])
      end

      it 'has input values' do
        expect(cfg[:datetime]).to eq(no_severity_cfg[:datetime])
        expect(cfg[:msg]).to eq(no_severity_cfg[:msg])
      end
    end

    context 'with partial severity configuration' do
      subject         { Ougai::Formatters::Colors::Configuration.new(partial_severity_cfg) }
      let(:cfg)       { subject.instance_variable_get(:@config) }
  
      it 'takes values undefined in default from input' do
        expect(cfg[:datetime]).to eq(partial_severity_cfg[:datetime])
      end

      it 'has input values having precedence over default values' do
        expect(cfg[:severity][:info]).to eq(partial_severity_cfg[:severity][:info])
        expect(cfg[:severity][:warn]).to eq(partial_severity_cfg[:severity][:warn])
      end

      it 'takes values undefined in input from default' do
        expect(cfg[:severity][:trace]).to eq(default_cfg[:severity][:trace])
        expect(cfg[:severity][:debug]).to eq(default_cfg[:severity][:debug])
        expect(cfg[:severity][:error]).to eq(default_cfg[:severity][:error])
        expect(cfg[:severity][:fatal]).to eq(default_cfg[:severity][:fatal])
      end
    end
  end

  describe '.get_color_for' do
    subject { Ougai::Formatters::Colors::Configuration.new(complete_cfg) }

    context 'when subject is not defined' do
      it 'returns nil' do
        expect(subject.get_color_for(:an_impossible_key, info)).to be_nil
      end
    end

    context 'with a String value' do
      it 'returns the single value regardless severity' do
        severities.each do |lvl|
          expect(subject.get_color_for(:datetime, lvl)).to eq('some same color')
        end
      end
    end

    context 'with a complete Hash value' do
      it 'returns the single value depending on severity' do
        severities.each do |lvl|
          expect(subject.get_color_for(:msg, lvl)).to eq(lvl.downcase + '_value')
        end
      end
    end

    context 'with a partial Hash value' do
      context 'when severity is defined' do
        it 'returns the corresponding value' do
          expect(subject.get_color_for(:partial_severity, trace)).to eq('some_trace_value')
          expect(subject.get_color_for(:partial_severity, debug)).to eq('some_debug_value')
        end
      end
      context 'when severity is not defined' do
        it 'returns the default value' do
          expect(subject.get_color_for(:partial_severity, info)).to eq('some_default_value')
          expect(subject.get_color_for(:partial_severity, warn)).to eq('some_default_value')
          expect(subject.get_color_for(:partial_severity, error)).to eq('some_default_value')
          expect(subject.get_color_for(:partial_severity, fatal)).to eq('some_default_value')
          expect(subject.get_color_for(:partial_severity, any)).to eq('some_default_value')
        end
      end
    end

    context 'with a valid Symbol value' do
      it 'returns the value inherited from the referenced symbol' do
        severities.each do |lvl|
          expect(subject.get_color_for(:msg, lvl)).to eq(subject.get_color_for(:severity, lvl))
        end
      end
    end

    context 'with an invalid Symbol value' do
      it 'returns nil' do
        severities.each do |lvl|
          expect(subject.get_color_for(:invalid, lvl)).to be_nil
        end
      end
    end
  end

  describe '.color' do
    it 'works' do
      expect(subject.color(:severity, 'an irrelevant text', info)).not_to be_nil
    end
  end

end
