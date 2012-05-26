# The ScraperWiki API Ruby Gem

A Ruby wrapper for the ScraperWiki API.

## Installation

    gem install scraperwiki-api

## Examples

    >> require 'scraperwiki-api'

    >> api = ScraperWiki::API.new 'my-api-key' # API key is optional

    >> api.datastore_sqlite 'example-scraper', 'SELECT * FROM swdata LIMIT 10'
    => [{"fieldA"=>"valueA", "fieldB"=>"valueB", "fieldC"=>"valueC"}, ...]

    >> api.scraper_getinfo 'example-scraper'
    => [{"code"=>"require 'nokogiri'\n...", "datasummary"=>...}]

    >> api.scraper_getruninfo 'example-scraper'
    => [{"run_ended"=>"1970-01-01T00:00:00", "first_url_scraped"=>...}]

    >> api.scraper_getuserinfo 'johndoe'
    => [{"username"=>"johndoe", "profilename"=>"John Doe", "coderoles"=>...}]

    >> api.scraper_search searchquery: 'search terms'
    => [{"description"=>"Scrapes websites for data.", "language"=>"ruby", ...]

    >> api.scraper_usersearch searchquery: 'search terms'
    => [{"username"=>"johndoe", "profilename"=>"John Doe", "date_joined"=>...}]

Thorough documentation at [RubyDoc.info](http://rdoc.info/gems/scraperwiki-api/ScraperWiki/API).

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/scraperwiki-api-ruby](http://github.com/opennorth/scraperwiki-api-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2011 Open North Inc., released under the MIT license
