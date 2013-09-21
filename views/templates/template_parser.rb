helpers do 
	def parseData(pageData)

		#do stuff to parse data here
		pageData["thatsme"] = "fred"

		pageData["posts"]["data"].each do |feed|
			feed["message"] = "i hacked it"

		end

		return pageData

	end
	
end