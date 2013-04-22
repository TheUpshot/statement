require "statement/version"
require 'uri'
require 'open-uri'
require 'american_date'
require 'nokogiri'

module Statement
  
  class Link
    def self.absolute_link(url, link)
      return link if link =~ /^http:\/\//

      (URI.parse(url) + link).to_s
    end

    def self.from_rss(url)
      doc = Nokogiri::XML(open(url))
      links = doc.xpath('//item')
      links.map do |link| 
        abs_link = absolute_link(url, link.xpath('link').text)
        { :source => url, :url => abs_link, :title => link.xpath('title').text, :date => link.xpath('pubDate').empty? ? nil: Date.parse(link.xpath('pubDate').text), :domain => URI.parse(link.xpath('link').text).host }
      end
    end
    
    def self.house_gop(url)
      uri = URI.parse(url)
      date = Date.parse(uri.query.split('=').last)
      doc = Nokogiri::HTML(open(url).read)
      links = doc.xpath("//ul[@id='membernews']").search('a')
      links.map do |link| 
        # return a hash
        abs_link = absolute_link(url, link["href"])
        { :source => url, :url => abs_link, :title => link.text.strip, :date => date, :domain => URI.parse(link["href"]).host }
      end
    end
    
  end
  
end
