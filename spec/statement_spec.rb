require "minitest/autorun"
require_relative "../lib/statement"
require 'webmock/minitest'
include Statement

describe Statement do
  it "parses an rss feed" do
    @feed_url = "http://ruiz.house.gov/rss.xml"
    WebMock.stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "ruiz_rss.xml")), :status => 200)
    @results = Feed.from_rss(@feed_url)
    @results.first[:domain].must_equal "ruiz.house.gov"
  end
  
  it "parses House GOP press release page" do
    @feed_url = "http://www.gop.gov/republicans/news?offset=03/29/13"
    WebMock.stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "house_gop_releases.html")), :status => 200)
    @results = Scraper.house_gop(@feed_url)
    @results.first[:source].must_equal @feed_url
  end
  
  it "does not attempt to parse dates when none are present" do
    @feed_url = "http://culberson.house.gov/feed/rss/"
    WebMock.stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "culberson_rss.xml")), :status => 200)
    @results = Feed.from_rss(@feed_url)
    @results.first[:date].must_equal nil
  end
  
  it "parses invalid RSS" do
    @feed_url = "http://www.burr.senate.gov/public/index.cfm?FuseAction=RSS.Feed"
    WebMock.stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "richard_burr.xml")), :status => 200)
    @results = Feed.from_rss(@feed_url)
    @results.first[:url].must_equal "http://www.burr.senate.gov/public/index.cfm?FuseAction=PressOffice.PressReleases&Type=Press Release&ContentRecord_id=65dbea38-d64c-6208-ef8f-2b000e899b3a"
    @results.first[:date].to_s.must_equal "2013-05-02"
  end

  it "handles relative URLs" do
    @feed_url = "http://www.gop.gov/republicans/news?offset=03/29/13"
    WebMock.stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "house_gop_releases.html")), :status => 200)
    @results = Scraper.house_gop(@feed_url)
    @results.last[:url].must_equal "http://www.gop.gov/republicans/other/relative_url_test.html"
  end
  
  it "scrapes a senate cold fusion page" do
    @url = "http://www.billnelson.senate.gov/news/media.cfm?year=2013"
    WebMock.stub_request(:any, @url).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'bill_nelson_press.html')), :status => 200)
    @results = Scraper.billnelson(year=2013)
    @results.last[:url].must_equal "http://www.billnelson.senate.gov/news/details.cfm?id=338190&"
  end
  
  it "scrapes vitter pages for 2013" do
    @vitter = "http://www.vitter.senate.gov/newsroom/press?year=2013"
    WebMock.stub_request(:any, @vitter).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'vitter_press.html')), :status => 200)
    @results = Scraper.vitter(year=2013)
    @results.map{|r| r[:domain]}.uniq.must_equal ["www.vitter.senate.gov"]
  end
  
  it "only scrapes vitter page for 2012" do
    @vitter = "http://www.vitter.senate.gov/newsroom/press?year=2012"
    WebMock.stub_request(:any, @vitter).to_return(:body => File.new(File.join(File.dirname(__FILE__), 'vitter_press.html')), :status => 200)
    @results = Scraper.vitter(year=2012)
    @results.map{|r| r[:domain]}.uniq.must_equal ["www.vitter.senate.gov"]    
  end
  
  it "scrapes sanford's press page" do
    @sanford_url = "http://sanford.house.gov/media-center/press-releases?page=0"
    @sanford_page = File.new(File.join(File.dirname(__FILE__), 'sanford_press.html'))
    WebMock.stub_request(:any, @sanford_url).to_return(:body => @sanford_page, :status => 200)

    expected_result = {
      :source => "http://sanford.house.gov/media-center/press-releases?page=0",
      :url    => "http://sanford.house.gov/media-center/press-releases/sanford-announces-public-schedule-for-april-18th-19th",
      :title  => "Sanford Announces Public Schedule for April 18th - 19th",
      :date   => Date.parse("2015-04-17"),
      :domain => "sanford.house.gov"
    }

    @results = Scraper.sanford(0)
    @results.length.must_equal 10
    @results.first.must_equal expected_result
  end
end
