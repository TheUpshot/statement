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

  it "handles relative URLs" do
    @feed_url = "http://www.gop.gov/republicans/news?offset=03/29/13"
    stub_request(:any, @feed_url).to_return(:body => File.new(File.join(File.dirname(__FILE__), "house_gop_releases.html")), :status => 200)
    @results = Statement::Link.house_gop(@feed_url)
    @results.last[:url].must_equal "http://www.gop.gov/republicans/other/relative_url_test.html"
  end
end