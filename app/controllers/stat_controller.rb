require 'hpricot'
require 'open-uri'

class StatController < ApplicationController

	def query
	@errors = []
		if request.post?
		 min_date=params[:min_date].to_i
		 max_date=params[:max_date].to_i
		 inferior_to(min_date, max_date)

		 if params[:terms].blank?
		  @errors<< "You must specify terms for the query!"
		 end
		 terms= u params[:terms]
		
		 if @errors.empty? 
		  @graph = open_flash_chart_object(600,300,"/stat/generate_graph?min_date="+params[:min_date]+"&max_date="+params[:max_date]+"&terms="+terms)
		 end

		end
	end

	def generate_graph
		#GET parameters
		min=params[:min_date].to_i
		max=params[:max_date].to_i
		term=params[:terms]
		print term

		#Generate arrays to store results
		years=Array.new
	    	results=Array.new

		#Fetch data from website
	    	for year in min..max
	    		url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="+term+"&mindate="+year.to_s+"&maxdate="+(year).to_s+"&rettype=count"
			
			#Hppricot is used for parsing
	    		doc = Hpricot(open(url).read)
			years << year.to_s
	    		results << doc.search("//count").first.inner_html.to_i
	    	end

		#Plot the results

    		title = Title.new("Bar on-click Example")

		line = Line.new
		line.width = 4
		line.dot_size = 5
		line.values = results

		y = YAxis.new
		y.set_range(0,results.max)

    		x = XAxis.new
    		x.set_labels(years)

		chart = OpenFlashChart.new
		chart.set_title(title)
		chart.add_element(line)
		chart.y_axis = y
		chart.x_axis = x

    		render :text => chart.to_s
	end

	private

	def inferior_to(a,b)
		if a>b
		 @errors<< "Start date cannot be bigger than end date!"
		end
		
	end

end
