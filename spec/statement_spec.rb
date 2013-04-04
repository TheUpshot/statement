require "minitest/autorun"
require_relative "../lib/statement"

describe Statement do
  it "parses an rss feed" do
    @results = Statement::Link.from_rss("http://ruiz.house.gov/rss.xml")
    @results.first[:domain].must_equal "ruiz.house.gov"
  end
  
  it "parses House GOP press release page" do
    @results = Statement::Link.house_gop("http://www.gop.gov/republicans/news?offset=03/29/13")
    @results.first[:source].must_equal "http://www.gop.gov/republicans/news?offset=03/29/13"
  end
  
  it "does not attempt to parse dates when none are present" do
    @results = Statement::Link.from_rss("http://culberson.house.gov/feed/rss/")
    @results.first[:date].must_equal nil
  end
  
end