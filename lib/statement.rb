# encoding: utf-8
require "statement/version"
require 'uri'
require 'open-uri'
require 'american_date'
require 'nokogiri'

module Statement
  
  class Link
    def self.absolute_link(url, link)
      return link if link =~ /^http:\/\//
      ("http://"+URI.parse(url).host + "/"+link).to_s
    end
    
    def self.open_rss(url)
      begin
        Nokogiri::XML(open(url))
      rescue
        nil
      end
    end
    
    def self.open_html(url)
      begin
        Nokogiri::HTML(open(url).read)
      rescue
        nil
      end
    end
    
    def self.date_from_rss_item(link)
      if !link.xpath('pubDate').text.blank?
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
      links = doc.xpath('//item')
      links.map do |link|
        abs_link = absolute_link(url, link.xpath('link').text)
        abs_link = "http://www.burr.senate.gov/public/"+ link.xpath('link').text if url == 'http://www.burr.senate.gov/public/index.cfm?FuseAction=RSS.Feed'
        { :source => url, :url => abs_link, :title => link.xpath('title').text, :date => date_from_rss_item(link), :domain => URI.parse(url).host }
      end
    end
    
    def self.house_gop(url)
      doc = open_html(url)
      return unless doc
      uri = URI.parse(url)
      date = Date.parse(uri.query.split('=').last)
      links = doc.xpath("//ul[@id='membernews']").search('a')
      links.map do |link| 
        abs_link = absolute_link(url, link["href"])
        { :source => url, :url => abs_link, :title => link.text.strip, :date => date, :domain => URI.parse(link["href"]).host }
      end
    end
    
    def self.from_scrapers
      year = Date.today.year
      [freshman_senators, capuano, cold_fusion(year, 0), conaway, susandavis, faleomavaega, klobuchar, lujan, palazzo(page=1), billnelson(year=year), 
        document_query(page=1), document_query(page=2), donnelly(year=year), lautenberg, crapo, coburn, boxer(start=1), mccain(year=year), 
        vitter_cowan(year=year), inhofe(year=year), reid].flatten
    end
    
    def self.backfill_from_scrapers
      [cold_fusion(2012, 0), cold_fusion(2011, 0), cold_fusion(2010, 0), billnelson(year=2012), document_query(page=3), 
        document_query(page=4), coburn(year=2012), coburn(year=2011), coburn(year=2010), boxer(start=11), boxer(start=21), 
        boxer(start=31), boxer(start=41), mccain(year=2012), mccain(year=2011), vitter_cowan(year=2012), vitter_cowan(year=2011),
        ].flatten
    end
    
    ## special cases for members without RSS feeds
    
    def self.capuano
      results = []
      base_url = "http://www.house.gov/capuano/news/"
      list_url = base_url + 'date.shtml'
      doc = open_html(list_url)
      return if doc.nil?
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
    
    def self.cold_fusion(year, month)
      results = []
      year = Date.today.year if not year
      month = 0 if not month
      domains = ['crenshaw.house.gov/', 'www.ronjohnson.senate.gov/public/','www.lee.senate.gov/public/','www.hoeven.senate.gov/public/','www.moran.senate.gov/public/','www.risch.senate.gov/public/']
      domains.each do |domain|
        if domain == 'crenshaw.house.gov/' or domain == 'www.risch.senate.gov/public/'
          url = "http://"+domain + "index.cfm/pressreleases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
        elsif domain == 'www.hoeven.senate.gov/public/' or domain == 'www.moran.senate.gov/public/'
          url = "http://"+domain + "index.cfm/news-releases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
        else
          url = "http://"+domain + "index.cfm/press-releases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
        end
        doc = open_html(url)
        return if doc.nil?
        doc.xpath("//tr")[2..-1].each do |row|
          date_text, title = row.children.map{|c| c.text.strip}.reject{|c| c.empty?}
          next if date_text == 'Date' or date_text.size > 8
          date = Date.parse(date_text)
          results << { :source => url, :url => row.children[2].children.first['href'], :title => title, :date => date, :domain => domain }
        end
      end
      results.flatten
    end
    
    def self.conaway(page=1)
      results = []
      base_url = "http://conaway.house.gov/news/"
      page_url = base_url + "documentquery.aspx?DocumentTypeID=1279&Page=#{page}"
      doc = open_html(page_url)
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        results << { :source => page_url, :url => base_url + row.children.children[1]['href'], :title => row.children.children[1].text.strip, :date => Date.parse(row.children.children[4].text), :domain => "conaway.house.gov" }
      end
      results
    end
    
    def self.susandavis
      results = []
      base_url = "http://www.house.gov/susandavis/"
      doc = open_html(base_url+'news.shtml')
      return if doc.nil?
      doc.search("ul")[6].children.each do |row|
        next if row.text.strip == ''
        results << { :source => base_url+'news.shtml', :url => base_url + row.children[1]['href'], :title => row.children[1].text.split.join(' '), :date => Date.parse(row.children.first.text), :domain => "house.gov/susandavis" }
      end
      results
    end
    
    def self.faleomavaega
      results = []
      base_url = "http://www.house.gov/faleomavaega/news-press.shtml"
      doc = open_html(base_url)
      return if doc.nil?
      doc.xpath("//li[@type='disc']").each do |row|
        results << { :source => base_url, :url => "http://www.house.gov/" + row.children[0]['href'], :title => row.children[0].text.gsub(/[u201cu201d]/, '').split('Washington, D.C.').last, :date => Date.parse(row.children[1].text), :domain => "house.gov/faleomavaega" }
      end
      results
    end
    
    def self.freshman_senators
      results = []
      ['baldwin', 'flake', 'hirono','heinrich','murphy','scott','king','heitkamp','cruz','kaine'].each do |senator|
        base_url = "http://www.#{senator}.senate.gov/"
        doc = Statement::Link.open_html(base_url+'press.cfm?maxrows=200&startrow=1&&type=1')
        return if doc.nil?
        doc.xpath("//tr")[3..-1].each do |row|
          next if row.text.strip == ''
          results << { :source => base_url+'press.cfm?maxrows=200&startrow=1&&type=1', :url => base_url + row.children.children[1]['href'], :title => row.children.children[1].text.strip.split.join(' '), :date => Date.parse(row.children.children[0].text), :domain => "#{senator}.senate.gov" }
        end
      end
      results.flatten
    end
    
    def self.klobuchar
      results = []
      base_url = "http://www.klobuchar.senate.gov/"
      [2012,2013].each do |year|
        year_url = base_url + "newsreleases.cfm?year=#{year}"
        doc = open_html(year_url)
        return if doc.nil?
        doc.xpath("//dt").each do |row|
          results << { :source => year_url, :url => base_url + row.next.children[0]['href'], :title => row.next.text.strip.gsub(/[u201cu201d]/, '').split.join(' '), :date => Date.parse(row.text), :domain => "klobuchar.senate.gov" }
        end
      end
      results
    end
    
    def self.lujan
      results = []
      base_url = 'http://lujan.house.gov/'
      doc = open_html(base_url+'index.php?option=com_content&view=article&id=981&Itemid=78')
      return if doc.nil?
      doc.xpath('//ul')[1].children.each do |row|
        next if row.text.strip == ''
        results << { :source => base_url+'index.php?option=com_content&view=article&id=981&Itemid=78', :url => base_url + row.children[0]['href'], :title => row.children[0].text, :date => nil, :domain => "lujan.house.gov" }
      end
      results
    end
    
    def self.billnelson(year=2013)
      results = []
      base_url = "http://www.billnelson.senate.gov/news/"
      year_url = base_url + "media.cfm?year=#{year}"
      doc = open_html(year_url)
      return if doc.nil?
      doc.xpath('//li').each do |row|
        results << { :source => year_url, :url => base_url + row.children[0]['href'], :title => row.children[0].text.strip, :date => Date.parse(row.children.last.text), :domain => "billnelson.senate.gov" }
      end
      results
    end
    
    # fetches the latest 1000 releases, can be altered
    def self.lautenberg(rows=1000)
      results = []
      base_url = 'http://www.lautenberg.senate.gov/newsroom/'
      url = base_url + "releases.cfm?maxrows=#{rows}&startrow=1&&type=1"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[4..-2].each do |row|
        results << { :source => url, :url => base_url + row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.parse(row.children[0].text.strip), :domain => "lautenberg.senate.gov" }
      end
      results
    end
    
    def self.crapo
      results = []
      base_url = "http://www.crapo.senate.gov/media/newsreleases/"
      url = base_url + "release_all.cfm"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr").each do |row|
        results << { :source => url, :url => base_url + row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.parse(row.children[0].text.strip.gsub('-','/')), :domain => "crapo.senate.gov" }
      end
      results
    end
    
    def self.coburn(year=Date.today.year)
      results = []
      url = "http://www.coburn.senate.gov/public/index.cfm?p=PressReleases&ContentType_id=d741b7a7-7863-4223-9904-8cb9378aa03a&Group_id=7a55cb96-4639-4dac-8c0c-99a4a227bd3a&MonthDisplay=0&YearDisplay=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[2..-1].each do |row|
        next if row.text[0..3] == "Date"
        results << { :source => url, :url => row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.parse(row.children[0].text.strip), :domain => "coburn.senate.gov" }
      end
      results
    end
    
    def self.boxer(start=1)
      results = []
      url = "http://www.boxer.senate.gov/en/press/releases.cfm?start=#{start}"
      domain = 'www.boxer.senate.gov'
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='left']")[1..-1].each do |row|
        results << { :source => url, :url => domain + row.next.next.children[1].children[0]['href'], :title => row.next.next.children[1].children[0].text, :date => Date.parse(row.text.strip), :domain => domain}
      end
      results
    end
    
    def self.mccain(year=Date.today.year)
      results = []
      url = "http://www.mccain.senate.gov/public/index.cfm?FuseAction=PressOffice.PressReleases&ContentRecordType_id=75e7e4a0-6088-44b6-8061-089d80513dc4&Region_id=&Issue_id=&MonthDisplay=0&YearDisplay=#{year}"
      domain = 'www.mccain.senate.gov'
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//li")[7..-1].each do |row|
        results << { :source => url, :url => domain + row.children[3].children[1].children[4].children[0]['href'], :title => row.children[3].children[1].children[4].text, :date => Date.parse(row.children[3].children[1].children[0].text), :domain => domain}
      end
      results
    end
    
    def self.vitter_cowan(year=Date.today.year)
      results = []
      urls = ["http://www.vitter.senate.gov/newsroom/", "http://www.cowan.senate.gov/"]
      urls.each do |url|
        next if year < 2013 and url == "http://www.cowan.senate.gov/"
        if url == "http://www.vitter.senate.gov/newsroom/"
          domain = "www.vitter.senate.gov"
        elsif url == "http://www.cowan.senate.gov/"
          domain = "www.cowan.senate.gov"
        end
        doc = open_html(url+"press?year=#{year}")
        return if doc.nil?
        doc.xpath("//tr")[1..-1].each do |row|
          next if row.text.strip.size < 30
          results << { :source => url, :url => row.children[2].children[0]['href'].strip, :title => row.children[2].text, :date => Date.parse(row.children[0].text), :domain => domain}
        end
      end
      results.flatten
    end
    
    def self.donnelly(year=Date.today.year)
      results = []
      url = "http://www.donnelly.senate.gov/newsroom/"
      domain = "www.donnelly.senate.gov"
      doc = open_html(url+"press?year=#{year}")
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => "http://www.donnelly.senate.gov"+row.children[2].children[1]['href'].strip, :title => row.children[2].text.strip, :date => Date.parse(row.children[0].text), :domain => domain}
      end
      results
    end
    
    def self.inhofe(year=Date.today.year)
      results = []
      url = "http://www.inhofe.senate.gov/newsroom/press-releases?year=#{year}"
      domain = "www.inhofe.senate.gov"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => row.children[2].children[0]['href'].strip, :title => row.children[2].text, :date => Date.parse(row.children[0].text), :domain => domain}
      end
      results
    end
    
    def self.levin(page=1)
      results = []
      url = "http://www.levin.senate.gov/newsroom/index.cfm?PageNum_rs=#{page}&section=press"
      domain = "www.levin.senate.gov"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath('//tr').each do |row|
        results << { :source => url, :url => row.children[2].children[0]['href'].gsub(/\s+/, ""), :title => row.children[2].children[0].text, :date => Date.parse(row.children[0].text), :domain => domain}
      end
      results
    end
    
    def self.reid
      results = []
      url = "http://www.reid.senate.gov/newsroom/press_releases.cfm"
      domain = "www.reid.senate.gov"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//table[@id='CS_PgIndex_21891_21893']//tr")[1..-1].each do |row|
        results << { :source => url, :url => "http://www.reid.senate.gov"+row.children[0].children[0]['href'], :title => row.children[0].children[0].text, :date => Date.parse(row.children[0].children[2].text), :domain => domain}
      end
      results
    end
    
    def self.palazzo(page=1)
      results = []
      domain = "palazzo.house.gov"
      url = "http://palazzo.house.gov/news/documentquery.aspx?DocumentTypeID=2519&Page=#{page}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='middlecopy']//li").each do |row|
        results << { :source => url, :url => "http://palazzo.house.gov/news/" + row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.children[3].text.strip), :domain => domain }
      end
      results
    end
    
    def self.document_query(page=1)
      results = []
      domains = [{"roe.house.gov" => 1532}, {"thornberry.house.gov" => 1776}, {"wenstrup.house.gov" => 2491}]
      domains.each do |domain|
        doc = open_html("http://"+domain.keys.first+"/news/documentquery.aspx?DocumentTypeID=#{domain.values.first}&Page=#{page}")
        return if doc.nil?
        doc.xpath("//span[@class='middlecopy']").each do |row|
          results << { :source => "http://"+domain.keys.first+"/news/"+"documentquery.aspx?DocumentTypeID=#{domain.values.first}&Page=#{page}", :url => "http://"+domain.keys.first+"/news/" + row.children[6]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.children[4].text.strip), :domain => domain.keys.first }
        end
      end
      results.flatten
    end
    
  end
end
