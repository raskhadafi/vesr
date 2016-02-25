require 'vesr/reference_builder'

RSpec.describe VESR::ReferenceBuilder do
  let(:customer_id) { 4 }
  let(:invoice_id) { 44 }
  let(:esr_id) { '12000000' }
  let(:instance) { described_class.new(customer_id, invoice_id, esr_id) }

  describe '.call' do
    let(:reference_builder_double) { instance_double(described_class) }

    it 'initializes a new instance and calls `#call`' do
      expect(described_class).
        to receive(:new).with(customer_id, invoice_id, esr_id).and_return(reference_builder_double)
      expect(reference_builder_double).to receive(:call)
      described_class.call(customer_id, invoice_id, esr_id)
    end
  end

  describe '#call' do
    subject { instance.call }

    it { is_expected.to eq('12000000000000000040000044') }
  end
end
