require 'twitter'
require 'yaml'

module Statement
  class Tweets
    
    attr_accessor :client, :timeline, :bulk_timeline
    
    def initialize
      @@config = YAML.load_file("config.yml") rescue nil || {}
      @client = Twitter::Client.new(
          :consumer_key => ENV['CONSUMER_KEY'] || @@config['consumer_key'],
          :consumer_secret => ENV['CONSUMER_SECRET'] || @@config['consumer_secret'],
          :oauth_token => ENV['OAUTH_TOKEN'] || @@config['oauth_token'],
          :oauth_token_secret => ENV['OAUTH_TOKEN_SECRET'] || @@config['oauth_token_secret']
        )
    end
    
    # fetches single twitter user's timeline
    def timeline(member_id)
      process_results(client.user_timeline(member_id))
    end

    # batch lookup of users, 100 at a time
    def users(member_ids)
      client.users(member_ids)
    end
    
    # fetches latest 100 tweets from a list (derekwillis twitter acct has a public congress list)
    def bulk_timeline(list_id, list_owner=nil)
      process_results(client.list_timeline(list_owner, list_id, {:count => 100}))
    end
    
    def process_results(tweets)
      results = []
      tweets.each do |tweet|
        url = tweet[:urls].first ? tweet[:urls].first[:expanded_url] : nil
        results << { :id => tweet[:id], :body => tweet[:text], :link => url, :in_reply_to_screen_name => tweet[:in_reply_to_screen_name], :total_tweets => tweet[:user][:statuses_count], :created_time => tweet[:created_at], :retweets => tweet[:retweet_count], :favorites => tweet[:favorite_count], :screen_name => tweet[:user][:screen_name]}
      end
      results
    end

  end
end