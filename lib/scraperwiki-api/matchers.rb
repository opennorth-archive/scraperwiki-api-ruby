require 'rspec'

module ScraperWiki
  class API
    # @example
    #   require 'scraperwiki-api'
    #
    #   api = ScraperWiki::API.new
    #   info = api.scraper_getinfo(shortname).first
    #
    #   describe Hash do
    #     include ScraperWiki::API::Matchers
    #     subject {info}
    #
    #     it {should be_protected}
    #     it {should be_editable_by('frabcus')}
    #     it {should run(:daily)}
    #     it {should_not be_broken}
    #     it {should have_at_least_the_keys(['name', 'email']).on('swdata')}
    #     it {should have_at_most_the_keys(['name', 'email', 'tel', 'fax']).on('swdata')}
    #     it {should have_total_rows_of(42).on('swdata')}
    #   end
    #
    # RSpec matchers for ScraperWiki scrapers.
    # @see http://rubydoc.info/gems/rspec-expectations/RSpec/Matchers
    module Matchers
      class CustomMatcher
        def initialize(expected)
          @expected = expected
        end

        def matches?(info)
          @info = info
        end

        def failure_phrase
          @expected
        end

        def negative_failure_phrase
          failure_phrase
        end

        def failure_message_for_should
          [failure_phrase, ScraperWiki::API.scraper_url(@info['short_name'])].join "\n"
        end

        def failure_message_for_should_not
          failure_message_for_should
        end
      end

      class PrivacyStatusMatcher < CustomMatcher
        def matches?(info)
          super
          info['privacy_status'] == @expected
        end

        def failure_phrase
          "expected #{@info['short_name']} to be #{@expected}"
        end
      end
      # @example
      #   it {should be_public}
      def be_public
        PrivacyStatusMatcher.new 'public'
      end
      # @example
      #   it {should be_protected}
      def be_protected
        PrivacyStatusMatcher.new 'visible'
      end
      # @example
      #   it {should be_private}
      def be_private
        PrivacyStatusMatcher.new 'private'
      end

      class UserRolesMatcher < CustomMatcher
        def matches?(info)
          super
          %w(owner editor).any? do |userrole|
            info['userroles'][userrole].include? @expected
          end
        end

        def failure_phrase
          "expected #{@info['short_name']} to be editable by #{@expected}"
        end
      end
      # @example
      #   it {should be_editable_by 'frabcus'}
      def be_editable_by(expected)
        UserRolesMatcher.new expected
      end

      class RunIntervalMatcher < CustomMatcher
        def matches?(info)
          super
          info['run_interval'] == ScraperWiki::API::RUN_INTERVALS[@expected]
        end

        def failure_phrase
          if @expected == -1
            "expected #{@info['short_name']} to never run"
          else
            "expected #{@info['short_name']} to run #{@expected}"
          end
        end
      end
      # @example
      #   it {should run(:daily)}
      def run(expected)
        RunIntervalMatcher.new expected
      end
      # @example
      #   it {should never_run}
      def never_run
        RunIntervalMatcher.new :never
      end

      class TablesMatcher < CustomMatcher
        def on(table)
          @table = table
          self
        end
      end

      class KeysMatcher < TablesMatcher
        def matches?(info)
          super
          difference.empty?
        end

        def failure_predicate
          raise NotImplementerError
        end

        def failure_phrase
          "#{@info['short_name']} #{failure_predicate}: #{difference.join ', '}"
        end
      end

      class MissingKeysMatcher < KeysMatcher
        def difference
          @expected - @info['datasummary']['tables'][@table]['keys']
        end

        def failure_predicate
          'is missing keys'
        end
      end
      # @example
      #   it {should have_at_least_the_keys(['fieldA', 'fieldB']).on('swdata')}
      def have_at_least_the_keys(expected)
        MissingKeysMatcher.new expected
      end

      class ExtraKeysMatcher < KeysMatcher
        def difference
          @info['datasummary']['tables'][@table]['keys'] - @expected
        end

        def failure_predicate
          'has extra keys'
        end
      end
      # @example
      #   it {should have_at_most_the_keys(['fieldA', 'fieldB', 'fieldC', 'fieldD']).on('swdata')}
      def have_at_most_the_keys(expected)
        ExtraKeysMatcher.new expected
      end

      class CountMatcher < TablesMatcher
        def matches?(info)
          super
          info['datasummary']['tables'][@table]['count'] == @expected
        end

        def failure_phrase
          "expected #{@info['short_name']} to have #{@expected} rows, not #{@info['datasummary']['tables'][@table]['count']}"
        end
      end
      # @example
      #   it {should have_total_rows_of(42).on('swdata')}
      def have_total_rows_of(expected)
        CountMatcher.new expected
      end

      class RunEventsMatcher < CustomMatcher
        def last_run
          @info['runevents'][0]
        end
      end

      class ExceptionMessageMatcher < RunEventsMatcher
        def matches?(info)
          super
          exception_message
        end

        def exception_message
          last_run['exception_message']
        end

        def failure_phrase
          "#{@info['short_name']} is broken: #{exception_message}"
        end
      end
      # @example
      #   it {should_not be_broken}
      def be_broken
        ExceptionMessageMatcher.new nil
      end
    end
  end
end
