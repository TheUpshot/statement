require "statement/version"
require 'uri'
require 'open-uri'

module Statement
  
  class Link
    
    def self.house_gop(url)
      uri = URI.parse(url)
      date = Date.parse(uri.query.split('=').last)
      doc = Nokogiri::HTML(open(url).read)
      links = doc.xpath("//ul[@id='membernews']").search('a')
      links.map{|link| {:source => source, :url => link["href"], :title => link.text.strip, :date => date, :domain => URI.parse(link["href"]).host}}
    end
    
  end
  
end
