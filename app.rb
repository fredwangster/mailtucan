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

	#define FB Auth credentials in env.rb
	def getFacebookAuth()
		response = HTTParty.get("https://graph.facebook.com/oauth/access_token?client_id=#{ENV['fb_appid']}&client_secret=#{ENV['fb_appsecret']}&grant_type=client_credentials")
		return response.parsed_response
	end

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
		access_token = getFacebookAuth()
		encoded_url = URI.encode("https://graph.facebook.com/#{fb_id}?fields=name,location,about,posts.fields(id,message,actions,created_time,updated_time,type,status_type,picture,link,source).limit(20),events.fields(description,location,id,name,owner,end_time,timezone,venue,start_time,privacy,cover)&#{access_token}")
		response = HTTParty.get(encoded_url)
		return response.to_json
	end


end

get '/' do 
   erb :home
end
################temp routes ################
## testing out ruby's mailer with default ##
get '/testpony' do
	Pony.mail({
		:to => 'shuchun.wang@gmail.com',
		:from => 'shuchun.wang@gmail.com',
		:subject => 'testing ruby mailer',
		:body => 'yoyo yippee yay.'

		})

end

get '/fromdb' do
	page = Page.find(1)
	@pageData = JSON.parse(page.fb_data)
	@newsletter_date = "September 21, 2013"
	@issue_number = "1"

	require('./views/templates/template_parser.rb')
	@pageData = parseData(@pageData)

	
	template_file= "/templates/one"
	erb template_file.to_sym
end

get '/ponyskinz' do
	@pageData = JSON.parse(File.read("./views/templates/dummydata.json"))
	@newsletter_date = "September 21, 2013"
	@issue_number = "1"

	require('./views/templates/template_parser.rb')
	@pageData = parseData(@pageData)

	template_file= "/templates/one"
	Pony.mail({
		:headers => { 'Content-Type' => 'text/html' },
		:to => 'subscribers@mailtucan.com',
		:bcc => 'atulyapandey@gmail.com, fred@pagevamp.com, vincent@pagevamp.com',
		:from => 'newsletter@mailtucan.com',
		:subject => "Weekly update #{@newsletter_date} for #{@pageData['name']}",
		:body => erb(template_file.to_sym, layout: false),
		:via => :smtp,
		:via_options => {
			:address => 'smtp.mailgun.org',
			:port => 25,
    		:enable_starttls_auto => true,
    		:user_name => 'postmaster@mailtucan.com',
    		:password => ENV['mailgun'],
    		:authentication => :plain,
    		:domain => "mailtucan.com",
		},
	})

end 
## testing skinning facebook data ##
get '/testdata/:template_url' do
	@pageData = JSON.parse(File.read("./views/templates/dummydata.json"))
	@newsletter_date = "September 21, 2013"
	@issue_number = "1"

	require('./views/templates/template_parser.rb')
	@pageData = parseData(@pageData)

	template_file= "/templates/#{params[:template_url]}"
	erb template_file.to_sym
end




################  end temp  ################


#the creator
post '/page' do
	if (!params[:fb_url])
		return {
			"error" => true,
			"message" => "Enter a Facebook URL"
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

	redirect "/page/edit/#{fb_id}"
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
		redirect "/newsletter/#{@newsletter.id}"
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
	@form_link = "http://mailtucan.herokuapp.com/form/#{@newsletter.id}"
	@embed_link = "http://mailtucan.herokuapp.com/embed/#{@newsletter.id}"
	#newsletter iframe source will be something like "mailtucan.com/embed/:newsletter_id"
	erb :embed_code

end

#subscriber. called by form to add email to subscription
post '/form/:newsletter_id' do
	#accepts :fb_id, :subscriber_email as param
	@newsletter = Newsletter.where("id = ?", params[:newsletter_id]).first
	@subscriber = Subscriber.where("subscriber_email = ?", params[:subscriber_email]).first
	if(!@subscriber)
		@subscriber = Subscriber.new
		@subscriber.subscriber_email = params[:subscriber_email]
		@subscriber.save
	end

	@subscription = Subscription.where("subscriber_id = ? AND newsletter_id = ?", @subscriber.id, params[:newsletter_id]).first
	if (!@subscription)
		@subscription = @newsletter.subscriptions.build(
						"subscriber_id" => @subscriber.id,
						"active" => true)

		@status = {
			"error"=> false,
			"message" => "Thank you for subscribing!"
		}

		erb :thankyou

		#return @status.to_json
	
	end


	@subscription.active = true
	@subscription.save

	@status = {
			"error"=> false,
			"message" => "Thank you for subscribing again!"
	}

	erb :thankyou

	#return @status.to_json

end

#form, standalone for easy sharing
get '/form/:newsletter_id' do
	@newsletter = Newsletter.where("id= ?", params[:newsletter_id]).first

	erb :form
end


#the actual embeddable form. this gets iframed
get '/embed/:newsletter_id' do
	@newsletter = Newsletter.where("id = ?", params[:newsletter_id]).first

	erb :embed
end

get '/admin' do
	

end


#the mailer
get '/mailer/:newsletter_id' do
	#if (params[:token] == ENV['token'])
		Subscription.find_each do | subscription |
			#make this more efficient... maybe 
			puts "Newsletter: #{subscription.newsletter_id} <br /> Subscriber id: #{subscription.subscriber_id}" 
			@subscriber = Subscriber.find(subscription.subscriber_id)
			@newsletter = Newsletter.find(subscription.newsletter_id)

			puts "Subscriber email: #{@subscriber.subscriber_email}"

			page = Page.find(@newsletter.page_id)
			@pageData = JSON.parse(page.fb_data)
			@newsletter_date = "September 21, 2013"
			@issue_number = "1"

			require('./views/templates/template_parser.rb')
			@pageData = parseData(@pageData)

			template_file = Template.find(@newsletter.template_id)
			template_file = "/templates/"+template_file.template_filename
			puts "#{template_file}"

			Pony.mail({
			:headers => { 'Content-Type' => 'text/html' },
			:to => 'subscribers@mailtucan.com',
			:bcc => "#{@subscriber.subscriber_email}",
			:from => 'newsletter@mailtucan.com',
			:subject => "Weekly update #{@newsletter_date} for #{@pageData['name']}",
			:body => erb(template_file.to_sym, layout: false),
			:via => :smtp,
			:via_options => {
				:address => 'smtp.mailgun.org',
				:port => 25,
	    		:enable_starttls_auto => true,
	    		:user_name => 'postmaster@mailtucan.com',
	    		:password => ENV['mailgun'],
	    		:authentication => :plain,
	    		:domain => "mailtucan.com",
			},
	})

		end
	#end

end



#unsubscriber
#TODO: generate unique hash for every subscription
get '/subscriptions/:subscription_id' do
	@subscription = Subscription.where("id = ?", params[:subscription_id])
	if(@subscription)
		@subscription.active = false
		@subscription.save

	end

	erb :unsubscribe
end


not_found do
  halt 404, 'page not found'
end

