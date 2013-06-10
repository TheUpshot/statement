require 'twitter'
require 'yaml'

module Statement
  class Twitter
    
    attr_accessor :client, :timeline
    
    def initialize
      @@config = YAML.load_file("config.yml") rescue nil || {}
      @client = Twitter::Client.new(
          :consumer_key => ENV['CONSUMER_KEY'] || @@config['consumer_key'],
          :consumer_secret => ENV['CONSUMER_SECRET'] || @@config['consumer_secret'],
          :oauth_token => ENV['OAUTH_TOKEN'] || @@config['oauth_token'],
          :oauth_token_secret => ENV['OAUTH_TOKEN_SECRET'] || @@config['oauth_token_secret']
        )
    end
    
    def timeline(member_id)
      process_results(@client.user_timeline(member_id))
    end
    
    def process_results(tweets)
      results = []
      tweets.each do |tweet|
        results << { :id => tweet[:id], :body => tweet[:text], :link => tweet[:urls].first[:expanded_url], :in_reply_to_screen_name => tweet[:in_reply_to_screen_name], :tweet_number => tweet[:statuses_count], :created_time => DateTime.parse(link[:created_at]), :retweets => tweet[:retweet_count], :favorites => tweet[:favorite_count] }
      end
      results
    end
    
  end
end