# Statement

Statement parses RSS feeds and HTML pages containing press releases and other official statements from members of Congress, and produces hashes with information about those pages. It has been tested under Ruby 1.9.2 and 1.9.3.

## Coverage

Statement currently parses press releases for the 535 members of the House and Senate, mostly via RSS feeds but some via HTML scrapers. Congressional committees that have RSS feeds are currently included, as are methods for speciality groups, such as House Republicans. Suggestions are welcomed.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'statement'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install statement
```

## Usage

```ruby
require 'rubygems'
require 'statement'
    
results = Statement::Link.from_rss('http://blumenauer.house.gov/index.php?option=com_bca-rss-syndicator&feed_id=1')
puts results.first
{:source=>"http://blumenauer.house.gov/index.php?option=com_bca-rss-syndicator&feed_id=1", :url=>"http://blumenauer.house.gov/index.php?option=com_content&amp;view=article&amp;id=2203:blumenauer-qwe-need-a-national-system-that-speaks-to-the-transportation-challenges-of-todayq&amp;catid=66:2013-press-releases", :title=>"Blumenauer: &quot;We need a national system that speaks to the transportation challenges of ...", :date=>#<Date: 2013-04-24 ((2456407j,0s,0n),+0s,2299161j)>, :domain=>"blumenauer.house.gov"}
```

## Tests

Statement uses MiniTest, to run tests:

```sh
$ rake test
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

If you write a new scraper, please use Nokogiri for parsing - see some of the existing examples for guidance. The ``domain`` attribute represents the URI base domain of the source site.

## Authors

* Derek Willis
* Jacob Harris

