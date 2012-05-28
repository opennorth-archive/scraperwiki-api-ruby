require 'httparty'

module ScraperWiki
  # A Ruby wrapper for the ScraperWiki API.
  # @see https://scraperwiki.com/docs/api
  class API
    include HTTParty
    base_uri 'api.scraperwiki.com/api/1.0'

    class Error < StandardError; end
    class ScraperNotFound < Error; end

    RUN_INTERVALS = {
      never: -1,
      monthly: 2678400,
      weekly: 604800,
      daily: 86400,
      hourly: 3600,
    }

    class << self
      # Returns the URL to the scraper's overview.
      #
      # @param [String] shortname the scraper's shortname
      # @return [String] the URL to the scraper's overview
      def scraper_url(shortname)
        "https://scraperwiki.com/scrapers/#{shortname}/"
      end

      # Returns the URL to edit the scraper.
      #
      # @param [String] shortname the scraper's shortname
      # @return [String] the URL to edit the scraper
      def edit_scraper_url(shortname)
        "https://scraperwiki.com/scrapers/#{shortname}/edit/"
      end
    end

    # Initializes a ScraperWiki API object.
    def initialize(apikey = nil)
      @apikey = apikey
    end

    # Queries and extracts data via a general purpose SQL interface.
    #
    # To make an RSS feed you need to use SQL's +AS+ keyword (e.g. "SELECT name
    # AS description") to make columns called +title+, +link+, +description+,
    # +guid+ (optional, uses link if not available) and +pubDate+ or +date+.
    #
    # +jsondict+ example output:
    #
    #     [
    #       {
    #         "fieldA": "valueA",
    #         "fieldB": "valueB",
    #         "fieldC": "valueC",
    #       },
    #       ...
    #     ]
    #
    # +jsonlist+ example output:
    #
    #     {
    #       "keys": ["fieldA", "fieldB", "fieldC"],
    #       "data": [
    #         ["valueA", "valueB", "valueC"],
    #         ...
    #       ]
    #     }
    #
    # +csv+ example output:
    #
    #     fieldA,fieldB,fieldC
    #     valueA,valueB,valueC
    #     ...
    #
    # @param [String] shortname the scraper's shortname (as it appears in the URL)
    # @param [String] query a SQL query
    # @param [Hash] opts optional arguments
    # @option opts [String] :format one of "jsondict", "jsonlist", "csv",
    #   "htmltable" or "rss2"
    # @option opts [String] :attach ";"-delimited list of shortnames of other
    #   scrapers whose data you need to access
    # @return [Array,Hash,String]
    # @see https://scraperwiki.com/docs/ruby/ruby_help_documentation/
    #
    # @note The query string parameter is +name+, not +shortname+
    #   {https://scraperwiki.com/docs/api#sqlite as in the ScraperWiki docs}
    def datastore_sqlite(shortname, query, opts = {})
      if Array === opts[:attach]
        opts[:attach] = opts[:attach].join ';'
      end
      request_with_apikey '/datastore/sqlite', {name: shortname, query: query}.merge(opts)
    end

    # Extracts data about a scraper's code, owner, history, etc.
    #
    # * +runid+ is a Unix timestamp with microseconds and a UUID.
    # * The value of +records+ is the same as that of +total_rows+ under +datasummary+.
    # * +run_interval+ is the number of seconds between runs. It is one of:
    #   * -1 (never)
    #   * 2678400 (monthly)
    #   * 604800 (weekly)
    #   * 86400 (daily)
    #   * 3600 (hourly)
    # * +privacy_status+ is one of:
    #   * "public" (everyone can see and edit the scraper and its data)
    #   * "visible" (everyone can see the scraper, but only contributors can edit it)
    #   * "private" (only contributors can see and edit the scraper and its data)
    # * An individual +runevents+ hash will have an +exception_message+ key if
    #   there was an error during that run.
    #
    # Example output:
    #
    #     [
    #       {
    #         "code": "require 'nokogiri'\n...",
    #         "datasummary": {
    #           "tables": {
    #             "swdata": {
    #               "keys": [
    #                 "fieldA",
    #                 ...
    #               ],
    #               "count": 42,
    #               "sql": "CREATE TABLE `swdata` (...)"
    #             },
    #             "swvariables": {
    #               "keys": [
    #                 "value_blob",
    #                 "type",
    #                 "name"
    #               ],
    #               "count": 2,
    #               "sql": "CREATE TABLE `swvariables` (`value_blob` blob, `type` text, `name` text)"
    #             },
    #             ...
    #           },
    #           "total_rows": 44,
    #           "filesize": 1000000
    #         },
    #         "description": "Scrapes websites for data.",
    #         "language": "ruby",
    #         "title": "Example scraper",
    #         "tags": [],
    #         "short_name": "example-scraper",
    #         "userroles": {
    #           "owner": [
    #             "johndoe"
    #           ],
    #           "editor": [
    #             "janedoe",
    #             ...
    #           ]
    #         },
    #         "last_run": "1970-01-01T00:00:00",
    #         "created": "1970-01-01T00:00:00",
    #         "runevents": [
    #           {
    #             "still_running": false,
    #             "pages_scraped": 5,
    #             "run_started": "1970-01-01T00:00:00",
    #             "last_update": "1970-01-01T00:00:00",
    #             "runid": "1325394000.000000_xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx",
    #             "records_produced": 42
    #           },
    #           ...
    #         ],
    #         "records": 44,
    #         "wiki_type": "scraper",
    #         "privacy_status": "visible",
    #         "run_interval": 604800,
    #         "attachable_here": [],
    #         "attachables": [],
    #         "history": [
    #           ...,
    #           {
    #             "date": "1970-01-01T00:00:00",
    #             "version": 0,
    #             "user": "johndoe",
    #             "session": "Thu, 1 Jan 1970 00:00:08 GMT"
    #           }
    #         ]
    #       }
    #     ]
    #
    # @param [String] shortname the scraper's shortname (as it appears in the URL)
    # @param [Hash] opts optional arguments
    # @option opts [String] :version version number (-1 for most recent) [default -1]
    # @option opts [String] :history_start_date history and runevents are
    #   restricted to this date or after, enter as YYYY-MM-DD
    # @option opts [String] :quietfields "|"-delimited list of fields to exclude
    #   from the output. Must be a subset of 'code|runevents|datasummary|userroles|history'
    # @return [Array]
    #
    # @note Returns an array although the array seems to always have only one item
    # @note The +tags+ field seems to always be an empty array
    # @note The query string parameter is +name+, not +shortname+
    #   {https://scraperwiki.com/docs/api#getinfo as in the ScraperWiki docs}
    def scraper_getinfo(shortname, opts = {})
      if Array === opts[:quietfields]
        opts[:quietfields] = opts[:quietfields].join '|'
      end
      request_with_apikey '/scraper/getinfo', {name: shortname}.merge(opts)
    end

    # See what the scraper did during each run.
    #
    # Example output:
    #
    #     [
    #       {
    #         "run_ended": "1970-01-01T00:00:00",
    #         "first_url_scraped": "http://www.iana.org/domains/example/",
    #         "pages_scraped": 5,
    #         "run_started": "1970-01-01T00:00:00",
    #         "runid": "1325394000.000000_xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx",
    #         "domainsscraped": [
    #           {
    #             "domain": "http://example.com",
    #             "bytes": 1000000,
    #             "pages": 5
    #           }
    #           ...
    #         ],
    #         "output": "...",
    #         "records_produced": 42
    #       }
    #     ]
    #
    # @param [String] shortname the scraper's shortname (as it appears in the URL)
    # @param [Hash] opts optional arguments
    # @option opts [String] runid a run ID
    # @return [Array]
    #
    # @note Returns an array although the array seems to always have only one item
    # @note The query string parameter is +name+, not +shortname+
    #   {https://scraperwiki.com/docs/api#getinfo as in the ScraperWiki docs}
    def scraper_getruninfo(shortname, opts = {})
      request_with_apikey '/scraper/getruninfo', {name: shortname}.merge(opts)
    end

    # Find out information about a user.
    #
    # Example output:
    #
    #     [
    #       {
    #         "username": "johndoe",
    #         "profilename": "John Doe",
    #         "coderoles": {
    #           "owner": [
    #             "johndoe.emailer",
    #             "example-scraper",
    #             ...
    #           ],
    #           "email": [
    #             "johndoe.emailer"
    #           ],
    #           "editor": [
    #             "yet-another-scraper",
    #             ...
    #           ]
    #         },
    #         "datejoined": "1970-01-01T00:00:00"
    #       }
    #     ]
    #
    # @param [String] username a username
    # @return [Array]
    #
    # @note Returns an array although the array seems to always have only one item
    # @note The date joined field is +date_joined+ (with underscore) on
    #   {#scraper_usersearch}
    def scraper_getuserinfo(username)
      request_with_apikey '/scraper/getuserinfo', username: username
    end

    # Search the titles and descriptions of all the scrapers.
    #
    # Example output:
    #
    #     [
    #       {
    #         "description": "Scrapes websites for data.",
    #         "language": "ruby",
    #         "created": "1970-01-01T00:00:00",
    #         "title": "Example scraper",
    #         "short_name": "example-scraper",
    #         "privacy_status": "public"
    #       },
    #       ...
    #     ]
    #
    # @param [Hash] opts optional arguments
    # @option opts [String] :searchquery search terms
    # @option opts [Integer] :maxrows number of results to return [default 5]
    # @option opts [String] :requestinguser the name of the user making the
    #   search, which changes the order of the matches
    # @return [Array]
    def scraper_search(opts = {})
      request_with_apikey '/scraper/search', opts
    end

    # Search for a user by name.
    #
    # Example output:
    #
    #     [
    #       {
    #         "username": "johndoe",
    #         "profilename": "John Doe",
    #         "date_joined": "1970-01-01T00:00:00"
    #       },
    #       ...
    #     ]
    #
    # @param [Hash] opts optional arguments
    # @option opts [String] :searchquery search terms
    # @option opts [Integer] :maxrows number of results to return [default 5]
    # @option opts [String] :nolist space-separated list of usernames to exclude
    #   from the output
    # @option opts [String] :requestinguser the name of the user making the
    #   search, which changes the order of the matches
    # @return [Array]
    #
    # @note The date joined field is +datejoined+ (without underscore) on
    #   {#scraper_getuserinfo}
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
      self.class.get(path, query: opts).parsed_response
    end
  end
end
