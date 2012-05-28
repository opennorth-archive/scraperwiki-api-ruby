# The ScraperWiki API Ruby Gem

A Ruby wrapper for the ScraperWiki API.

## Installation

    gem install scraperwiki-api

## API Examples

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

More documentation at [RubyDoc.info](http://rdoc.info/gems/scraperwiki-api/ScraperWiki/API).

## Scraper validations

If your project uses a lot of scrapers – for example, [OpenCorporates](http://opencorporates.com/), which [scrapes company registries around the world](http://blog.opencorporates.com/2011/03/25/building-a-global-database-the-open-distributed-way/), or [Represent](http://represent.opennorth.ca/), which scrapes information on elected officials from government websites in Canada – you'll want to check that your scrapers behave the way you expect them to. This gem defines [RSpec](https://www.relishapp.com/rspec) matchers to do just that. For example:

    require 'scraperwiki-api'
    api = ScraperWiki::API.new
    info = api.scraper_getinfo(shortname).first

    describe 'Scraper errors' do
      include ScraperWiki::API::Matchers
      subject {info}

      it {should be_protected}
      it {should be_editable_by('frabcus')}
      it {should run(:daily)}
      it {should_not be_broken}
      it {should have_at_least_the_keys(['name', 'email']).on('swdata')}
      it {should have_at_most_the_keys(['name', 'email', 'tel', 'fax']).on('swdata')}
      it {should have_a_row_count_of(42).on('swdata')}
    end

More documentation at [RubyDoc.info](http://rdoc.info/gems/scraperwiki-api/ScraperWiki/API/Matchers).

## Bugs? Questions?

This gem's main repository is on GitHub: [http://github.com/opennorth/scraperwiki-api-ruby](http://github.com/opennorth/scraperwiki-api-ruby), where your contributions, forks, bug reports, feature requests, and feedback are greatly welcomed.

Copyright (c) 2011 Open North Inc., released under the MIT license
