require 'action_view/helpers/translation_helper'
require 'action_view/helpers'

require 'vesr/reference_builder'
require 'vesr/validation_digit_calculator'

module Prawn
  module EsrRecipe

    include ActionView::Helpers::TranslationHelper

    def draw_account_detail(bank, sender, print_payment_for)
      if bank
        text bank.vcard.full_name
        text bank.vcard.postal_code + " " + bank.vcard.locality
      end

      text " "
      if print_payment_for
        text I18n::translate(:biller, :scope => "activerecord.attributes.invoice")
      else
        text " "
      end
      text " "

      draw_address sender.vcard
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
        indent cm2pt(0.4) do
          draw_account_detail(account.bank, sender, print_payment_for)
        end
        draw_account(account)
        draw_amount(invoice.balance.currency_round)

        bounding_box [cm2pt(0.4), bounds.top - cm2pt(5.2)], :width => cm2pt(5) do
          text esr9_reference(invoice, account), :size => 7

          text " "

          draw_address invoice.customer.vcard
        end
      end

      bounding_box [cm2pt(6.4), cm2pt(9.6)], :width => cm2pt(5) do
        draw_account_detail(account.bank, sender, print_payment_for)
        draw_account(account)
        draw_amount(invoice.balance.currency_round)
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
          font 'Helvetica', :size => 8 do
            esr_recipe(invoice, account, sender, print_payment_for)
          end
        end
      end
    end

    private
    # ESR helpers
    def esr9(invoice, esr_account)
      esr9_build(invoice.balance.currency_round, invoice, esr_account.pc_id, esr_account.esr_id)
    end

    def esr9_reference(invoice, esr_account)
      esr_number = VESR::ReferenceBuilder.call(invoice.customer.id, invoice.id, esr_account.esr_id)
      esr9_format VESR::ValidationDigitCalculator.call(esr_number)
    end

    def esr9_build(esr_amount, invoice, biller_id, esr_id)
      # 01 is type 'Einzahlung in CHF'
      amount_string = "01#{sprintf('%011.2f', esr_amount).delete('.')}"
      id_string = VESR::ReferenceBuilder.call(invoice.customer.id, invoice.id, esr_id)
      biller_string = esr9_format_account_id(biller_id)

      "#{VESR::ValidationDigitCalculator.call(amount_string)}>#{VESR::ValidationDigitCalculator.call(id_string)}+ #{biller_string}>"
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
