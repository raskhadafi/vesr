require 'action_view/helpers/translation_helper'
require 'action_view/helpers'

module Prawn
  module EsrRecipe

    include ActionView::Helpers::TranslationHelper

    def draw_account_detail(bank, sender, print_payment_for)
      text bank.vcard.full_name
      text bank.vcard.postal_code + " " + bank.vcard.locality

      text " "
      if print_payment_for
        text I18n::translate(:biller, :scope => "activerecord.attributes.invoice")
      else
        text " "
      end
      text " "

      draw_address sender.vcard
    end

    # Draws the full address of a vcard
    def draw_address(vcard)
      lines = [vcard.full_name, vcard.extended_address, vcard.street_address, vcard.post_office_box, "#{vcard.postal_code} #{vcard.locality}"]
      lines = lines.map {|line| line.strip unless (line.nil? or line.strip.empty?)}.compact

      lines.each do |line|
        text line
      end
    end

    def draw_account(account)
      bounding_box [cm2pt(2.6), bounds.top - cm2pt(3.4)], :width => cm2pt(2.5) do
        font_size 9 do
          text account.pc_id
        end
      end
    end

    def draw_amount(amount)
      font_size 10 do
        bounding_box [0, bounds.top - cm2pt(4.2)], :width => cm2pt(3.6) do
          text sprintf('%.0f', amount.floor), :align => :right, :character_spacing => 1
        end

        bounding_box [cm2pt(4.7), bounds.top - cm2pt(4.2)], :width => cm2pt(1) do
          text sprintf('%02.0f', amount * 100 % 100), :character_spacing => 1
        end
      end
    end

    # VESR form
    # =========
    def esr_recipe(invoice, account, sender, print_payment_for)
      bounding_box [cm2pt(0.4), cm2pt(9.6)], :width => cm2pt(5) do
        indent cm2pt(0.2) do
          draw_account_detail(account.bank, sender, print_payment_for)
        end
        draw_account(account)
        draw_amount(invoice.amount)

        bounding_box [cm2pt(0.2), bounds.top - cm2pt(5.2)], :width => cm2pt(5) do
          text esr9_reference(invoice, account), :size => 7

          text " "

          draw_address invoice.customer.vcard
        end
      end

      bounding_box [cm2pt(6.4), cm2pt(9.6)], :width => cm2pt(5) do
        draw_account_detail(account.bank, sender, print_payment_for)
        draw_account(account)
        draw_amount(invoice.amount)
      end

      font_size 10 do
        character_spacing 1.1 do
          draw_text esr9_reference(invoice, account), :at => [cm2pt(12.7), cm2pt(6.8)]
        end
      end

      bounding_box [cm2pt(12.7), cm2pt(5.5)], :width => cm2pt(7.5) do
        draw_address(invoice.customer.vcard)
      end

      # ESR-Reference
      if ::Rails.root.join('data/ocrb10.ttf').exist?
        ocr_font = ::Rails.root.join('data/ocrb10.ttf')
      else
        ocr_font = "Helvetica"
        ::Rails.logger.warn("No ocrb10.ttf found for ESR reference in #{::Rails.root.join('data')}!")
      end

      font ocr_font, :size => 11 do
        character_spacing 0.5 do
          draw_text esr9(invoice, account), :at => [cm2pt(6.7), cm2pt(1.7)]
        end
      end
    end

    def draw_esr(invoice, account, sender, print_payment_for = true)
      float do
        canvas do
          font_size 8 do
            esr_recipe(invoice, account, sender, print_payment_for)
          end
        end
      end
    end

    private
    # ESR helpers
    def esr9(invoice, esr_account)
      esr9_build(invoice.amount, invoice, esr_account.pc_id, esr_account.esr_id)
    end

    def esr9_reference(invoice, esr_account)
      esr9_format(esr9_add_validation_digit(esr_number(esr_account.esr_id, invoice.customer.id, invoice.id)))
    end

    def esr9_build(esr_amount, invoice, biller_id, esr_id)
      # 01 is type 'Einzahlung in CHF'
      amount_string = "01#{sprintf('%011.2f', esr_amount).delete('.')}"
      id_string = esr_number(esr_id, invoice.customer.id, invoice.id)
      biller_string = esr9_format_account_id(biller_id)

      "#{esr9_add_validation_digit(amount_string)}>#{esr9_add_validation_digit(id_string)}+ #{biller_string}>"
    end

    def esr_number(esr_id, customer_id, invoice_id)
      customer_id_length = 19 - esr_id.to_s.length
      esr_id.to_s + sprintf("%0#{customer_id_length}i", customer_id).delete(' ') + sprintf('%07i', invoice_id).delete(' ')
    end

    def esr9_add_validation_digit(value)
      # Defined at http://www.pruefziffernberechnung.de/E/Einzahlungsschein-CH.shtml
      esr9_table = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5]
      digit = 0
      value.split('').map{|c| digit = esr9_table[(digit + c.to_i) % 10]}
      digit = (10 - digit) % 10

      "#{value}#{digit}"
    end

    def esr9_format(reference_code)
      # Drop all leading zeroes
      reference_code.gsub!(/^0*/, '')

      # Group by 5 digit blocks, beginning at the right side
      reference_code.reverse.gsub(/(.....)/, '\1 ').reverse
    end

    # Formats an account number for ESR
    #
    # Account numbers for ESR should have the following format:
    # XXYYYYYYZ, where the number of digits is fixed. We support
    # providing the number in the format XX-YYYY-Z which is more
    # common in written communication.
    def esr9_format_account_id(account_id)
      (pre, main, post) = account_id.split('-')

      sprintf('%02i%06i%1i', pre.to_i, main.to_i, post.to_i)
    end
  end
end
