module VESR
  class ValidationDigitCalculator
    # Defined at http://www.pruefziffernberechnung.de/E/Einzahlungsschein-CH.shtml

    ESR9_TABLE = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5]

    def self.call(value)
      value = value.to_s

      digit = 0
      value.split('').each do |char|
        current_digit = digit + char.to_i
        digit = ESR9_TABLE[current_digit % 10]
      end
      digit = (10 - digit) % 10

      "#{value}#{digit}"
    end
  end
end
