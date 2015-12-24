module EsrRecordTypes
  RECORD_TYPES = {
    esr_e_banking_credit: '002',
    esr_e_banking_cancellation: '005',
    esr_e_banking_correction: '008',
    esr_post_office_counter_credit: '012',
    esr_post_office_counter_cancellation: '015',
    esr_post_office_counter_correction: '018',

    esr_plus_e_banking_credit: '102',
    esr_plus_e_banking_cancellation: '105',
    esr_plus_e_banking_correction: '108',
    esr_plus_post_office_counter_credit: '112',
    esr_plus_post_office_counter_cancellation: '115',
    esr_plus_post_office_counter_correction: '118',

    lsv_credit: '202',
    lsv_cancellation: '205',

    total_record_credit: '999',
    total_record_cancellation: '995',
  }

  def self.lookup_code(lookup_code)
    RECORD_TYPES.each do |name, code|
      return name if code == lookup_code
    end
  end
end
