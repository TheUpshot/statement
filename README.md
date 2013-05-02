# Statement

Statement parses RSS feeds and HTML pages containing press releases and other official statements from members of Congress, and produces hashes with information about those pages.

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
    
results = Statement::Link.house_gop('http://www.gop.gov/republicans/news?offset=03/29/11')
puts results.first
{:source=>"http://www.gop.gov/republicans/news?offset=03/29/11", :url=>"http://poe.house.gov/News/DocumentSingle.aspx?DocumentID=233004", :title=>"Poe: War in the Name of Humanity", :date=> <Date: 2011-03-29 ((2455650j,0s,0n),+0s,2299161j)>, :domain=>"poe.house.gov"}
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

