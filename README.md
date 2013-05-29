# Statement

Statement parses RSS feeds and HTML pages containing press releases and other official statements from members of Congress, and produces hashes with information about those pages. It has been tested under Ruby 1.9.2 and 1.9.3.

## Coverage

Statement currently parses press releases for members of the House and Senate. For members with RSS feeds, you can pass the feed URL into Statement. For members without RSS feeds, HTML scrapers are provided, as are methods for speciality groups, such as House Republicans. Suggestions are welcomed.

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

Statement provides access to press releases and Facebook status updates from members of Congress. Most congressional offices have RSS feeds but some require HTML scraping. To parse an RSS feed, simply pass the URL to Statement's Feed class:

```ruby
require 'rubygems'
require 'statement'
    
results = Statement::Feed.from_rss('http://blumenauer.house.gov/index.php?option=com_bca-rss-syndicator&feed_id=1')
puts results.first
{:source=>"http://blumenauer.house.gov/index.php?option=com_bca-rss-syndicator&feed_id=1", :url=>"http://blumenauer.house.gov/index.php?option=com_content&amp;view=article&amp;id=2203:blumenauer-qwe-need-a-national-system-that-speaks-to-the-transportation-challenges-of-todayq&amp;catid=66:2013-press-releases", :title=>"Blumenauer: &quot;We need a national system that speaks to the transportation challenges of ...", :date=>#<Date: 2013-04-24 ((2456407j,0s,0n),+0s,2299161j)>, :domain=>"blumenauer.house.gov"}
```

The sites that require HTML scraping are detailed in individual methods, and can be called individually or in bulk:

```ruby
results = Statement::Scraper.billnelson
members = Statement::Scraper.member_scrapers
```

Using the `koala` gem, Statement can fetch Facebook status feeds, given a Facebook ID. You'll need to either set environment variables `APP_ID` and `APP_SECRET` or create a `config.yml` file containing `app_id` and `app_secret` keys and values.

```ruby
f = Statement::Facebook.new
results = f.feed('RepFincherTN08')
```

It also can process IDs in batches by passing an array of IDs and a `slice` argument to indicate how many ids in each batch:

```ruby
f = Statement::Facebook.new
results = f.batch(facebook_ids, 10)
```

In all cases Statement strips out posts that are not by the ID, and returns a Hash containing attributes from the feed:

```ruby
{:id=>"9307301412_10151632750071413", :body=>"This is Gold Star Mother Larraine McGee whose son, Christopher Everett, Army National Guard, was killed in action September 2005. Precious family.", :link=>"http://www.facebook.com/photo.php?fbid=10151632750021413&set=a.118418671412.133511.9307301412&type=1&relevant_count=1", :title=>nil, :type=>"photo", :status_type=>"added_photos", :created_time=>#<DateTime: 2013-05-28T14:49:08+00:00 ((2456441j,53348s,0n),+0s,2299161j)>, :updated_time=>#<DateTime: 2013-05-28T17:41:37+00:00 ((2456441j,63697s,0n),+0s,2299161j)>, :facebook_id=>"9307301412"}
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

