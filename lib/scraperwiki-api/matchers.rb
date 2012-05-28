require 'rspec'

module ScraperWiki
  class API
    # @example
    #   require 'scraperwiki-api'
    #   api = ScraperWiki::API.new
    #
    #   info = api.scraper_getinfo('example-scraper').first
    #
    #   describe 'example-scraper' do
    #     include ScraperWiki::API::Matchers
    #     subject {info}
    #
    #     it {should be_protected}
    #     it {should be_editable_by('frabcus')}
    #     it {should run(:daily)}
    #     it {should_not be_broken}
    #     it {should have_at_least_the_keys(['name', 'email']).on('swdata')}
    #     it {should have_at_most_the_keys(['name', 'email', 'tel', 'fax']).on('swdata')}
    #     it {should have_a_row_count_of(42).on('swdata')}
    #   end
    #
    #   data = api.datastore_sqlite('example-scraper', 'SELECT * from `swdata`')
    #
    #   describe 'example-scraper' do
    #     include ScraperWiki::API::Matchers
    #     subject {data}
    #
    #     it {should_not have_blank_values.in('name')}
    #     it {should have_unique_values.in('email')}
    #     it {should have_values_of(['M', 'F']).in('gender')}
    #     it {should have_values_matching(/\A[^@\s]+@[^a\s]+\z/).in('email')}
    #     it {should have_values_starting_with('http://').in('url')}
    #     it {should have_values_ending_with('Inc.').in('company_name')}
    #     it {should have_integer_values.in('year')}
    #     it {should set_any_of(['name', 'first_name', 'last_name'])}
    #   end
    #
    # RSpec matchers for ScraperWiki scrapers.
    # @see http://rubydoc.info/gems/rspec-expectations/RSpec/Matchers
    module Matchers
      class CustomMatcher
        def initialize(expected)
          @expected = expected
        end

        def matches?(actual)
          @actual = actual
        end

        def does_not_match?(actual)
          @actual = actual
        end

        def failure_message
          NotImplementerError
        end

        def negative_failure_message
          failure_message
        end
      end

      # Scraper matchers -------------------------------------------------------

      class ScraperInfoMatcher < CustomMatcher
      end

      class PrivacyStatusMatcher < ScraperInfoMatcher
        def matches?(actual)
          super
          actual['privacy_status'] == @expected
        end

        def failure_message
          "expected #{@actual['short_name']} to be #{@expected}"
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

      class UserRolesMatcher < ScraperInfoMatcher
        def matches?(actual)
          super
          %w(owner editor).any? do |userrole|
            actual['userroles'][userrole].include? @expected
          end
        end

        def failure_message
          "expected #{@actual['short_name']} to be editable by #{@expected}"
        end
      end
      # @example
      #   it {should be_editable_by 'frabcus'}
      def be_editable_by(expected)
        UserRolesMatcher.new expected
      end

      class RunIntervalMatcher < ScraperInfoMatcher
        def matches?(actual)
          super
          actual['run_interval'] == ScraperWiki::API::RUN_INTERVALS[@expected]
        end

        def failure_message
          if @expected == -1
            "expected #{@actual['short_name']} to never run"
          else
            "expected #{@actual['short_name']} to run #{@expected}"
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

      class TablesMatcher < ScraperInfoMatcher
        def on(table)
          @table = table
          self
        end
      end

      class KeysMatcher < TablesMatcher
        def matches?(actual)
          super
          difference.empty?
        end

        def failure_predicate
          raise NotImplementerError
        end

        def failure_message
          "#{@actual['short_name']} #{failure_predicate}: #{difference.join ', '}"
        end
      end

      class MissingKeysMatcher < KeysMatcher
        def difference
          @expected - @actual['datasummary']['tables'][@table]['keys']
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
          @actual['datasummary']['tables'][@table]['keys'] - @expected
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
        def matches?(actual)
          super
          actual['datasummary']['tables'][@table]['count'] == @expected
        end

        def failure_message
          "expected #{@actual['short_name']} to have #{@expected} rows, not #{@actual['datasummary']['tables'][@table]['count']}"
        end
      end
      # @example
      #   it {should have_a_row_count_of(42).on('swdata')}
      def have_a_row_count_of(expected)
        CountMatcher.new expected
      end

      class RunEventsMatcher < ScraperInfoMatcher
        def last_run
          @actual['runevents'][0]
        end
      end

      class ExceptionMessageMatcher < RunEventsMatcher
        def matches?(actual)
          super
          exception_message
        end

        def exception_message
          last_run['exception_message']
        end

        def failure_message
          "#{@actual['short_name']} is broken: #{exception_message}"
        end
      end
      # @example
      #   it {should_not be_broken}
      def be_broken
        ExceptionMessageMatcher.new nil
      end

      # Datastore matchers -----------------------------------------------------

      class DatastoreMatcher < CustomMatcher
        def items
          @items ||= if Array === @actual
            @actual
          elsif Hash === @actual
            @actual['data'].map do |array|
              hash = {}
              @actual['keys'].each_with_index do |key,index|
                hash[key] = array[index]
              end
              hash
            end
          else
            raise NotImplementerError
          end
        end

        def matches?(actual)
          super
          @mismatches = mismatches
          @mismatches.empty?
        end

        def does_not_match?(actual)
          super
          @matches = matches
          @matches.empty?
        end

        def matches
          raise NotImplementerError
        end

        def mismatches
          raise NotImplementerError
        end

        def failures
          if @mismatches
            @mismatches
          else
            @matches
          end
        end

        def failure_size
          if @mismatches
            @mismatches.size
          else
            @matches.size
          end
        end

        def failure_description
          raise NotImplementerError
        end

        def failure_message
          "#{failure_size} of #{items.size} #{failure_description}\n#{failures.map(&:inspect).join "\n"}"
        end

        def negative_failure_message
          failure_message
        end
      end

      class SetAnyOf < DatastoreMatcher
        def mismatches
          items.select do |item|
            @expected.all? do |field|
              item[field].respond_to?(:empty?) ? item[field].empty? : !item[field]
            end
          end
        end

        def failure_description
          "records didn't set any of #{@expected.join ','}"
        end
      end
      # @example
      #   it {should set_any_of(['name', 'first_name', 'last_name'])}
      def set_any_of(expected)
        SetAnyOf.new expected
      end

      class FieldMatcher < DatastoreMatcher
        def in(field)
          @field = field
          self
        end

        def matches
          items.select do |item|
            match? item[@field]
          end
        end

        def mismatches
          items.reject do |item|
            match? item[@field]
          end
        end

        def blank?(v)
          v.respond_to?(:empty?) ? v.empty? : !v
        end

        def failure_description
          "'#{@field}' values #{failure_predicate}"
        end
      end

      class HaveBlankValues < FieldMatcher
        def match?(v)
          blank? v
        end

        def failure_predicate
          'are blank'
        end
      end
      # @example
      #   it {should_not have_blank_values.in('name')}
      def have_blank_values
        HaveBlankValues.new nil
      end

      class HaveValuesOf < FieldMatcher
        def match?(v)
          blank?(v) || @expected.include?(v)
        end

        def failure_predicate
          "aren't one of #{@expected.join ', '}"
        end
      end
      # @example
      #   it {should have_values_of(['M', 'F']).in('gender')}
      def have_values_of(expected)
        HaveValuesOf.new expected
      end

      class HaveValuesMatching < FieldMatcher
        def match?(v)
          blank?(v) || v[@expected]
        end

        def failure_predicate
          "don't match #{@expected.inspect}"
        end
      end
      # @example
      #   it {should have_values_matching(/\A[^@\s]+@[^a\s]+\z/).in('email')}
      def have_values_matching(expected)
        HaveValuesMatching.new expected
      end

      class HaveUniqueValues < FieldMatcher
        def mismatches
          counts = Hash.new 0
          items.each_with_index do |item,index|
            unless blank? item[@field]
              counts[item[@field]] += 1
            end
          end
          counts.select{|_,count| count > 1}.keys
        end

        def failure_predicate
          'are not unique'
        end
      end
      # @example
      #   it {should have_unique_values.in('email')}
      def have_unique_values
        HaveUniqueValues.new nil
      end

      class HaveValuesStartingWith < FieldMatcher
        def match?(v)
          blank?(v) || v.start_with?(@expected)
        end

        def failure_predicate
          "don't start with #{@expected}"
        end
      end
      # @example
      #   it {should have_values_starting_with('http://').in('url')}
      def have_values_starting_with(expected)
        HaveValuesStartingWith.new expected
      end

      class HaveValuesEndingWith < FieldMatcher
        def match?(v)
          blank?(v) || v.end_with?(@expected)
        end

        def failure_predicate
          "don't end with #{@expected}"
        end
      end
      # @example
      #   it {should have_values_ending_with('Inc.').in('company_name')}
      def have_values_ending_with(expected)
        HaveValuesEndingWith.new expected
      end

      class HaveIntegerValues < FieldMatcher
        def match?(v)
          blank?(v) || (Integer(v) rescue false)
        end

        def failure_predicate
          "aren't integers"
        end
      end
      # @example
      #   it {should have_integer_values.in('year')}
      def have_integer_values
        HaveIntegerValues.new nil
      end
    end
  end
end
