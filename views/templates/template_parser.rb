helpers do 
	def parseData(pageData)

		#do stuff to parse data here
		pageData["thatsme"] = "fred"

		pageData["feed"]["data"].each do |feed|

			feed["picture"] = feed["picture"].gsub("_s", "_n")

		end

		return pageData

	end
	
end