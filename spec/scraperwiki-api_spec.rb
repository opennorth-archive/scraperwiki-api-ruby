require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'time'

# We don't want to test the ScraperWiki API. We just want to check that the
# wrapper works.
describe ScraperWiki::API do
  EXAMPLE_SHORTNAME = 'frabcus.emailer'
  EXAMPLE_USERNAME = 'frabcus'
  QUIETFIELDS = %w(code runevents datasummary userroles history)

  before :all do
    @api = ScraperWiki::API.new
  end

  describe '#datastore_sqlite' do
    # @todo
  end

  describe '#scraper_getinfo' do
    it 'should return a non-empty array containing a single hash' do
      response = @api.scraper_getinfo EXAMPLE_SHORTNAME
      response.should be_an(Array)
      response.should have(1).item
      response.first.should be_a(Hash)
    end

    it 'should respect the :version argument' do
      bare = @api.scraper_getinfo(EXAMPLE_SHORTNAME).first
      bare.should_not have_key('currcommit')
      result = @api.scraper_getinfo(EXAMPLE_SHORTNAME, version: 1).first
      result.should have_key('currcommit')
      result['code'].should_not == bare['code']
    end

    it 'should respect the :history_start_date argument' do
      bare = @api.scraper_getinfo(EXAMPLE_SHORTNAME).first
      bare['history'].should have_at_least(2).items
      history_start_date = bare['history'][0]['date'][0..9]
      result = @api.scraper_getinfo(EXAMPLE_SHORTNAME, history_start_date: history_start_date).first
      result['history'].should have(1).item
    end

    it 'should respect the :quietfields argument (as an array)' do
      result = @api.scraper_getinfo(EXAMPLE_SHORTNAME, quietfields: QUIETFIELDS).first
      QUIETFIELDS.each do |key|
        result.should_not have_key(key)
      end
    end

    it 'should respect the :quietfields argument (as an string)' do
      result = @api.scraper_getinfo(EXAMPLE_SHORTNAME, quietfields: QUIETFIELDS.join('|')).first
      QUIETFIELDS.each do |key|
        result.should_not have_key(key)
      end
    end
  end

  describe '#scraper_getruninfo' do
    it 'should return a non-empty array containing a single hash' do
      response = @api.scraper_getruninfo EXAMPLE_SHORTNAME
      response.should be_an(Array)
      response.should have(1).item
      response.first.should be_a(Hash)
    end

    it 'should respect the :runid argument' do
      runevents = @api.scraper_getinfo(EXAMPLE_SHORTNAME).first['runevents']
      bare = @api.scraper_getruninfo(EXAMPLE_SHORTNAME).first
      bare['runid'].should == runevents.first['runid']
      response = @api.scraper_getruninfo(EXAMPLE_SHORTNAME, runid: runevents.last['runid']).first
      response['runid'].should_not == bare['runid']
    end
  end

  describe '#scraper_getuserinfo' do
    it 'should return a non-empty array containing a single hash' do
      response = @api.scraper_getuserinfo EXAMPLE_USERNAME
      response.should be_an(Array)
      response.should have(1).item
      response.first.should be_a(Hash)
    end
  end

  describe '#scraper_search' do
    it 'should return a non-empty array of hashes' do
      response = @api.scraper_search
      response.should be_an(Array)
      response.should have_at_least(1).item
      response.first.should be_a(Hash)
    end

    it 'should respect the :searchquery argument' do
      @api.scraper_search(searchquery: EXAMPLE_SHORTNAME).find{|result|
        result['short_name'] == EXAMPLE_SHORTNAME
      }.should_not be_nil
    end

    it 'should respect the :maxrows argument' do
      @api.scraper_search(maxrows: 1).should have(1).item
    end
  end

  describe '#scraper_usersearch' do
    it 'should return a non-empty array of hashes' do
      response = @api.scraper_usersearch
      response.should be_an(Array)
      response.should have_at_least(1).item
      response.first.should be_a(Hash)
    end

    it 'should respect the :searchquery argument' do
      @api.scraper_usersearch(searchquery: EXAMPLE_USERNAME).find{|result|
        result['username'] == EXAMPLE_USERNAME
      }.should_not be_nil
    end

    it 'should respect the :maxrows argument' do
      @api.scraper_usersearch(maxrows: 1).should have(1).item
    end

    it 'should respect the :nolist argument (as an array)' do
      usernames = @api.scraper_usersearch.map{|result| result['username']}
      @api.scraper_usersearch(nolist: usernames).find{|result|
        usernames.include? result['username']
      }.should be_nil
    end

    it 'should respect the :nolist argument (as an string)' do
      usernames = @api.scraper_usersearch.map{|result| result['username']}
      @api.scraper_usersearch(nolist: usernames.join(' ')).find{|result|
        usernames.include? result['username']
      }.should be_nil
    end
  end
end
