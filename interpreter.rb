require 'rubygems'
require 'mechanize'
require 'ruby-progressbar'

require 'csv'
require 'open-uri'

agent = Mechanize.new


BASE_URL = "http://finance.yahoo.com/q/ao?s="
EXTENDED_URL = "+Analyst+Opinion"

MARKETS = ["nasdaq", "nyse", "amex"]
MARKETS_SIZES = [2700,3256,447]
TOTAL_TO_PROCESS = MARKETS_SIZES.inject(:+)

SYMBOL = 0
NAME = 1
SECTOR = 2
INDUSTRY = 3

CSV_OPTIONS = {
  :write_headers => true,
  :headers => %w[S N Sec Ind MR(tw) MR(lw) MR(c) MeanTar MedTar HiTar LowTar NoB]
}


MARKETS.each_with_index do |market, db_array_index|
	
	result_file_name = "#{market}-results.csv"
	file = "MARKETS/#{market}.csv"

	CSV.open(result_file_name, 'wb', CSV_OPTIONS) do |csv|
			
		total = MARKETS_SIZES[db_array_index]
		prog_market = ProgressBar.create(:title => "#{market.upcase}", :format => '%t | %a |%b>>%i| %p%%', :total => total)
		
		CSV.foreach(file, :headers => true) do |row|
			
			url = BASE_URL + row[SYMBOL] + EXTENDED_URL

			begin
				page = agent.get(url)

				mr_table = page.parser.search("table#yfncsumtab table.yfnc_datamodoutline1")[0]
				tar_table = page.parser.search("table#yfncsumtab table.yfnc_datamodoutline1")[1]
				
				if page.parser.search("div#yfi_sym_results div.error h2").text[0..31] != "There are no All Markets results" and mr_table != nil and tar_table != nil
					mr_tw = mr_table.search("td.yfnc_tabledata1")[0].text
					mr_lw = mr_table.search("td.yfnc_tabledata1")[1].text
					mr_c = mr_table.search("td.yfnc_tabledata1")[2].text

					mean_tar = tar_table.search("td.yfnc_tabledata1")[0].text
					med_tar = tar_table.search("td.yfnc_tabledata1")[1].text
					hi_tar = tar_table.search("td.yfnc_tabledata1")[2].text
					low_tar = tar_table.search("td.yfnc_tabledata1")[3].text
					nob = tar_table.search("td.yfnc_tabledata1")[4].text

					csv << [row[SYMBOL], row[NAME], row[SECTOR], row[INDUSTRY], mr_tw, mr_lw, mr_c, mean_tar, med_tar, hi_tar, low_tar, nob]
				else
					csv << [row[SYMBOL], row[NAME], row[SECTOR], row[INDUSTRY], "ERROR"]
				end
			rescue OpenURI::HTTPError => e
				csv << [url, e.message]
			end

			prog_market.increment
			
		end
	end
end