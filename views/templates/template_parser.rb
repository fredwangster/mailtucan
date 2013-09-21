helpers do 
	def parseData(pageData)

	

		if (pageData["posts"]["data"])
			pageData["posts"]["data"].each do |feed|
				if feed["picture"]
					feed["picture"] = feed["picture"].gsub("_s", "_n")
				end
				feed["created_time"] = Date.parse(feed["created_time"]).strftime("%b %d, %Y")
			end
		end

		begin
			pageData["events"]["data"].each do |event|
				if event["start_time"]
					event["start_time"] = Date.parse(event["start_time"]).strftime("%b %d, %Y %H:%m:%S%p")
				end
			end

		rescue 
			pageData["events"] = {
				"data" => []
			}
		end

		return pageData

	end
	
end
