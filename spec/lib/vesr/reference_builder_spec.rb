require 'vesr/reference_builder'

RSpec.describe VESR::ReferenceBuilder do
  let(:customer_id) { 4 }
  let(:invoice_id) { 44 }
  let(:esr_id) { '12000000' }
  let(:instance) { described_class.new(customer_id, invoice_id, esr_id) }

  describe '#call' do
    subject { instance.call }

    it { is_expected.to eq('12000000000000000040000044') }
  end
end
