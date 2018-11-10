RSpec.describe Ougai::Formatters::Customizable do
  # let!(:re_start_with_datetime) { /^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}(Z|[\+\-\:0-9]{4,6})]/ }
  let!(:trace_color)    { Ougai::Formatters::Colors::BLUE }
  let!(:debug_color)    { Ougai::Formatters::Colors::WHITE }
  let!(:info_color)     { Ougai::Formatters::Colors::CYAN }
  let!(:warn_color)     { Ougai::Formatters::Colors::YELLOW }
  let!(:error_color)    { Ougai::Formatters::Colors::RED }
  let!(:fatal_color)    { Ougai::Formatters::Colors::PURPLE }
  let!(:unknown_color)  { Ougai::Formatters::Colors::GREEN }
  let!(:reset_color)    { Ougai::Formatters::Colors::RESET }

  let(:datetime)        { Time.now }
  let(:iso_datetime)    { datetime.strftime("%FT%T.%3N#{(datetime.utc? ? 'Z' : '%:z')}") }
  let(:log_msg)         { 'Log Message!' }
  let(:data) do
    {
      msg: log_msg,
      status: 200,
      method: 'GET',
      path: '/',
      ip_address: '127.0.0.1'
    }
  end
  let(:err) do
    data.merge(
      err: {
        name: 'DummyError',
        message: 'it is dummy.',
        stack: "error1.rb\n  error2.rb"
      }
    )
  end

  let(:formatter) { described_class.new }

  it 'has a version number' do
    expect(Ougai::Formatters::CUSTOMIZABLE_VERSION).not_to be nil
  end

  describe '#default_msg_format' do
    subject { described_class.default_msg_format(Ougai::Formatters::Colors::Configuration.new) }

    it 'renders log msg like Readable' do
      formatted = subject.call('INFO', iso_datetime, nil, data)
      expect(formatted).to eq("[#{iso_datetime}] #{info_color}INFO#{reset_color}: #{log_msg}")
    end

    # [TODO] regex ?
    it 'colors severity' do
      formatted = subject.call('INFO', datetime, nil, data)
      expect(formatted).to include("#{info_color}INFO#{reset_color}")
    end

    it 'removes :msg from data' do
      expect(data.key?(:msg)).to be_truthy
      subject.call('INFO', datetime, nil, data)
      expect(data.key?(:msg)).to be_falsey
    end
  end

  describe '#default_data_format' do
    subject { described_class.default_data_format([:ip_address, :removed], false) }

    context 'when data is empty' do
      it 'returns nil' do
        expect(subject.call({})).to be_nil
      end
    end

    context 'when data is not empty' do
      it 'returns awesome_printed data' do
        expect(subject.call(data)).to eq(data.ai)
      end
    end

    context 'when some fields are excluded' do
      let(:data_clone)    { data.clone}
      let(:printed_data)  { subject.call(data) }

      it 'prints permitted fields' do
        printed_data = subject.call(data)
        data_clone.delete(:ip_address)
        awesome_print_data = subject.call(data_clone)
        expect(printed_data).to eq(awesome_print_data)
      end

      it 'does not print excluded fields' do
        printed_data = subject.call(data)
        expect(printed_data).not_to include('ip_address')
      end

      it 'deletes excluded fields' do
        subject.call(data)
        expect(data.key?(:ip_address)).to be_falsey
      end

      it 'keeps permitted fields' do
        subject.call(data)
        expect(data.key?(:msg)).to be_truthy
        expect(data.key?(:status)).to be_truthy
        expect(data.key?(:method)).to be_truthy
        expect(data.key?(:path)).to be_truthy
      end
    end

    context 'when all fields are excluded' do
      it 'returns nil' do
        printed_data = subject.call(ip_address: '127.0.0.1', removed: false)
        expect(printed_data).to be_nil
      end
    end
  end

  describe '#default_err_format' do
    subject { described_class.default_err_format }

    context 'when data has error' do
      it 'removes :err from data' do
        expect(err.key?(:err)).to be_truthy
        subject.call(err)
        expect(err.key?(:err)).to be_falsey
      end
    end

    context 'when data has no error' do
      it 'does not modify data' do
        data_clone = data.clone
        subject.call(data)
        expect(data_clone).to eq(data)
      end

      it 'returns nil' do
        expect(subject.call(data)).to be_nil
      end
    end
  end

  describe '#initialize' do
    context 'when no customization is provided' do
      it 'has a non-nil format_msg proc' do
        format_msg = subject.instance_variable_get(:@format_msg)
        expect(format_msg).to be_a(Proc)
      end

      it 'has a non-nil format_data proc' do
        format_data = subject.instance_variable_get(:@format_data)
        expect(format_data).to be_a(Proc)
      end

      it 'has a non-nil format_err proc' do
        format_err = subject.instance_variable_get(:@format_err)
        expect(format_err).to be_a(Proc)
      end

    end

    context 'when custom colors configuration is provided' do
    end
  end

  describe '._call' do
    context 'when only a message is logged' do
      let(:output) { subject._call('INFO', datetime, nil, msg: log_msg) }

      it 'returns a String' do
        expect(output).to be_a(String)
      end

      it 'finished by a new line' do
        expect(output).to end_with("\n")
      end

      it 'prints the output of format_msg' do
        format_msg = subject.instance_variable_get(:@format_msg)
        format_msg_output = format_msg.call('INFO', iso_datetime, nil, msg: log_msg)
        expect(output).to include(format_msg_output)
      end
    end

    context 'when a message and some data are provided' do
      let(:data_clone) { data.clone }
      let(:output) { subject._call('INFO', datetime, nil, data) }

      it 'prints the output of format_msg and format_data' do
        format_msg = subject.instance_variable_get(:@format_msg)
        msg_output = format_msg.call('INFO', iso_datetime, nil, data_clone)
        format_data = subject.instance_variable_get(:@format_data)
        data_output = format_data.call(data_clone)
        concatenation = ''.dup.concat(msg_output + "\n").concat(data_output + "\n")
        expect(output).to eq(concatenation)
      end
    end
  end
end
