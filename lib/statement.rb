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
    
    def self.from_scrapers
      results = []
      results << freshman_senators
      results << capuano
      results << crenshaw(2013, 0)
      results << conaway
      results << susandavis
      results << faleomavaega
      results << klobuchar
      results << lujan
      results << billnelson(year=2013)
      results.flatten
    end
    
    ## special cases for members without RSS feeds
    
    def self.capuano
      results = []
      base_url = "http://www.house.gov/capuano/news/"
      list_url = base_url + 'date.shtml'
      doc = Nokogiri::HTML(open(list_url).read)
      doc.xpath("//a").each do |link|
        if link['href'] and link['href'].include?('/pr')
          begin 
            date = Date.parse(link.text) 
          rescue 
            date = nil
          end
          results << { :source => list_url, :url => base_url + link['href'], :title => link.text.split(' ',2).last, :date => date, :domain => "www.house.gov/capuano/" }
        end
      end
      return results[0..-5]
    end
    
    def self.crenshaw(year, month)
      results = []
      year = Date.today.year if not year
      month = 0 if not month
      url = "http://crenshaw.house.gov/index.cfm/pressreleases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
      doc = Nokogiri::HTML(open(url).read)
      doc.xpath("//tr")[2..-1].each do |row|
        date_text, title = row.children.map{|c| c.text.strip}.reject{|c| c.empty?}
        next if date_text == 'Date'
        date = Date.parse(date_text)
        results << { :source => url, :url => row.children[2].children.first['href'], :title => title, :date => date, :domain => "crenshaw.house.gov" }
      end
      results
    end
    
    def self.conaway(page=1)
      results = []
      base_url = "http://conaway.house.gov/news/"
      page_url = base_url + "documentquery.aspx?DocumentTypeID=1279&Page=#{page}"
      doc = Nokogiri::HTML(open(page_url).read)
      doc.xpath("//tr")[1..-1].each do |row|
        results << { :source => page_url, :url => base_url + row.children.children[1]['href'], :title => row.children.children[1].text.strip, :date => Date.parse(row.children.children[4].text), :domain => "conaway.house.gov" }
      end
      results
    end
    
    def self.susandavis
      results = []
      base_url = "http://www.house.gov/susandavis/"
      doc = Nokogiri::HTML(open(base_url+'news.shtml').read)
      doc.search("ul")[6].children.each do |row|
        next if row.text.strip == ''
        results << { :source => base_url+'news.shtml', :url => base_url + row.children[1]['href'], :title => row.children[1].text.split.join(' '), :date => Date.parse(row.children.first.text), :domain => "house.gov/susandavis" }
      end
      results
    end
    
    def self.faleomavaega
      results = []
      base_url = "http://www.house.gov/faleomavaega/news-press.shtml"
      doc = Nokogiri::HTML(open(base_url).read)
      doc.xpath("//li[@type='disc']").each do |row|
        results << { :source => base_url, :url => "http://www.house.gov/" + row.children[0]['href'], :title => row.children[0].text.gsub(/[\x80-\xff]/,'').split('Washington, D.C.').last, :date => Date.parse(row.children[1].text.gsub(/[\x80-\xff]/,' ')), :domain => "house.gov/faleomavaega" }
      end
      results
    end
    
    def self.freshman_senators
      results = []
      ['baldwin', 'donnelly', 'flake', 'hirono','heinrich','murphy','scott','king','heitkamp','cruz','kaine'].each do |senator|
        base_url = "http://www.#{senator}.senate.gov/"
        doc = Nokogiri::HTML(open(base_url+'press.cfm?maxrows=200&startrow=1&&type=1').read)
        doc.xpath("//tr")[3..-1].each do |row|
          next if row.text.strip == ''
          results << { :source => base_url+'press.cfm?maxrows=200&startrow=1&&type=1', :url => base_url + row.children.children[1]['href'], :title => row.children.children[1].text.strip.split.join(' '), :date => Date.parse(row.children.children[0].text.gsub(/[\x80-\xff]/,'')), :domain => "#{senator}.senate.gov" }
        end
      end
      results.flatten
    end
    
    def self.klobuchar
      results = []
      base_url = "http://www.klobuchar.senate.gov/"
      [2012,2013].each do |year|
        year_url = base_url + "newsreleases.cfm?year=#{year}"
        doc = Nokogiri::HTML(open(year_url).read)
        doc.xpath("//dt").each do |row|
          results << { :source => year_url, :url => base_url + row.next.children[0]['href'], :title => row.next.text.strip.gsub(/[\x80-\xff]/,'').split.join(' '), :date => Date.parse(row.text), :domain => "klobuchar.senate.gov" }
        end
      end
      results
    end
    
    def self.lujan
      results = []
      base_url = 'http://lujan.house.gov/'
      doc = Nokogiri::HTML(open(base_url+'index.php?option=com_content&view=article&id=981&Itemid=78').read)
      doc.xpath('//ul')[1].children.each do |row|
        next if row.text.strip == ''
        results << { :source => base_url+'index.php?option=com_content&view=article&id=981&Itemid=78', :url => base_url + row.children[0]['href'], :title => row.children[0].text.gsub(/[\x80-\xff]/,'').gsub('Lujn','Lujan'), :date => nil, :domain => "lujan.house.gov" }
      end
      results
    end
    
    def self.billnelson(year=2013)
      results = []
      base_url = "http://www.billnelson.senate.gov/news/"
      year_url = base_url + "media.cfm?year=#{year}"
      doc = Nokogiri::HTML(open(year_url).read)
      doc.xpath('//li').each do |row|
        results << { :source => year_url, :url => base_url + row.children[0]['href'], :title => row.children[0].text.strip, :date => Date.parse(row.children.last.text).to_s, :domain => "billnelson.senate.gov" }
      end
      results
    end
    
    def self.roe(page=1)
      results = []
      base_url = "http://roe.house.gov/news/"
      doc = Nokogiri::HTML(open(base_url+"documentquery.aspx?DocumentTypeID=1532&Page=#{page}").read)
      doc.xpath("//span[@class='middlecopy']").each do |row|
        results << { :source => base_url+"documentquery.aspx?DocumentTypeID=1532&Page=#{page}", :url => base_url + row.children[6]['href'], :title => row.children[1].text.strip.gsub(/[\x80-\xff]/,''), :date => Date.parse(row.children[4].text.gsub(/[\x80-\xff]/,'').strip), :domain => "roe.house.gov" }
      end
      
      
    end
    
    
  end
end
