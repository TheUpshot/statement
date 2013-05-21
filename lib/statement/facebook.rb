require 'koala'
require 'oj'
require 'yaml'

module Statement
  class Facebook
    
    attr_accessor :graph, :feed, :batch
    
    def initialize
      @@config = YAML.load_file("config.yml") rescue nil || {}
      app_id = ENV['APP_ID'] || @@config['app_id']
      app_secret = ENV['APP_SECRET'] || @@config['app_secret']
      oauth = Koala::Facebook::OAuth.new(app_id, app_secret)
      @graph = Koala::Facebook::API.new(oauth.get_app_access_token)
    end
    
    def feed(member_id)
      graph.get_connection(member_id, 'feed')
    end
    
    # given an array of congressional facebook ids, pulls feeds in batches of 50.
    def batch(member_ids)
      results = []
      member_ids.each_slice(50) do |members|
        results << graph.batch {|batch_api| members.each {|member| batch_api.get_connection(member, 'feed')}}
      end
      results
    end
  end
end