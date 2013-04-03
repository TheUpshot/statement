require "statement/version"
require 'uri'
require 'open-uri'
require 'american_date'
require 'nokogiri'

module Statement
  
  class Link
    
    def self.from_rss(url)
      doc = Nokogiri::XML(open(url))
      links = doc.xpath('//item')
      links.map{|link| {:source => url, :url => link.xpath('link').text, :title => link.xpath('title').text, :date => Date.parse(link.xpath('pubDate').text), :domain => URI.parse(link.xpath('link').text).host }}
    end
    
    def self.house_gop(url)
      uri = URI.parse(url)
      date = Date.parse(uri.query.split('=').last)
      doc = Nokogiri::HTML(open(url).read)
      links = doc.xpath("//ul[@id='membernews']").search('a')
      links.map{|link| {:source => url, :url => link["href"], :title => link.text.strip, :date => date, :domain => URI.parse(link["href"]).host}}
    end
    
  end
  
end
