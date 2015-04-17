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
      [:crenshaw, :capuano, :cold_fusion, :conaway, :chabot, :freshman_senators, :klobuchar, :billnelson, :crapo, :boxer,
      :vitter, :inhofe, :palazzo, :roe, :document_query, :swalwell, :fischer, :clark, :edwards, :culberson_chabot_grisham, :barton,
      :sherman_mccaul, :welch, :sessions, :gabbard, :ellison, :costa, :farr, :mcclintock, :mcnerney, :olson, :schumer, :lamborn, :walden,
      :bennie_thompson, :speier, :poe, :grassley]
    end

    def self.committee_methods
      [:senate_approps_majority, :senate_approps_minority, :senate_banking, :senate_hsag_majority, :senate_hsag_minority, :senate_indian, :senate_aging, :senate_smallbiz_minority, :senate_intel, :house_energy_minority, :house_homeland_security_minority, :house_judiciary_majority, :house_rules_majority, :house_ways_means_majority]
    end

    def self.member_scrapers
      year = Date.today.year
      results = [crenshaw, capuano, cold_fusion(year, nil), conaway, chabot, klobuchar(year), palazzo(page=1), roe(page=1), billnelson(year=year),
        document_query(page=1), document_query(page=2), swalwell(page=1), crapo, boxer(start=1), grassley(page=0),
        vitter(year=year), inhofe(year=year), fischer, clark(year=year), edwards, culberson_chabot_grisham(page=1), barton, sherman_mccaul, welch,
        sessions(year=year), gabbard, ellison(page=0), costa, farr, olson, mcnerney, schumer, lamborn(limit=10), walden, bennie_thompson, speier,
        poe(year=year, month=0)].flatten
      results = results.compact
      Utils.remove_generic_urls!(results)
    end

    def self.backfill_from_scrapers
      results = [cold_fusion(2012, 0), cold_fusion(2011, 0), cold_fusion(2010, 0), billnelson(year=2012), document_query(page=3),
        document_query(page=4), boxer(start=11), boxer(start=21), grassley(page=1), grassley(page=2), grassley(page=3),
        boxer(start=31), boxer(start=41), vitter(year=2012), vitter(year=2011), swalwell(page=2), swalwell(page=3), clark(year=2013), culberson_chabot_grisham(page=2),
        sherman_mccaul(page=1), sessions(year=2013), pryor(page=1), ellison(page=1), ellison(page=2), ellison(page=3), farr(year=2013), farr(year=2012), farr(year=2011),
        mcnerney(page=2), mcnerney(page=3), mcnerney(page=4), mcnerney(page=5), mcnerney(page=6), olson(year=2013), schumer(page=2), schumer(page=3), poe(year=2015, month=2),
        poe(year=2015, month=1)].flatten
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

    def self.crenshaw(year=Date.today.year, month=nil)
      results = []
      year = Date.today.year if not year
      domain = 'crenshaw.house.gov'
      if month
        url = "http://crenshaw.house.gov/index.cfm/pressreleases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
      else
        url = "http://crenshaw.house.gov/index.cfm/pressreleases"
      end
      doc = Statement::Scraper.open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[2..-1].each do |row|
        date_text, title = row.children.map{|c| c.text.strip}.reject{|c| c.empty?}
        next if date_text == 'Date' or date_text.size > 10
        date = Date.parse(date_text)
        results << { :source => url, :url => row.children[3].children.first['href'], :title => title, :date => date, :domain => domain }
      end
      results
    end

    def self.cold_fusion(year=Date.today.year, month=nil)
      results = []
      year = Date.today.year if not year
      domains = ['www.ronjohnson.senate.gov/public/','www.risch.senate.gov/public/']
      domains.each do |domain|
        if domain == 'www.risch.senate.gov/public/'
          if not month
            url = "http://www.risch.senate.gov/public/index.cfm/pressreleases"
          else
            url = "http://www.risch.senate.gov/public/index.cfm/pressreleases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
          end
        else
          if not month
            url = "http://www.ronjohnson.senate.gov/public/index.cfm/press-releases"
          else
            url = "http://www.ronjohnson.senate.gov/public/index.cfm/press-releases?YearDisplay=#{year}&MonthDisplay=#{month}&page=1"
          end
        end
        doc = Statement::Scraper.open_html(url)
        return if doc.nil?
        doc.xpath("//tr")[2..-1].each do |row|
          date_text, title = row.children.map{|c| c.text.strip}.reject{|c| c.empty?}
          next if date_text == 'Date' or date_text.size > 10
          date = Date.parse(date_text)
          results << { :source => url, :url => row.children[3].children.first['href'], :title => title, :date => date, :domain => domain }
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
      doc.xpath("//li")[40..48].each do |row|
        next if not row.text.include?('Posted')
        results << { :source => url, :url => base_url + row.children[1]['href'], :title => row.children[1].children.text.strip, :date => Date.parse(row.children[3].text.strip), :domain => "chabot.house.gov" }
      end
      results
    end

    def self.klobuchar(year)
      results = []
      base_url = "http://www.klobuchar.senate.gov/"
      [year.to_i-1,year.to_i].each do |year|
        year_url = base_url + "public/news-releases?MonthDisplay=0&YearDisplay=#{year}"
        doc = open_html(year_url)
        return if doc.nil?
        doc.xpath("//tr")[1..-1].each do |row|
          next if row.children[3].children[0].text.strip == 'Title'
          results << { :source => year_url, :url => row.children[3].children[0]['href'], :title => row.children[3].children[0].text.strip, :date => Date.strptime(row.children[1].text, "%m/%d/%y"), :domain => "klobuchar.senate.gov" }
        end
      end
      results
    end

    def self.poe(year, month=0)
      results = []
      base_url = "http://poe.house.gov"
      month_url = base_url + "/press-releases?MonthDisplay=#{month}&YearDisplay=#{year}"
      doc = open_html(month_url)
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.children[3].children[0].text.strip == 'Title'
        results << { :source => month_url, :url => base_url + row.children[3].children[0]['href'], :title => row.children[3].children[0].text.strip, :date => Date.strptime(row.children[1].text, "%m/%d/%y"), :domain => "poe.house.gov" }
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
        results << { :source => url, :url => base_url + row.children[3].children[0]['href'], :title => row.children[3].text.strip, :date => Date.parse(row.children[1].text.strip.gsub('-','/')), :domain => "crapo.senate.gov" }
      end
      results
    end

    def self.fischer(year=Date.today.year)
      results = []
      url = "http://www.fischer.senate.gov/public/index.cfm/press-releases?MonthDisplay=0&YearDisplay=#{year}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr")[2..-1].each do |row|
        next if row.text.strip[0..3] == "Date"
        results << { :source => url, :url => row.children[3].children[0]['href'], :title => row.children[3].text.strip, :date => Date.strptime(row.children[1].text.strip, "%m/%d/%y"), :domain => "fischer.senate.gov" }
      end
      results
    end

    def self.grassley(page=0)
      results = []
      url = "http://www.grassley.senate.gov/news/news-releases?title=&tid=All&date[value]&page=#{page}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='views-field views-field-field-release-date']").each do |row|
        results << { :source => url, :url => "http://www.grassley.senate.gov" + row.next.next.children[1].children[0]['href'], :title => row.next.next.text.strip, :date => Date.parse(row.text.strip), :domain => "grassley.senate.gov" }
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

    def self.vitter(year=Date.today.year)
      results = []
      url = "http://www.vitter.senate.gov/newsroom/"
      domain = "www.vitter.senate.gov"
      doc = open_html(url+"press?year=#{year}")
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => row.children[3].children[0]['href'].strip, :title => row.children[3].text, :date => Date.strptime(row.children[1].text, "%m/%d/%y"), :domain => domain}
      end
      results
    end

    # deprecated
    def self.donnelly(year=Date.today.year)
      results = []
      url = "http://www.donnelly.senate.gov/newsroom/"
      domain = "www.donnelly.senate.gov"
      doc = open_html(url+"press?year=#{year}")
      return if doc.nil?
      doc.xpath("//tr")[1..-1].each do |row|
        next if row.text.strip.size < 30
        results << { :source => url, :url => "http://www.donnelly.senate.gov"+row.children[3].children[1]['href'].strip, :title => row.children[3].text.strip, :date => Date.strptime(row.children[1].text, "%m/%d/%y"), :domain => domain}
      end
      results
    end

    def self.inhofe(year=Date.today.year)
      results = []
      url = "http://www.inhofe.senate.gov/newsroom/press-releases?year=#{year}"
      domain = "www.inhofe.senate.gov"
      doc = open_html(url)
      return if doc.nil?
      if doc.xpath("//tr")[1..-1]
        doc.xpath("//tr")[1..-1].each do |row|
          next if row.text.strip.size < 30
          results << { :source => url, :url => row.children[3].children[0]['href'].strip, :title => row.children[3].text, :date => Date.strptime(row.children[1].text, "%m/%d/%y"), :domain => domain}
        end
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
      results
    end

    def self.clark(year=Date.today.year)
      results = []
      domain = 'katherineclark.house.gov'
      url = "http://katherineclark.house.gov/index.cfm/press-releases?MonthDisplay=0&YearDisplay=#{year}"
      doc = open_html(url)
      return if doc.nil?
      (doc/:tr)[1..-1].each do |row|
        next if row.children[1].text.strip == 'Date'
        results << { :source => url, :date => Date.parse(row.children[1].text.strip), :title => row.children[3].children.text, :url => row.children[3].children[0]['href'], :domain => domain}
      end
      results
    end

    def self.sessions(year=Date.today.year)
      results = []
      domain = 'sessions.senate.gov'
      url = "http://www.sessions.senate.gov/public/index.cfm/news-releases?YearDisplay=#{year}"
      doc = open_html(url)
      return if doc.nil?
      (doc/:tr)[1..-1].each do |row|
        next if row.children[1].text.strip == 'Date'
        results << { :source => url, :date => Date.parse(row.children[1].text), :title => row.children[3].children.text, :url => row.children[3].children[0]['href'], :domain => domain}
      end
      results
    end

    def self.edwards
      results = []
      domain = 'donnaedwards.house.gov'
      url = "http://donnaedwards.house.gov/index.php?option=com_content&view=category&id=10&Itemid=18"
      doc = open_html(url)
      return if doc.nil?
      table = (doc/:table)[4]
      (table/:tr).each do |row|
        results << { :source => url, :url => "http://donnaedwards.house.gov/"+row.children.children[1]['href'], :title => row.children.children[1].text.strip, :date => Date.parse(row.children.children[3].text.strip), :domain => domain}
      end
      results
    end

    def self.culberson_chabot_grisham(page=1)
      results = []
      domains = [{'culberson.house.gov' => 2573}, {'chabot.house.gov' => 2508}, {'lujangrisham.house.gov' => 2447}]
      domains.each do |domain|
        doc = open_html("http://"+domain.keys.first+"/news/documentquery.aspx?DocumentTypeID=#{domain.values.first}&Page=#{page}")
        return if doc.nil?
        doc.css('ul.UnorderedNewsList li').each do |row|
          link = "http://"+domain.keys.first+"/news/" + row.children[1]['href']
          title = row.children[1].text.strip
          date = Date.parse(row.children[3].text.strip)
          results << { :source => "http://"+domain.keys.first+"/news/"+"documentquery.aspx?DocumentTypeID=#{domain.values.first}&Page=#{page}", :title => title, :url => link, :date => date, :domain => domain.keys.first }
        end
      end
      results.flatten
    end

    def self.barton
      results = []
      domain = 'joebarton.house.gov'
      url = "http://joebarton.house.gov/press-releasescolumns/"
      doc = open_html(url)
      return if doc.nil?
      (doc/:h3)[0..-3].each do |row|
        results << { :source => url, :url => "http://joebarton.house.gov/"+row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.next.next.text), :domain => domain}
      end
      results
    end

    def self.sherman_mccaul(page=0)
      results = []
      domains = ['sherman.house.gov', 'mccaul.house.gov']
      domains.each do |domain|
        url = "http://#{domain}/media-center/press-releases?page=#{page}"
        doc = open_html(url)
        return if doc.nil?
        dates = doc.xpath('//span[@class="field-content"]').map {|s| s.text if s.text.strip.include?("201")}.compact!
        (doc/:h3).first(10).each_with_index do |row, i|
          date = Date.parse(dates[i])
          results << {:source => url, :url => "http://"+domain+row.children.first['href'], :title => row.children.first.text.strip, :date => date, :domain => domain}
        end
      end
      results.flatten
    end

    def self.welch
      results = []
      domain = 'welch.house.gov'
      url = "http://www.welch.house.gov/press-releases/"
      doc = open_html(url)
      return if doc.nil?
      (doc/:h3).each do |row|
        results << { :source => url, :url => "http://www.welch.house.gov/"+row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.next.next.text), :domain => domain}
      end
      results
    end

    def self.gabbard
      results = []
      domain = 'gabbard.house.gov'
      url = "http://gabbard.house.gov/index.php/news/press-releases"
      doc = open_html(url)
      return if doc.nil?
      doc.css('ul.fc_leading li').each do |row|
        results << {:source => url, :url => "http://gabbard.house.gov"+row.children[0].children[1]['href'], :title => row.children[0].children[1].text.strip, :date => Date.parse(row.children[2].text), :domain => domain}
      end
      results
    end

    def self.ellison(page=0)
      results = []
      domain = 'ellison.house.gov'
      url = "http://ellison.house.gov/media-center/press-releases?page=#{page}"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='views-field views-field-created datebar']").each do |row|
        next if row.nil?
        results << { :source => url, :url => "http://ellison.house.gov" + row.next.next.children[1].children[0]['href'], :title => row.next.next.children[1].children[0].text.strip, :date => Date.parse(row.text.strip), :domain => domain}
      end
      results
    end

    def self.costa
      results = []
      domain = 'costa.house.gov'
      url = "http://costa.house.gov/index.php/newsroom30/press-releases12"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='nspArt']").each do |row|
        results << { :source => url, :url => "http://costa.house.gov" + row.children[0].children[1].children[0]['href'], :title => row.children[0].children[1].children[0].text.strip, :date => Date.parse(row.children[0].children[0].text), :domain => domain}
      end
      results
    end

    def self.farr(year=2014)
      results = []
      domain = 'www.farr.house.gov'
      if year == 2014
        url = "http://www.farr.house.gov/index.php/newsroom/press-releases"
      else
        url = "http://www.farr.house.gov/index.php/newsroom/press-releases-archive/#{year.to_s}-press-releases"
      end
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//tr[@class='cat-list-row0']").each do |row|
        results << { :source => url, :url => "http://farr.house.gov" + row.children[1].children[1]['href'], :title => row.children[1].children[1].text.strip, :date => Date.parse(row.children[3].text.strip), :domain => domain}
      end
      results
    end

    def self.mcclintock
      results = []
      domain = 'mcclintock.house.gov'
      url = "http://mcclintock.house.gov/press-all.shtml"
      doc = open_html(url)
      return if doc.nil?
      doc.css("ul li").first(152).each do |row|
        results << { :source => url, :url => row.children[0].children[1]['href'], :title => row.children[0].children[1].text.strip, :date => Date.parse(row.children[0].children[0].text), :domain => domain}
      end
      results
    end

    def self.olson(year=2014)
      results = []
      domain = 'olson.house.gov'
      url = "http://olson.house.gov/#{year}-press-releases/"
      doc = open_html(url)
      return if doc.nil?
      (doc/:h3).each do |row|
        results << {:source => url, :url => 'http://olson.house.gov' + row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.next.next.text), :domain => domain }
      end
      results
    end

    def self.mcnerney(page=1)
      results = []
      domain = 'mcnerney.house.gov'
      url = "http://mcnerney.house.gov/media-center/press-releases"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath("//div[@class='views-field views-field-title']").each do |row|
        results << {:source => url, :url => 'http://mcnerney.house.gov' + row.children[1].children[0]['href'], :title => row.children[1].children[0].text.strip, :date => Date.parse(row.next.next.text.strip), :domain => domain }
      end
      results
    end

    def self.document_query(page=1)
      results = []
      domains = [{"thornberry.house.gov" => 1776}, {"wenstrup.house.gov" => 2491}, {"clawson.house.gov" => 2641}]
      domains.each do |domain|
        doc = open_html("http://"+domain.keys.first+"/news/documentquery.aspx?DocumentTypeID=#{domain.values.first}&Page=#{page}")
        return if doc.nil?
        doc.xpath("//div[@class='middlecopy']//li").each do |row|
          results << { :source => "http://"+domain.keys.first+"/news/"+"documentquery.aspx?DocumentTypeID=#{domain.values.first}&Page=#{page}", :url => "http://"+domain.keys.first+"/news/" + row.children[1]['href'], :title => row.children[1].text.strip, :date => Date.parse(row.children[3].text.strip), :domain => domain.keys.first }
        end
      end
      results.flatten
    end

    def self.schumer(page=1)
      results = []
      domain = 'www.schumer.senate.gov'
      url = "http://www.schumer.senate.gov/newsroom/press-releases/table?PageNum_rs=#{page}"
      doc = open_html(url)
      return if doc.nil?
      rows = (doc/:table/:tr).select{|r| !r.children[3].nil?}
      rows.each do |row|
        results << {:source => url, :url => row.children[3].children[1]['href'].strip, :title => row.children[3].text.strip, :date => Date.parse(row.children[1].text.strip), :domain => domain }
      end
      results
    end

    def self.lamborn(limit=nil)
      results = []
      domain = 'lamborn.house.gov'
      url = "http://lamborn.house.gov/2015-press-releases/"
      doc = open_html(url)
      return if doc.nil?
      links = (doc/:h3).map{|h| { "http://lamborn.house.gov"+h.children[1]['href'] => h.text.strip} }
      links = links.first(limit) if limit
      links.each do |link|
        page = open_html(link.keys.first)
        print_path = page.search("a").detect{|a| a['onclick'] && a['onclick'].include?('popup')}['onclick'].split("'")[1]
        print_page = open_html("http://lamborn.house.gov"+print_path)
        results << {:source => url, :url => link.keys.first, :title => link.values.first, :date => Date.parse(print_page.xpath('//*[@class="PopupNewsDetailsDate"]').text), :domain => domain }
      end
      results
    end

    def self.walden
      results = []
      domain = 'walden.house.gov'
      url = "http://walden.house.gov/s2015/"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath('//*[@id="centerbox"]/div[1]/ul/li').each do |row|
        results << {:source => url, :url => 'http://walden.house.gov' + row.children[3].children[1]['href'], :title => row.children[3].text.strip, :date => Date.parse(row.children[5].text), :domain => domain }
      end
      results
    end

    def self.bennie_thompson
      results = []
      domain = "benniethompson.house.gov"
      url = "http://benniethompson.house.gov/index.php?option=com_content&view=category&id=41&Itemid=148"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath('//*[@id="adminForm"]/table/tbody/tr').each do |row|
        results << {:source => url, :url => 'http://benniethompson.house.gov' + row.children[1].children[1]['href'], :title => row.children[1].children[1].text.strip, :date => Date.parse(row.children[3].text.strip), :domain => domain }
      end
      results
    end

    def self.speier
      results = []
      domain = "speier.house.gov"
      url = "http://speier.house.gov/index.php?option=com_content&view=category&id=20&Itemid=14"
      doc = open_html(url)
      return if doc.nil?
      doc.xpath('//*[@id="adminForm"]/table/tbody/tr').each do |row|
        results << {:source => url, :url => 'http://speier.house.gov' + row.children[1].children[1]['href'], :title => row.children[1].children[1].text.strip, :date => Date.parse(row.children[3].text.strip), :domain => domain }
      end
      results
    end

    def self.backfill_bilirakis
      results = []
      domain = 'bilirakis.house.gov'
      url = 'http://bilirakis.house.gov/press-releases/'
      doc = open_html(url)
      return if doc.nil?
      doc.css("ul li[@class='article articleright']").each do |row|
        results << {:source => url, :url => 'http://bilirakis.house.gov' + row.children[3].children[1]['href'], :title => row.children[3].text.strip, :date => Date.parse(row.children[5].text), :domain => domain }
      end
    end

    def self.backfill_boustany
      results = []
      domain = 'boustany.house.gov'
      url = 'http://boustany.house.gov/113th-congress/showallitems/'
      doc = open_html(url)
      return if doc.nil?

    end

  end
end
