RSpec.describe Ougai::Formatters::Colors do

  let(:red)   { Ougai::Formatters::Colors::RED }
  let(:reset) { Ougai::Formatters::Colors::RESET }

  describe '#color_text' do
    let(:dummy_text) { 'some dummy text' }
  
    context 'color is nil' do
      it 'raw text is returned' do
        uncolored_text = Ougai::Formatters::Colors.color_text(nil, dummy_text)
        expect(uncolored_text).to eq(dummy_text)
      end
    end

    context 'color is provided' do
      it 'text is properly colored' do
        colored_text = Ougai::Formatters::Colors.color_text(red, dummy_text)
        expect(colored_text).to eq(red + dummy_text + reset)
      end
    end
  end

end
