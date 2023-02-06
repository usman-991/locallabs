require 'google_drive'
require 'pdf-reader'

class Scraper

  def download
    session = GoogleDrive::Session.from_config('client_secret.json')
    folder = session.file_by_id("1v8kAzirygnGsKm4X0eX_OhNgFPw865aQ")
    folder.files.each_with_index do |file|
      file_id = file.id
      file_name = file.title
      p file_name
      file.download_to_file("#{file_name.split.join("_")}")
    end
  end

  def find_index(check_string)
    check = @lines.select{|e| e.include? "#{check_string}"}
    @lines.index check[0]
  end

  def is_wrong_file
    (@document.include? "Judgment for Costs of" and @document.include? "Appointed Attorney") ? true : false
  end

  def fetch_pettionr
    cost_index = find_index("Judgment for Costs of")
    extra_text = @lines[cost_index-2].split(",").last
    petitioner = @lines[cost_index-2].gsub(extra_text,'').strip
    petitioner[-1] == ',' ?  petitioner[0..-2] : petitioner
  end

  def fetch_state
    @lines.first.split[-3..-1].join(" ")
  end

  def format_date(date_array)
    year = date_array.last.size < 3 ? "20#{date_array.last}" : date_array.last
    month = date_array[1].size == 1 ? "0#{date_array[1]}" : date_array[1]
    day = date_array[0].size == 1 ? "0#{date_array[0]}" : date_array[0]
    "#{year}-#{month}-#{day}"
  end

  def extract_notic_date
    line_index = find_index("Date of Notice:")
    formatted_date = format_date(@lines[line_index].scan(/\d+/))
    Date.parse(formatted_date).to_date.to_s
  end

  def fetch_amount
    @document.scan(/[$]\d+[,]?\d+[.]?\d+/).flatten.first
  end

  def parser
    pdf_files = Dir["*.pdf"]
    response_array = []
    pdf_files.each do |pdf_file|
      puts pdf_file
      reader = PDF::Reader.new(pdf_file)
      @document = reader.pages.first.text
      next unless is_wrong_file
      @lines = @document.scan(/^.+/)
      response_array << {
        :petitioner => fetch_pettionr,
        :state =>  fetch_state,
        :amount => fetch_amount,
        :date => extract_notic_date,
        :file_name => pdf_file
      }
    end
    response_array
  end

end
obj = Scraper.new
obj.download
puts obj.parser