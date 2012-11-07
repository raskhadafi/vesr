# encoding: utf-8

class EsrFile < ActiveRecord::Base
  # Access restrictions
  attr_accessible :file, :remarks

  # Default sorting
  default_scope order('created_at DESC')

  # File upload
  mount_uploader :file, EsrFileUploader

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
    File.new(file.current_path).each {|line|
      self.esr_records << EsrRecord.new.parse(line) unless line[0..2] == '999'
    }
  end
end
