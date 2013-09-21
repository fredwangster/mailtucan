#Require bundler gem and call Bundler.require to load in all gemsi
require 'bundler'
Bundler.require

#for URI parsing
require 'uri'
require './models.rb'

#for passwords, etc. Replaced with "heroku config" on server
require './env' if File.exists?('env.rb')

ActiveRecord::Base.establish_connection(
	ENV['DATABASE_URL']  || "sqlite3:///mailtucan.db")



helpers do
	def getFacebookId(url) 
		#parseURL to get ID
		parseUrl = URI(url)
		if (url.split('.').count == 1) then
			id = url 
		else
			splitted = parseUrl.path.split('/')
			if (splitted.count >= 3) then
				id = splitted[splitted.count]
			else
				id = splitted[1]
			end
		end
		return id
	end

	def getFacebookType(fb_id)
		response = HTTParty.get("http://graph.facebook.com/#{fb_id}")
		if (response["first_name"])
			type = "profile"
		elsif (response["privacy"])
			type = "group"
		else
			type = "page"
		end

		return type
	end

	def getFacebookPosts(fb_id)
		response = HTTParty.get("http://graph.facebook.com/#{fb_id}?fields=feed.fields(id,message,actions,created_time,updated_time,type,status_type).limit(100)")
		return response.to_json
	end


end

get '/' do 
   erb :home
end
################temp routes ################
## crappy fix to populate templates table ##
get '/migrate' do
	config = JSON.parse(File.read("./views/templates/templates.json"))
	templates = config["templates"]
	templates.each do |template|
		puts template["template_filename"]
		@c_temp = Template.where("template_filename = ?", template["template_filename"]).first
		unless(@c_temp)
			@n_temp = Template.new
			@n_temp.template_name = template["template_name"]
			@n_temp.template_filename = template["template_filename"]
			@n_temp.save
		end
		
	end
	"hello"
end


## testing out ruby's mailer with default ##
get '/testpony' do
	Pony.mail({
		:to => 'shuchun.wang@gmail.com',
		:from => 'shuchun.wang@gmail.com',
		:subject => 'testing ruby mailer',
		:body => 'yoyo yippee yay.'

		})

end

################  end temp  ################


#the creator
post '/page' do
	if (!params[:fb_url])
		return {
			"error" => true,
			"message" => "Invalid Facebook URL detected"
			}.to_json
	end


	#accepts :fb_url as param
	isFacebookUrl = /facebook\.com/ =~ params[:fb_url]
	hasIllegalChars = /[\[\]]/ =~ params[:fb_url]

	if (!isFacebookUrl || hasIllegalChars) then
   		"malformed url"
	else
		"good to go"
	end

	#parse facebook url for id
	fb_id = getFacebookId(params[:fb_url])

	#query graph api for latest posts, fb_id
	fb_data = getFacebookPosts(fb_id)
	
	#if fb_id found, update with new data
	@page = Page.where("fb_id = ?", fb_id).first
	if (@page)
		@page.fb_data = fb_data
		@page.save
	
	#otherwise, create DB entry 
	else
		@page = Page.new 
		@page.fb_id = fb_id
		@page.fb_data = fb_data
		@page.send_last = Time.now

		#weekly email
		@page.send_next = Time.now + (7*24*60*60)
		@page.url = fb_id
		@page.save

		@newsletter = @page.newsletters.build(
								"fb_id" => fb_id)
		@newsletter.save
	end

	return {
		"error" => false,
		"fb_id" => fb_id
		}.to_json

end

#the template selector
get '/page/edit/:fb_id' do
	#display templates available
	@templates = Template.all
	@fb_id = params[:fb_id]
	erb :templates_select
	
end

#save selected template
post '/page/edit/:fb_id' do
	#accepts template_id as param
	if(params[:template_id])
		#update db with chosen template
		@newsletter = Newsletter.where("fb_id = ?", params[:fb_id]).first
		@newsletter.template_id = params[:template_id]
		@newsletter.save
		return {
			"error"	=> false,
			"newsletter_id" => @newsletter.id
		}.to_json
	else

		"Bad Request"
	end



	#redirect to /newsletter/:newsletter_id for embed code 
end

#get newsletter embed code
get '/newsletter/:newsletter_id' do
	
	@newsletter = Newsletter.where("id = ?", params[:newsletter_id]).first

	#newsletter iframe source will be something like "mailtucan.com/embeddable/:newsletter_id"
	erb :embed_code

end

#subscriber. called by form to add email to subscription
post '/form/:newsletter_id' do
	#accepts :fb_id, :subscriber_email as param
	@newsletter = Newsletter.where("newsletter_id = ?", params[:newsletter_id]).first
	@subscriber = Subscriber.where("subscriber_email = ?", params[:subscriber_email]).first
	if(!@subscriber)
		@subscriber = Subscriber.new
		@subscriber.email = params[:subscriber_email]
		@subscriber.save
	end
		@subscription = @newsletter.subscriptions.build(
						"subscriber_id" => @subscriber.subscriber_id,
						"active" => true)

	return {
		"error"=> false,
		"message" => "Thank you for subscribing!"
	}.to_json
	
end

#form, standalone for easy sharing
get '/form/:newsletter_id' do
	@newsletter = Newsletter.where("newsletter_id = ?", params[:newsletter_id])

	erb :form
end


#the actual embeddable form. this gets iframed
get '/embed/:newsletter_id' do
	@newsletter = Newsletter.where("newsletter_id = ?", params[:newsletter_id])

	erb :embed
end



#the mailer
post '/mailer/:newsletter_id' do
	#accepts :token as param

	#check for token ==> NOT IN GITHUB

	#pull the correct template info

	#call mail script

end



#unsubscriber
#TODO: generate unique hash for every subscription
get '/subscriptions/:subscription_id' do
	@subscription = Subscription.where("subscription_id = ?", params[:subscription_id])
	if(@subscription)
		@subscription.active = false
		@subscription.save
	end

	erb :unsubscribe
end


not_found do
  halt 404, 'page not found'
end

