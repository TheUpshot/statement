# encoding: utf-8
require 'uri'
require 'open-uri'
require 'american_date'
require 'nokogiri'
require 'typhoeus'

module Statement
  class Feed
    
    def self.batch(urls)
      results = []
      failures = []
      hydra = Typhoeus::Hydra.new
      urls.each do |url|
        req = Typhoeus::Request.new(url)
        req.on_complete do |response|
          if response.success?
            doc = Nokogiri::XML(response.body)
            results << parse_rss(doc, url)
          else
            failures << url
          end
        end
        hydra.queue(req)
      end
      hydra.run
      [results.flatten, failures]
    end
  
    def self.open_rss(url)
      begin
        Nokogiri::XML(open(url))
      rescue
        nil
      end
    end
    
    def self.date_from_rss_item(link)
      if !link.xpath('pubDate').text.empty?
        Date.parse(link.xpath('pubDate').text)
      elsif !link.xpath('pubdate').empty?
        Date.parse(link.xpath('pubdate').text)
      else
        nil
      end
    end

    def self.from_rss(url)
      doc = open_rss(url)
      return unless doc
      parse_rss(doc, url)
    end
    
    def self.parse_rss(doc, url)
      links = doc.xpath('//item')
      return if links.empty?
      results = links.map do |link|
        abs_link = Utils.absolute_link(url, link.xpath('link').text)
        abs_link = "http://www.burr.senate.gov/public/"+ link.xpath('link').text if url == 'http://www.burr.senate.gov/public/index.cfm?FuseAction=RSS.Feed'
        abs_link = link.xpath('link').text[37..-1] if url == "http://www.johanns.senate.gov/public/?a=RSS.Feed"
        { :source => url, :url => abs_link, :title => link.xpath('title').text, :date => date_from_rss_item(link), :domain => URI.parse(url).host }
      end
      Utils.remove_generic_urls!(results)
    end
    
  end
end
