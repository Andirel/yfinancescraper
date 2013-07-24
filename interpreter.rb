require 'rubygems'
require 'mechanize'

require 'csv'
require 'open-uri'

agent = Mechanize.new

BASE_URL = "http://finance.yahoo.com/q/ao?s="
EXTENDED_URL = "+Analyst+Opinion"

DB_ARRAY = ["nasdaq", "nyse", "amex"]

SYMBOL = 0
NAME = 1
SECTOR = 2
INDUSTRY = 3

CSV_OPTIONS = {
  :write_headers => true,
  :headers => %w[S N Sec Ind MR(tw) MR(lw) MR(c) MeanTar MedTar HiTar LowTar NoB]
}

(0..2).each do |db_array_index|

	result_file_name = DB_ARRAY[db_array_index] + "-results.csv"
	file = "MARKETS/" + DB_ARRAY[db_array_index] + ".csv"

	CSV.open(result_file_name, 'wb', CSV_OPTIONS) do |csv|
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
		end
	end
end