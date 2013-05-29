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
      results = graph.get_connection(member_id, 'feed')
      process_results(results.select{|r| r['from']['id'] == r['link']['id'].split('_').first})
    end
    
    # given an array of congressional facebook ids, pulls feeds in slices.
    def batch(member_ids, slice)
      results = []
      member_ids.each_slice(slice) do |members|
         results << graph.batch do |batch_api| 
          members.each do |member|
            batch_api.get_connection(member, 'feed')
          end
        end
      end
      process_results(results.flatten.select{|r| r['from']['id'] == r['id'].split('_').first})
    end
    
    def process_results(links)
      results = []
      links.each do |link|
        facebook_id = link['id'].split('_').first
        results << { :id => link['id'], :body => link['message'], :link => link['link'], :title => link['name'], :type => link['type'], :status_type => link['status_type'], :created_time => DateTime.parse(link['created_time']), :updated_time => DateTime.parse(link['updated_time']), :facebook_id => facebook_id }
      end
      results
    end
    
  end
end