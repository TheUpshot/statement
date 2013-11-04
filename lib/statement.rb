require "statement/version"
require "statement/feed"
require "statement/scraper"
require "statement/utils"
require "statement/facebook"
require "statement/tweets"
require "yaml"

module Statement
  extend Utils
   @config = {
              :app_id => nil,
              :app_secret => nil,
              :nyt_congress_api_key => nil,
              :consumer_key => nil,
              :consumer_secret => nil,
              :oauth_token => nil,
              :oauth_token_secret => nil 
            }

  @valid_config_keys = @config.keys

  # Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym}
  end

  # Configure through yaml file
  def self.configure_with(path_to_yaml_file)
    begin
      config = YAML::load(IO.read(path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end

    configure(config)
  end

  def self.config
    @config
  end
end
