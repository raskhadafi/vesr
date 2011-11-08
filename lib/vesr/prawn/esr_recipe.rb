require 'action_view/helpers/translation_helper'
require 'action_view/helpers'

module Prawn
  module EsrRecipe

    include ActionView::Helpers::TranslationHelper

    def esr_recipe(invoice, esr_account, sender, print_payment_for? = true)
      # VESR form
      # =========
      bank = esr_account.bank
      amount = invoice.amount

      font_size 8
      bounding_box [cm2pt(0.2), cm2pt(8.8)], :width => cm2pt(5) do
        text bank.vcard.full_name
        text bank.vcard.postal_code + " " + bank.vcard.locality

        text " "
        if print_payment_for?
          text I18n::translate(:biller, :scope => "activerecord.attributes.invoice")
        else
          text " "
        end
        text " "

        vcard = sender.vcard
        text vcard.full_name
        text vcard.extended_address if vcard.extended_address.present?
        text vcard.street_address if vcard.street_address
        text vcard.postal_code + " " + vcard.locality if vcard.postal_code and vcard.locality

        move_down cm2pt(0.8)
        indent cm2pt(2.3) do
          font_size 9 do
            text esr_account.pc_id
          end
        end
      end

      bounding_box [0, cm2pt(4.5)], :width => cm2pt(3.5) do
        font_size 9 do
          text sprintf('%.0f', amount.floor), :align => :right, :character_spacing => 1
        end
      end

      bounding_box [cm2pt(4.7), cm2pt(4.5)], :width => cm2pt(1) do
        font_size 9 do
          text sprintf('%02.0f', amount * 100 % 100), :character_spacing => 1
        end
      end

      bounding_box [cm2pt(0.2), cm2pt(3.2)], :width => cm2pt(5) do
        text esr9_reference(invoice, esr_account)

        text " "

        vcard = invoice.customer.vcard
        text vcard.full_name
        text vcard.extended_address if vcard.extended_address
        text vcard.street_address if vcard.street_address
        text vcard.postal_code + " " + vcard.locality if vcard.postal_code and vcard.locality
      end

      bounding_box [cm2pt(6), cm2pt(8.8)], :width => cm2pt(5) do
        text bank.vcard.full_name
        text bank.vcard.postal_code + " " + bank.vcard.locality

        text " "
        if print_payment_for?
          text I18n::translate(:biller, :scope => "activerecord.attributes.invoice")
        else
          text " "
        end
        text " "

        vcard = sender.vcard
        text vcard.full_name
        text vcard.extended_address if vcard.extended_address.present?
        text vcard.street_address if vcard.street_address
        text vcard.postal_code + " " + vcard.locality if vcard.postal_code and vcard.locality

        move_down cm2pt(0.8)
        indent cm2pt(2.6) do
          font_size 9 do
            text esr_account.pc_id
          end
        end
      end

      bounding_box [cm2pt(6), cm2pt(4.5)], :width => cm2pt(3.5) do
        font_size 9 do
          text sprintf('%.0f', amount.floor), :align => :right, :character_spacing => 1
        end
      end

      bounding_box [cm2pt(10.8), cm2pt(4.5)], :width => cm2pt(1) do
        font_size 9 do
          text sprintf('%02.0f', amount * 100 % 100), :character_spacing => 1
        end
      end

      font_size 10 do
        draw_text esr9_reference(invoice, esr_account), :at => [cm2pt(12.3), cm2pt(5.9)], :character_spacing => 1.1
      end

      bounding_box [cm2pt(12.1), cm2pt(4.5)], :width => cm2pt(7.5) do
        vcard = invoice.customer.vcard
        text vcard.honorific_prefix if vcard.honorific_prefix
        text vcard.full_name
        text vcard.extended_address if vcard.extended_address.present?
        text vcard.street_address if vcard.street_address
        text vcard.postal_code + " " + vcard.locality if vcard.postal_code and vcard.locality
      end

      # ESR-Reference
      font_size 11
      font ::Rails.root.join('data/ocrb10.ttf') if FileTest.exists?(::Rails.root.join('data/ocrb10.ttf'))

      draw_text esr9(invoice, esr_account), :at => [cm2pt(6.3), cm2pt(0.9)]
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

    def esr9_format_account_id(account_id)
      (pre, main, post) = account_id.split('-')

      sprintf('%02i%06i%1i', pre, main, post)
    end
  end
end
