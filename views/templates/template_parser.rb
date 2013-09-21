helpers do 
	def parseData(pageData)

		#do stuff to parse data here
		pageData["thatsme"] = "fred"

		pageData["posts"]["data"].each do |feed|
			if feed["picture"]
				feed["picture"] = feed["picture"].gsub("_s", "_n")
			end
			feed["created_time"] = Date.parse(feed["created_time"]).strftime("%b %d, %Y")
		end
		
		pageData["events"]["data"].each do |event|
			if event["start_time"]
				event["start_time"] = Date.parse(event["start_time"]).strftime("%b %d, %Y %H:%m:%S%p")
			end
		end

		return pageData

	end
	
end