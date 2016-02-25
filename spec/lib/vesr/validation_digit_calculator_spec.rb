require 'vesr/validation_digit_calculator'

RSpec.describe VESR::ValidationDigitCalculator do
  describe '.call' do
    subject { described_class.call(value) }

    context '1' do
      let(:value) { '1' }
      it { is_expected.to eq('11') }
    end

    context '12345678' do
      let(:value) { '12345678' }
      it { is_expected.to eq('123456786') }
    end

    context '12000000000000000040000044' do
      let(:value) { '12000000000000000040000044' }
      it { is_expected.to eq('120000000000000000400000448') }
    end
  end
end
