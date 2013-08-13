require 'rubygems'
require 'mechanize'
require 'ruby-progressbar'
require 'colorize'

require 'csv'
require 'open-uri'

agent = Mechanize.new

URL = "http://finance.yahoo.com/q/ao?s=GDI+Analyst+Opinion"

SYMBOL = 0
NAME = 1
SECTOR = 2
INDUSTRY = 3

CSV_OPTIONS = {
  :write_headers => true,
  :headers => %w[Ticker Name Sector Industry Price Beta MR(tw) MR(lw) MR(c) MeanTar MedTar HiTar LowTar NoB]
}

def result_file_name 
	return "test-results.csv"
end

CSV.open(result_file_name, 'wb', CSV_OPTIONS) do |csv|
	
	begin
		ao_page = agent.get(URL)
		if ao_page.parser.search("div#yfi_sym_results div.error h2").text[0..31] != "There are no All Markets results" and ao_page.parser.search("div#yfi_sym_lookup_results h1").text != "Get Quotes Results for GDI"
			mr_table = ao_page.parser.search("table#yfncsumtab table.yfnc_datamodoutline1")[0]
			tar_table = ao_page.parser.search("table#yfncsumtab table.yfnc_datamodoutline1")[1]
				
			if mr_table != nil and tar_table != nil
				mr_tw = mr_table.search("td.yfnc_tabledata1")[0].text
				mr_lw = mr_table.search("td.yfnc_tabledata1")[1].text
				mr_c = mr_table.search("td.yfnc_tabledata1")[2].text

				mean_tar = tar_table.search("td.yfnc_tabledata1")[0].text
				med_tar = tar_table.search("td.yfnc_tabledata1")[1].text
				hi_tar = tar_table.search("td.yfnc_tabledata1")[2].text
				low_tar = tar_table.search("td.yfnc_tabledata1")[3].text
				nob = tar_table.search("td.yfnc_tabledata1")[4].text
			else
				mr_tw = ""
				mr_lw = ""
				mr_c = ""
				mean_tar = ""
				med_tar = ""
				hi_tar = ""
				low_tar = ""
				nob = ""
			end
		end

		## OPENS STOCK SUMMARY PAGE TO GET PRICE
		begin
			sum_page = agent.get(URL)
			if sum_page.parser.search("div#yfi_sym_results div.error h2").text[0..31] != "There are no All Markets results" and ao_page.parser.search("div#yfi_sym_lookup_results h1").text != "Get Quotes Results for GDI"
				price_id = "yfs_184_" + row[SYMBOL]
				price = sum_page.parser.search("div#yfi_rt_quote_summary div.yfi_rt_quote_summary_rt_top p span span")[0].text
				# TO-DO: Add validation that it is BETA in the table
				beta_row = sum_page.parser.search("div#yfi_quote_summary_data table#table1")[0]
				beta = beta_row.search("td.yfnc_tabledata1")[5].text
			else
				price = "FREE"
				beta = ""
			end
		end

		puts [price, beta, mr_tw, mr_lw, mr_c, mean_tar, med_tar, hi_tar, low_tar, nob].to_s.green

		csv << [price, beta, mr_tw, mr_lw, mr_c, mean_tar, med_tar, hi_tar, low_tar, nob]
	end
end