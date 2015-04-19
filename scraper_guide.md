## Contributing Scrapers

Some members of Congress either don't have RSS feeds of their press releases, or the ones they have are broken. That's where scraping comes in. Unfortunately, members also tend to change the layouts of their sites more often than you might think, so it's not always a matter of writing a single scraper and forgetting about it.

That doesn't mean that writing member-specific scrapers is particularly difficult. Many lawmakers have similar sites, so you can either build off an existing scraper or even add to an existing one. Here's the basic process:

### Setup

1. Ruby: if you don't have it, install Ruby (version 2.x) and `gem install bundler`
2. Fork the [repository](https://github.com/TheUpshot/statement) and clone it to a directory on your computer.
3. cd into that directory and run `bundle install` to install the gems used by Statement.

### Scraper Design

Most lawmakers have press release sections of their sites that display the date, title and link of a press release. Take Barbara Boxer, the California Democratic senator. Her [press release page](http://www.boxer.senate.gov/press/release/) is somewhat typical in that it features a table of releases, 10 to a page. The goal is to scrape that page, and optionally others if the site is paginated (most congressional press release sites are), and to build an Array of Ruby hashes that contain each release's url, date and title, along with two other piece of information: the source page of press release urls and the domain of the site (which helps to identify the lawmaker).

To do this, we use Nokogiri, a Ruby HTML and XML parser, rather than regular expressions. One of Nokogiri's strengths is that it can parse HTML documents based on CSS classes, XPath or via HTML entity search. Statement has a helper method, `open_html`, that loads the press release url into Nokigiri's parser. Senator Boxer's scraper might look like this:

```ruby
def self.boxer
  results = []
  url = "http://www.boxer.senate.gov/press/release"
  domain = 'www.boxer.senate.gov'
  doc = open_html(url)
  return if doc.nil?
  doc.css("tr")[1..-1].each do |row|
    results << { :source => url, :url => "http://"+domain + row.children[3].children[1]['href'], :title => row.children[3].children[1].text.strip, :date => Date.parse(row.children[1].text), :domain => domain}
  end
  results
end
```
For the first row that would produce the following hash:

```ruby
=> {:source=>"http://www.boxer.senate.gov/press/release", :url=>"http://www.boxer.senate.gov/press/release/boxer-feinstein-colleagues-introduces-bill-in-support-of-positive-train-control/", :title=>"Boxer, Feinstein, Colleagues Introduces Bill in Support of Positive Train Control", :date=><Date: 2015-04-17 ((2457130j,0s,0n),+0s,2299161j)>, :domain=>"www.boxer.senate.gov"}
```

For people new to Nokogiri, perhaps the hardest part is navigating its nodes - a `tr` node will have children `td` nodes, for example. The best advice we can provide is to spend time in the console trying to navigate up and down an HTML document's nodes. Calling the `text` method on any Nokogiri object will print its contents.

The best advice is to work off an existing [member scraper](https://github.com/TheUpshot/statement/blob/master/lib/statement/scraper.rb). You don't need to write anything except the scraper method; we'll take care of the rest once you submit your pull request.
