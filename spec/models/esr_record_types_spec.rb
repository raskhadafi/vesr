require './app/models/esr_record_types'

RSpec.describe EsrRecordTypes do
  describe '.lookup_code' do
    let(:code) { '202' }

    subject { EsrRecordTypes.lookup_code(code) }

    it { is_expected.to eq(:lsv_credit) }
  end
end
