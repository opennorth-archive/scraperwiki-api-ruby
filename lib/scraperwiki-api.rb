require 'json'

require 'httparty'

module ScraperWiki
  # A Ruby wrapper for the ScraperWiki API.
  # @see https://scraperwiki.com/docs/api
  class API
    include HTTParty
    base_uri 'api.scraperwiki.com/api/1.0'

    def initialize(apikey = nil)
      @apikey = apikey
    end

    # Query and extract data via a general purpose SQL interface.
    #
    # @param [String] shortname the scraper's shortname (as it appears in the URL)
    # @param [String] query a SQL query
    # @param [Hash] opts optional arguments
    # @options opts [String] :format one of "jsondict", "jsonlist", "csv",
    #   "htmltable" or "rss2"
    # @options opts [String] :attach datastores from other scrapers, delimited
    #   by ';' (refer to internal api)
    # @see https://scraperwiki.com/docs/ruby/ruby_help_documentation/
    def datastore_sqlite(shortname, query, opts = {})
      request_with_apikey '/datastore/sqlite', opts
    end

    # Extract data about a scraper's code, owner, history, etc.
    #
    # @param [String] shortname the scraper's shortname (as it appears in the URL)
    # @param [Hash] opts optional arguments
    # @options opts [String] :version version number (-1 for most recent) [default -1]
    # @options opts [String] :history_start_date history and runevents are
    #   restricted to this date or after, enter as YYYY-MM-DD
    # @options opts [String] :quietfields list of fields to exclude from the
    #   output for quicker response, delimited by '|'. Must be a subset of
    #   'code|runevents|datasummary|userroles|history'
    def scraper_getinfo(shortname, opts = {})
      request_with_apikey '/scraper/getinfo', {shortname: shortname}.merge(opts)
    end

    # See what the scraper did during each run.
    #
    # @param [String] shortname the scraper's shortname (as it appears in the URL)
    # @param [Hash] opts optional arguments
    # @options opts [String] runid a run ID
    def scraper_getruninfo(shortname, opts = {})
      request_with_apikey '/scraper/getruninfo', {shortname: shortname}.merge(opts)
    end

    # Find out information about a user
    #
    # @param [String] username a ScraperWiki username
    def scraper_getuserinfo(username)
      request_with_apikey '/scraper/getuserinfo', username: username
    end

    # Search the titles and descriptions of all the scrapers.
    #
    # Example output:
    #
    # [
    #   {
    #     "description": "Scrapes stuff.",
    #     "language": "python",
    #     "created": "1970-01-01T00:00:00",
    #     "title": "Example scraper",
    #     "short_name": "example-scraper",
    #     "privacy_status": "public"
    #   },
    #   ...
    # ]
    #
    # @param [Hash] opts optional arguments
    # @option opts [String] :searchquery search terms
    # @option opts [String] :maxrows number of results to return [default 5]
    # @option opts [String] :requestinguser who makes the search (orders the matches)
    def scraper_search(opts = {})
      request_with_apikey '/scraper/search', opts
    end

    # Search for a user by name
    #
    # Example output:
    #
    # [
    #   {
    #     "username": "1234567",
    #     "profilename": "John Doe",
    #     "date_joined": "1970-01-01T00:00:00"
    #   },
    #   ...
    # ]
    #
    # @param [Hash] opts optional arguments
    # @option opts [String] :searchquery search terms
    # @option opts [String] :maxrows number of results to return [default 5]
    # @option opts [String] :nolist space-separated list of users not to return
    # @option opts [String] :requestinguser who makes the search (orders the matches)
    def scraper_usersearch(opts = {})
      if Array === opts[:nolist]
        opts[:nolist] = opts[:nolist].join ' '
      end
      request '/scraper/usersearch', opts
    end

  private

    def request_with_apikey(path, opts = {})
      if @apikey
        opts[:apikey] = @apikey
      end
      request path, opts
    end

    def request(path, opts)
      JSON.parse self.class.get(path, query: opts)
    end
  end
end
