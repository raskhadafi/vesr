# encoding: utf-8

class EsrFile < ActiveRecord::Base
  # Access restrictions
  attr_accessible :file, :remarks

  # Default sorting
  default_scope order('created_at DESC')

  # File upload
  mount_uploader :file, EsrFileUploader
  validates :file, :presence => true

  has_many :esr_records, :dependent => :destroy

  # String
  def to_s(format = :default)
    case format
    when :long
      s = ''
      esr_records.each {|record|
        s += record.to_s + "\n"
      }
      s
    else
      "#{updated_at.strftime('%d.%m.%Y')}: #{file_identifier}"
    end
  end

  after_save :create_records

  private
  def create_records
    File.new(file.current_path).each do |line|
      if EsrRecord.supported_line?(line)
        esr_records << create_esr_record(line)
      else
        Rails.logger.info "VESR: Ignoring line #{line}"
      end
    end
  end

  def create_esr_record(line)
    record = EsrRecord.new.parse(line)
    record.save
    Rails.logger.error "VESR: Record #{record.inspect} is invalid: #{record.errors.inspect}" unless record.valid?
    record
  end
end
