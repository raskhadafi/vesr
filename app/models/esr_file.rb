class EsrFile < ActiveRecord::Base
  # File upload
  mount_uploader :file, EsrFileUploader

  has_many :esr_records, :dependent => :destroy
  
  def to_s(format = :default)
    case format
    when :long
      esr_records.map{|record| record.to_s}.join("\n")
    else
      "#{updated_at.strftime('%d.%m.%Y')}: #{esr_records.count} Buchungen"
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
