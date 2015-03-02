# encoding: utf-8

class EsrRecord < ActiveRecord::Base
  # Access restrictions
  attr_accessible :file, :remarks

  belongs_to :esr_file

  belongs_to :booking, :dependent => :destroy, :autosave => true
  belongs_to :invoice

  # State Machine
  include AASM

  validates_presence_of :state

  aasm :column => :state do
    state :ready, :initial => true
    state :paid
    state :missing
    state :overpaid
    state :underpaid
    state :resolved
    state :duplicate

    event :write_off do
      transitions :from => :underpaid, :to => :resolved
    end

    event :resolve do
      transitions :from => :underpaid, :to => :resolved
    end

    event :book_extra_earning do
      transitions :from => [:overpaid, :missing], :to => :resolved
    end
  end

  scope :invalid, where(:state => ['overpaid', 'underpaid', 'resolved'])
  scope :unsolved, where(:state => ['overpaid', 'underpaid', 'missing'])
  scope :valid, where(:state => 'paid')


  private
  def parse_date(value)
    year  = value[0..1].to_i + 2000
    month = value[2..3].to_i
    day   = value[4..5].to_i

    return Date.new(year, month, day)
  end

  def payment_date=(value)
    write_attribute(:payment_date, parse_date(value))
  end

  def transaction_date=(value)
    write_attribute(:transaction_date, parse_date(value))
  end

  def value_date=(value)
    write_attribute(:value_date, parse_date(value))
  end

  def reference=(value)
    write_attribute(:reference, value[0..-2])
  end

  public
  def to_s
    "CHF #{amount} for client #{client_id} on #{value_date}, reference #{reference}"
  end

  def client_id
    reference[0..7]
  end

  def invoice_id
    reference[19..-1].to_i
  end

  def customer_id
    reference[8..18].to_i
  end

  def parse(line)
#    self.recipe_type       = line[0, 1]
    self.bank_pc_id        = line[3..11]
    self.reference         = line[12..38]
    self.amount            = BigDecimal.new(line[39..48]) / 100
    self.payment_reference = line[49..58]
    self.payment_date      = line[59..64]
    self.transaction_date  = line[65..70]
    self.value_date        = line[71..76]
    self.microfilm_nr      = line[77..85]
    self.reject_code       = line[86, 1]
    self.reserved          = line[87,95]
    self.payment_tax       = line[96..99]

    self
  end

  def update_remarks
    # Duplicate
    if self.state == 'duplicate'
      return
    end

    # Invoice not found
    if self.state == 'missing'
      self.remarks += ", Rechnung ##{invoice_id} nicht gefunden"
      return
    end

    # Remark if invoice should not get payment according to state
    if !(invoice.active)
      self.remarks += ", wurde bereits #{invoice.state_adverb}"
      return
    end

    # Perfect payment
    return if invoice.balance == 0

    # Paid more than once
    if (self.state == 'overpaid') && (invoice.amount == self.amount)
      self.remarks += ", mehrfach bezahlt"
      return
    end

    # Not fully paid
    if (self.state == 'underpaid')
      self.remarks += ", Teilzahlung"
      return
    end

    # Simply mark bad amount otherwise
    self.remarks += ", falscher Betrag"
  end

  def update_state
    if duplicate_of.present?
      self.state = 'duplicate'
      return
    end

    if self.invoice.nil?
      self.state = 'missing'
      return
    end

    balance = self.invoice.balance
    if balance == 0
      self.state = 'paid'
    elsif balance > 0
      self.state = 'underpaid'
    elsif balance < 0
      self.state = 'overpaid'
    end
  end

  def self.update_unsolved_states
    self.unsolved.find_each do |e|
      e.update_state
      e.save
    end
  end

  # Invoices
  before_create :assign_invoice, :create_esr_booking, :update_state, :update_remarks, :update_invoice_state

  private
  def assign_invoice
    # Prepare remarks to not be null
    self.remarks ||= ''

    self.remarks += "Referenz #{reference}"

    if Invoice.exists?(invoice_id)
      self.invoice_id = invoice_id
    elsif Invoice.column_names.include?(:imported_esr_reference) && imported_invoice = Invoice.find(:first, :conditions => ["imported_esr_reference LIKE concat(?, '%')", reference])
      self.invoice = imported_invoice
    end
  end

  def vesr_account
    BankAccount.find_by_esr_id(client_id)
  end

  # Tries to find a record this would duplicate
  def duplicate_of
    EsrRecord.where(:reference => reference, :bank_pc_id => bank_pc_id, :amount => amount, :payment_date => payment_date, :transaction_date => transaction_date).first
  end

  def create_esr_booking
    return if duplicate_of.present?

    if invoice
      esr_booking = invoice.bookings.build
      debit_account = invoice.balance_account
    else
      esr_booking = Booking.new
      debit_account = DebitInvoice.balance_account
    end

    esr_booking.update_attributes(
      :amount         => amount,
      :debit_account  => debit_account,
      :credit_account => vesr_account,
      :value_date     => value_date,
      :title          => "VESR Zahlung",
      :comments       => remarks
    )

    esr_booking.save

    self.booking = esr_booking

    return esr_booking
  end

  def update_invoice_state
    if invoice
      # Only call if callback is available
      return unless invoice.respond_to?(:calculate_state)

      invoice.calculate_state
      invoice.save
    end
  end

  public
  def create_write_off_booking
    invoice.write_off("Korrektur nach VESR Zahlung").save
  end

  def create_extra_earning_booking(comments = nil)
    if invoice
      invoice.book_extra_earning("Korrektur nach VESR Zahlung").save
    else
      Booking.create(:title => "Ausserordentlicher Ertrag",
                   :comments => comments || "Zahlung kann keiner Rechnung zugewiesen werden",
                   :amount => self.amount,
                   :debit_account  => Account.find_by_code(Invoice.settings['invoices.extra_earnings_account_code']),
                   :credit_account => Account.find_by_code(Invoice.settings['invoices.balance_account_code']),
                   :value_date => Date.today)
    end
  end
end
