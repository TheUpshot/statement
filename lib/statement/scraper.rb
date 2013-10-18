# encoding: utf-8
require 'uri'
require 'open-uri'
require 'american_date'
require 'nokogiri'

module Statement
  class Scraper
    
    def self.open_html(url)
      begin
        Nokogiri::HTML(open(url).read)
      rescue
        nil
      end
    end
    
    def self.house_gop(url)
      doc = open_html(url)
      return unless doc
      uri = URI.parse(url)
      date = Date.parse(uri.query.split('=').last)
      links = doc.xpath("//ul[@id='membernews']").search('a')
      results = links.map do |link| 
        abs_link = Utils.absolute_link(url, link["href"])
        { :source => url, :url => abs_link, :title => link.text.strip, :date => date, :domain => URI.parse(link["href"]).host }
      end
      Utils.remove_generic_urls!(results)
    end
    
    def self.member_methods
      [:capuano, :cold_fusion, :conaway, :chabot, :susandavis, :freshman_senators, :klobuchar, :lujan, :billnelson, :lautenberg, :crapo, :coburn, :boxer, :mccain, :vitter, :donnelly, :inhofe, :levin, :reid, :palazzo, :document_query, :farenthold, :swalwell, :fischer]
    end
    
    def self.committee_methods
      [:senate_approps_majority, :senate_approps_minority, :senate_banking, :senate_hsag_majority, :senate_hsag_minority, :senate_indian, :senate_aging, :senate_smallbiz_minority, :senate_intel, :house_energy_minority, :house_homeland_security_minority, :house_judiciary_majority, :house_rules_majority, :house_ways_means_majority]
    end
    
    def self.member_scrapers
      year = Date.today.year
      results = [freshman_senators, capuano, cold_fusion(year, 0), conaway, chabot, susandavis, klobuchar, lujan, palazzo(page=1), billnelson(year=year), 
        document_query(page=1), document_query(page=2), farenthold(year), swalwell(page=1), donnelly(year=year), crapo, coburn, boxer(start=1), mccain(year=year), 
        vitter(year=year), inhofe(year=year), reid, fischer].flatten
      results = results.compact
      Utils.remove_generic_urls!(results)
    end
    
    def self.backfill_from_scrapers
      results = [cold_fusion(2012, 0), cold_fusion(2011, 0), cold_fusion(2010, 0), billnelson(year=2012), document_query(page=3), 
        document_query(page=4), coburn(year=2012), coburn(year=2011), coburn(year=2010), boxer(start=11), boxer(start=21), 
        boxer(start=31), boxer(start=41), mccain(year=2012), mccain(year=2011), vitter(year=2012), vitter(year=2011), swalwell(page=2), swalwell(page=3)
        ].flatten
      Utils.remove_generic_urls!(results)
    end
    
    def self.committee_scrapers
      year = Date.today.year
      results = [senate_approps_majority, senate_approps_minority, senate_banking(year), senate_hsag_majority(year), senate_hsag_minority(year),
         senate_indian, senate_aging, senate_smallbiz_minority, senate_intel(113, 2013, 2014), house_energy_minority, house_homeland_security_minority,
         house_judiciary_majority, house_rules_majority, house_ways_means_majority].flatten
      Utils.remove_generic_urls!(results)
    end
    
    ## special cases for committees without RSS feeds
    
    def self.senate_approps_majority
      results = []
      url = "http://www.appropriations.senate.gov/news.cfm"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='newsDateUnderlined']").each do |date|
        date.next.next.children.reject{|c| c.text.strip.empty?}.each do |row|
          results << { :source => url, :url => url + row.children[0]['href'], :title => row.text, :date => Date.parse(date.text), :domain => "http://www.appropriations.senate.gov/", :party => 'majority' }
        end
      end
      results
    end
    
    def self.senate_approps_minority
      results = []
      url = "http://www.appropriations.senate.gov/republican.cfm"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='newsDateUnderlined']").each do |date|
        date.next.next.children.reject{|c| c.text.strip.empty?}.each do |row|
          results << { :source => url, :url => url + row.children[0]['href'], :title => row.text, :date => Date.parse(date.text), :domain => "http://www.appropriations.senate.gov/", :party => 'minority' }
        end
      end
      results
    end
    
    def self.senate_banking(year=Date.today.year)
      results = []
      url = "http://www.banking.senate.gov/public/index.cfm?FuseAction=Newsroom.PressReleases&ContentRecordType_id=b94acc28-404a-4fc6-b143-a9e15bf92da4&Region_id=&Issue_id=&MonthDisplay=0&YearDisplay=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr").each do |row|
        results << { :source => url, :url => "http://www.banking.senate.gov/public/" + row.children[2].children[1]['href'], :title => row.children[2].text.strip, :date => Date.parse(row.children[0].text.strip+", #{year}"), :domain => "http://www.banking.senate.gov/", :party => 'majority' }
      end
      results
    end
    
    def self.senate_hsag_majority(year=Date.today.year)
      results = []
      url = "http://www.hsgac.senate.gov/media/majority-media?year=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr").each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => row.children[2].children[0]['href'].strip, :title => row.children[2].children[0].text, :date => Date.parse(row.children[0].text), :domain => "http://www.hsgac.senate.gov/", :party => 'majority' }
      end
      results
    end
    
    def self.senate_hsag_minority(year=Date.today.year)
      results = []
      url = "http://www.hsgac.senate.gov/media/minority-media?year=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr").each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => row.children[2].children[0]['href'].strip, :title => row.children[2].children[0].text, :date => Date.parse(row.children[0].text), :domain => "http://www.hsgac.senate.gov/", :party => 'minority' }
      end
      results
    end
    
    def self.senate_indian
      results = []
      url = "http://www.indian.senate.gov/news/index.cfm"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//h3").each do |row|
        results << { :source => url, :url => "http://www.indian.senate.gov"+row.children[0]['href'], :title => row.children[0].text, :date => Date.parse(row.previous.previous.text), :domain => "http://www.indian.senate.gov/", :party => 'majority' }
      end
      results
    end
    
    def self.senate_aging
      results = []
      url = "http://www.aging.senate.gov/pressroom.cfm?maxrows=100&startrow=1&&type=1"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[6..104].each do |row|
        results << { :source => url, :url => "http://www.aging.senate.gov/"+row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.parse(row.children[0].text), :domain => "http://www.aging.senate.gov/" }
      end
      results
    end
    
    def self.senate_smallbiz_minority
      results = []
      url = "http://www.sbc.senate.gov/public/index.cfm?p=RepublicanPressRoom"
      doc = open_html(url)
      return if doc.nil?      
      doc.xpath("//ul[@class='recordList']").each do |row|
        results << { :source => url, :url => row.children[0].children[2].children[0]['href'], :title => row.children[0].children[2].children[0].text, :date => Date.parse(row.children[0].children[0].text), :domain => "http://www.sbc.senate.gov/", :party => 'minority' }
      end
      results
    end
    
    def self.senate_intel(congress=113, start_year=2013, end_year=2014)
      results = []
      url = "http://www.intelligence.senate.gov/press/releases.cfm?congress=#{congress}&y1=#{start_year}&y2=#{end_year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr[@valign='top']")[7..-1].each do |row|
        results << { :source => url, :url => "http://www.intelligence.senate.gov/press/"+row.children[2].children[0]['href'], :title => row.children[2].children[0].text.strip, :date => Date.parse(row.children[0].text), :domain => "http://www.intelligence.senate.gov/" }
      end
      results
    end
    
    def self.house_energy_minority
      results = []
      url = "http://democrats.energycommerce.house.gov/index.php?q=news-releases"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='views-field-title']").each do |row|
        results << { :source => url, :url => "http://democrats.energycommerce.house.gov"+row.children[1].children[0]['href'], :title => row.children[1].children[0].text, :date => Date.parse(row.next.next.text.strip), :domain => "http://energycommerce.house.gov/", :party => 'minority' }
      end
      results
    end
    
    def self.house_homeland_security_minority
      results = []
      url = "http://chsdemocrats.house.gov/press/index.asp?subsection=1"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//li[@class='article']").each do |row|
        results << { :source => url, :url => "http://chsdemocrats.house.gov"+row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.children[3].text), :domain => "http://chsdemocrats.house.gov/", :party => 'minority' }
      end
      results
    end
    
    def self.house_judiciary_majority
      results = []
      url = "http://judiciary.house.gov/news/press2013.html"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//p")[3..60].each do |row|
        next if row.text.size < 30
        results << { :source => url, :url => row.children[5]['href'], :title => row.children[0].text, :date => Date.parse(row.children[1].text.strip), :domain => "http://judiciary.house.gov/", :party => 'majority' }
      end
      results
    end
    
    def self.house_rules_majority
      results = []
      url = "http://www.rules.house.gov/News/Default.aspx"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[1..-2].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => "http://www.rules.house.gov/News/"+row.children[0].children[1].children[0]['href'], :title => row.children[0].children[1].children[0].text, :date => Date.parse(row.children[2].children[1].text.strip), :domain => "http://www.rules.house.gov/", :party => 'majority' }
      end
      results
    end
    
    def self.house_ways_means_majority
      results = []
      url = "http://waysandmeans.house.gov/news/documentquery.aspx?DocumentTypeID=1496"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//ul[@class='UnorderedNewsList']").children.each do |row|
        next if row.text.strip.size < 10
        results << { :source => url, :url => "http://waysandmeans.house.gov"+row.children[1].children[1]['href'], :title => row.children[1].children[1].text, :date => Date.parse(row.children[3].children[0].text.strip), :domain => "http://waysandmeans.house.gov/", :party => 'majority' }
      end
      results
    end
    
    ## special cases for members without RSS feeds
    
    def self.swalwell(page=1)
      results = []
      url = "http://swalwell.house.gov/category/press-releases/page/#{page}/"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//h3")[0..4].each do |row|
        results << { :source => url, :url => row.children[0]['href'], :title => row.children[0].text, :date => nil, :domain => 'swalwell.house.gov'}
      end
      results
    end

    def self.capuano
      results = []
      base_url = "http://www.house.gov/capuano/news/"
      list_url = base_url + 'date.shtml'
      doc = open_html(list_url)
      return if doc.nil?
      doc.xpath("//a").select{|l| !l['href'].nil? and l['href'].include?('/pr')}[1..-5].each do |link|
        begin
          year = link['href'].split('/').first
          date = Date.parse(link.text.split(' ').first+'/'+year) 
        rescue
          date = nil
        end
        results << { :source => list_url, :url => base_url + link['href'], :title => link.text.split(' ',2).last, :date => date, :domain => "www.house.gov/capuano/" }
      end
      return results[0..-5]
    end
    
    def self.cold_fusion(year=Date.today.year, month=0)
      results = []
      year = Date.today.year if not year
      month = 0 if not month
      domains = ['crenshaw.house.gov', 'www.ronjohnson.senate.gov/public/','www.hoeven.senate.gov/public/','www.moran.senate.gov/public/','www.risch.senate.gov/public/']
      domains.each do |domain|
        if domain == 'crenshaw.house.gov' or domain == 'www.risch.senate.gov/public/'
          url = "http://"+domain + "/index.cfm/pressreleases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
        elsif domain == 'www.hoeven.senate.gov/public/' or domain == 'www.moran.senate.gov/public/'
          url = "http://"+domain + "index.cfm/news-releases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
        else
          url = "http://"+domain + "index.cfm/press-releases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
        end
        doc = open_html(url)
        return if doc.nil?
        doc.xpath("//tr")[2..-1].each do |row|
          date_text, title = row.children.map{|c| c.text.strip}.reject{|c| c.empty?}
          next if date_text == 'Date' or date_text.size > 10
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
      doc.xpath("//li")[41..50].each do |row|
        results << { :source => page_url, :url => base_url + row.children[1]['href'], :title => row.children[1].children.text.strip, :date => Date.parse(row.children[3].text.strip), :domain => "conaway.house.gov" }
      end
      results
    end
    
    def self.chabot(year=Date.today.year)
      results = []
      base_url = "http://chabot.house.gov/news/"
      url = base_url + "documentquery.aspx?DocumentTypeID=2508&Year=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//li")[38..43].each do |row|
        results << { :source => url, :url => base_url + row.children[1]['href'], :title => row.children[1].children.text.strip, :date => Date.parse(row.children[3].text.strip), :domain => "chabot.house.gov" }
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
    
    def self.freshman_senators
      results = []
      ['markey', 'murphy','cruz'].each do |senator|
        base_url = "http://www.#{senator}.senate.gov/"
        doc = open_html(base_url+'press.cfm?maxrows=200&startrow=1&&type=1')
        return if doc.nil?
        doc.xpath("//tr")[3..-1].each do |row|
          next if row.text.strip == ''
          next if row.children.children[1]['href'].nil?
          results << { :source => base_url+'press.cfm?maxrows=200&startrow=1&&type=1', :url => base_url + row.children.children[1]['href'], :title => row.children.children[1].text.strip.split.join(' '), :date => Date.strptime(row.children.children[0].text, "%m/%d/%y"), :domain => "#{senator}.senate.gov" }
        end
      end
      results.flatten
    end
    
    def self.klobuchar
      results = []
      base_url = "http://www.klobuchar.senate.gov/"
      [2012,2013].each do |year|
        year_url = base_url + "public/news-releases?MonthDisplay=0&YearDisplay=#{year}"
        doc = open_html(year_url)
        return if doc.nil?
        doc.xpath("//tr")[1..-1].each do |row|
          next if row.children[2].children[0].text.strip == 'Title'
          results << { :source => year_url, :url => row.children[2].children[0]['href'], :title => row.children[2].children[0].text.strip, :date => Date.strptime(row.children[0].text, "%m/%d/%y"), :domain => "klobuchar.senate.gov" }
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
        results << { :source => url, :url => base_url + row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.strptime(row.children[0].text.strip, "%m/%d/%y"), :domain => "lautenberg.senate.gov" }
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

    def self.fischer(year=Date.today.year)
      results = []
      url = "http://www.fischer.senate.gov/public/index.cfm/press-releases?MonthDisplay=0&YearDisplay=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[2..-1].each do |row|
        next if row.text[0..3] == "Date"
        results << { :source => url, :url => row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.strptime(row.children[0].text.strip, "%m/%d/%y"), :domain => "fischer.senate.gov" }
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
        results << { :source => url, :url => row.children[2].children[0]['href'], :title => row.children[2].text.strip, :date => Date.strptime(row.children[0].text.strip, "%m/%d/%y"), :domain => "coburn.senate.gov" }
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
        results << { :source => url, :url => "http://"+domain+'/public/'+row.children[3].children[1].children[4].children[0]['href'], :title => row.children[3].children[1].children[4].text, :date => Date.strptime(row.children[3].children[1].children[0].text, "%m/%d/%y"), :domain => domain}
      end
      results
    end
    
    def self.vitter(year=Date.today.year)
      results = []
      url = "http://www.vitter.senate.gov/newsroom/"
      domain = "www.vitter.senate.gov"
      doc = open_html(url+"press?year=#{year}")
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => row.children[2].children[0]['href'].strip, :title => row.children[2].text, :date => Date.strptime(row.children[0].text, "%m/%d/%y"), :domain => domain}
      end
      results
    end
    
    def self.donnelly(year=Date.today.year)
      results = []
      url = "http://www.donnelly.senate.gov/newsroom/"
      domain = "www.donnelly.senate.gov"
      doc = open_html(url+"press?year=#{year}")
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => "http://www.donnelly.senate.gov"+row.children[2].children[1]['href'].strip, :title => row.children[2].text.strip, :date => Date.strptime(row.children[0].text, "%m/%d/%y"), :domain => domain}
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
        results << { :source => url, :url => row.children[2].children[0]['href'].strip, :title => row.children[2].text, :date => Date.strptime(row.children[0].text, "%m/%d/%y"), :domain => domain}
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

    def self.roe(page=1)
      results = []
      domain = 'roe.house.gov'
      url = "http://roe.house.gov/news/documentquery.aspx?DocumentTypeID=1532&Page=#{page}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='middlecopy']//li").each do |row|
        results << { :source => url, :url => "http://roe.house.gov/news/" + row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.children[3].text.strip), :domain => domain }
      end     


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
    
    def self.farenthold(year=2013)
      results = []
      url = "http://farenthold.house.gov/index.php?flt_m=&flt_y=#{year}&option=com_content&view=article&id=1181&Itemid=100059&layout=default"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@id='idGtReportDisplay']//li").each do |row|
        results << { :source => url, :url => 'http://farenthold.house.gov'+row.children[0]['href'], :title => row.children[0].text.strip, :date => nil, :domain => "farenthold.house.gov"}
      end
      results
    end
    
  end
end