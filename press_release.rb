require 'net/http'
require 'nokogiri'
require 'json'
require 'date'

class Scraper

	def ids_request
		uri = URI.parse("https://www.nasa.gov/api/2/ubernode/479003")
		Net::HTTP.get_response(uri)
	end

	def parse_nokogiri(html)
		Nokogiri::HTML(html)
	end

	def json_parsing(response)
		JSON.parse(response.body)
	end

	def parser
		response = ids_request
		data = json_parsing(response)
		page = parse_nokogiri(data["_source"]["body"])
		article = page.css('p').reject{|e| e.text.include? '-end-'}.map(&:text).join(' ')
		{
			:title => data["_source"]["title"],
			:date => Date.parse(data["_source"]["promo-date-time"]).to_date.to_s,
			:release_no => data["_source"]["release-id"],
			:article => article.split.join(' ')
		}
	end

end
obj = Scraper.new
puts obj.parser

