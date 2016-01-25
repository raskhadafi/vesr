require 'vesr/validation_digit_calculator'

module VESR
  class ReferenceBuilder
    def self.call(customer_id, invoice_id, esr_id)
      new(customer_id, invoice_id, esr_id).call
    end

    attr_reader :customer_id, :invoice_id, :esr_id

    def initialize(customer_id, invoice_id, esr_id)
      @customer_id = customer_id
      @invoice_id = invoice_id
      @esr_id = esr_id
    end

    def call
      "#{esr_id}#{formatted_customer_id}#{formatted_invoice_id}"
    end

    private

    def formatted_customer_id
      format "%0#{customer_id_length}i", customer_id
    end

    def customer_id_length
      19 - esr_id.to_s.length
    end

    def formatted_invoice_id
      format '%07i', invoice_id
    end
  end
end
