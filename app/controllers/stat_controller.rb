require 'hpricot'
require 'csv'
require 'open-uri'
require 'uri'

class StatController < ApplicationController

	def query
	@tab = "query"
	@errors = []
		if request.post?
		 min_date=params[:min_date].to_i
		 max_date=params[:max_date].to_i
		 inferior_to(min_date, max_date)

		 if params[:terms].blank?
		  @errors<< "You must specify terms for the query!"
		 end
		 terms= URI.escape(params[:terms])
		
		 if @errors.empty?
		  timestamp=Time.now.nsec
		  @graph = open_flash_chart_object(600,300,"/stat/plot?min_date="+min_date.to_s+"&max_date="+max_date.to_s+"&terms="+terms+"&id="+timestamp.to_s)
		 end

		end

	end

	def csv
	results=fetch_data(params[:min_date].to_i,params[:max_date].to_i, params[:terms], params[:id])

  	tsv_string = CSV.generate(:col_sep => "\t") do |tsv|
			tsv << ["Query: "+params[:terms]]
		(0..results[0].length-1).each do |i|
			tsv << [results[0][i],results[1][i]]
		end
  	end		

	send_data(tsv_string,:type => 'text/csv; charset=iso-8859-1; header=present',:filename => 'report.csv', :disposition =>'attachment', :encoding => 'utf16-le')
	end


	def plot
		table_of_results=fetch_data(params[:min_date].to_i,params[:max_date].to_i, params[:terms], params[:id])
		table_of_results_title=fetch_data(params[:min_date].to_i,params[:max_date].to_i, params[:terms]+"[Title]", params[:id])
		
		#Plot the results
    		title = Title.new("Hits for query: "+params[:terms])

		line = Line.new
		line.text = "Hits in whole text"
		line.width = 4
		line.colour = '#000099'
		line.dot_size = 5
		line.values = table_of_results[1]

		line_title = Line.new
		line_title.text = "Hits in titles"
		line_title.width = 4
		line_title.colour = '#ff0000'
		line_title.dot_size = 5
		line_title.values = table_of_results_title[1]

		y = YAxis.new
		y.set_range(0,table_of_results[1].max)
		yl = YLegend.new("Number of hits")
		yl.set_style('{font-size: 12px; color: black}')

    		x = XAxis.new
    		x.set_labels(table_of_results[0])

		chart = OpenFlashChart.new
		chart.set_title(title)
		chart.set_y_legend(yl)
		chart.add_element(line)
		chart.add_element(line_title)
		chart.y_axis = y
		chart.x_axis = x

    		render :text => chart.to_s
	end

	def about
	@tab = "about"
	end

protected

	def fetch_data(min,max,term,id)
		#Generate arrays to store results
		years=Array.new
	    	hits=Array.new

		#Fetch data from website
	    	for year in min..max
	    		url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="+URI.escape(term)+"&mindate="+year.to_s+"&maxdate="+year.to_s+"&rettype=count"
			
			#Hppricot is used for parsing
	    		doc = Hpricot(open(url).read)
			years << year.to_s
	    		hits << doc.search("//count").first.inner_html.to_i
	    	end
	results = Array.new
	results = [years,hits]
	end


	private

	def inferior_to(a,b)
		if a>b
		 @errors<< "Start date cannot be bigger than end date!"
		end
	end

end
