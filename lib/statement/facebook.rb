require 'koala'
require 'oj'
require 'yaml'

module Statement
  class Facebook
    
    attr_accessor :graph
    
    def initialize
      @@config = YAML.load_file("config.yml") rescue nil || {}
      app_id = ENV['APP_ID'] || @@config['app_id']
      app_secret = ENV['APP_SECRET'] || @@config['app_secret']
      oauth = Koala::Facebook::OAuth.new(app_id, app_secret)
      @graph = Koala::Facebook::API.new(oauth.get_app_access_token)
    end
    
  end
end