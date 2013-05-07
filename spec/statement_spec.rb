require "minitest/autorun"
require_relative "../lib/statement"
require 'webmock/minitest'

describe Statement do
  it "parses an rss feed" do
    @feed_url = "http://ruiz.house.gov/rss.xml"
    stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "ruiz_rss.xml")), :status => 200)
    @results = Statement::Link.from_rss(@feed_url)
    @results.first[:domain].must_equal "ruiz.house.gov"
  end
  
  it "parses House GOP press release page" do
    @feed_url = "http://www.gop.gov/republicans/news?offset=03/29/13"
    stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "house_gop_releases.html")), :status => 200)
    @results = Statement::Link.house_gop(@feed_url)
    @results.first[:source].must_equal @feed_url
  end
  
  it "does not attempt to parse dates when none are present" do
    @feed_url = "http://culberson.house.gov/feed/rss/"
    stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "culberson_rss.xml")), :status => 200)

    @results = Statement::Link.from_rss(@feed_url)
    @results.first[:date].must_equal nil
  end
  
  it "parses invalid RSS" do
    @feed_url = "http://www.burr.senate.gov/public/index.cfm?FuseAction=RSS.Feed"
    stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "richard_burr.xml")), :status => 200)
    
    @results = Statement::Link.from_rss(@feed_url)
    @results.first[:url].must_equal "http://www.burr.senate.gov/public/index.cfm?FuseAction=PressOffice.PressReleases&Type=Press Release&ContentRecord_id=65dbea38-d64c-6208-ef8f-2b000e899b3a"
    @results.first[:date].to_s.must_equal "2013-05-02"
  end

  it "handles relative URLs" do
    @feed_url = "http://www.gop.gov/republicans/news?offset=03/29/13"
    stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "house_gop_releases.html")), :status => 200)
    @results = Statement::Link.house_gop(@feed_url)
    @results.last[:url].must_equal "http://www.gop.gov/republicans/other/relative_url_test.html"
  end
  
  it "scrapes a senate cold fusion page" do
    @url = "http://www.billnelson.senate.gov/news/media.cfm?year=2013"
    stub_request(:any, @url).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'bill_nelson_press.html')), :status => 200)
    @results = Statement::Link.billnelson(year=2013)
    @results.last[:url].must_equal "http://www.billnelson.senate.gov/news/details.cfm?id=338190&"
  end
  
  it "scrapes vitter and cowan pages for 2013" do
    @vitter = "http://www.vitter.senate.gov/newsroom/press?year=2013"
    @cowan = "http://www.cowan.senate.gov/press?year=2013"
    stub_request(:any, @vitter).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'vitter_press.html')), :status => 200)
    stub_request(:any, @cowan).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'cowan_press.html')), :status => 200)
    @results = Statement::Link.vitter_cowan(year=2013)
    @results.map{|r| r[:domain]}.uniq.must_equal ["www.vitter.senate.gov", "www.cowan.senate.gov"]
  end
  
  it "only scrapes vitter page for 2012" do
    @vitter = "http://www.vitter.senate.gov/newsroom/press?year=2012"
    @cowan = "http://www.cowan.senate.gov/press?year=2012"
    stub_request(:any, @vitter).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'vitter_press.html')), :status => 200)
    stub_request(:any, @cowan).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'cowan_press.html')), :status => 200)
    @results = Statement::Link.vitter_cowan(year=2012)
    @results.map{|r| r[:domain]}.uniq.must_equal ["www.vitter.senate.gov"]    
  end
  
end