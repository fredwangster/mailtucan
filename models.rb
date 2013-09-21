

#a page can have multiple newsletters
#----TEMP: enforce only one newsletter per page
class Page < ActiveRecord::Base
  validate :fb_id, :url, presence: true
  serialize :fb_data
  has_many :newsletters
end

#a newsletter references a page and a template
class Newsletter < ActiveRecord::Base
  belongs_to :page
  belongs_to :template
  has_many :subscriptions
end


#a template can be applied to many newsletters
class Template < ActiveRecord::Base
  has_many :newsletters
end

#a subscriber can have many subscriptions to newsletters
class Subscriber < ActiveRecord::Base
  has_many :subscriptions

end

#each subscription can be active or not
#maintains link between subscriber and newsletter
class Subscription < ActiveRecord::Base
  belongs_to :subscriber
  belongs_to :newsletter
  validate :active, presence: true
end
