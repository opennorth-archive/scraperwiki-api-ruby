require 'time'

require 'rspec'
require 'yajl'

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
    #     it {should have_a_table('swdata')}
    #     it {should have_a_row_count_of(42).on('swdata')}
    #
    #     # Check for missing keys:
    #     it {should have_at_least_the_keys(['name', 'email']).on('swdata')}
    #
    #     # Check for extra keys:
    #     it {should have_at_most_the_keys(['name', 'email', 'tel', 'fax']).on('swdata')}
    #   end
    #
    #   data = api.datastore_sqlite('example-scraper', 'SELECT * from `swdata`')
    #
    #   describe 'example-scraper' do
    #     include ScraperWiki::API::Matchers
    #     subject {data}
    #
    #     it {should set_any_of(['name', 'first_name', 'last_name'])}
    #
    #     # Validate the values of individual fields:
    #     it {should_not have_blank_values.in('name')}
    #     it {should have_unique_values.in('email')}
    #     it {should have_values_of(['M', 'F']).in('gender')}
    #     it {should have_values_matching(/\A[^@\s]+@[^@\s]+\z/).in('email')}
    #     it {should have_values_starting_with('http://').in('url')}
    #     it {should have_values_ending_with('Inc.').in('company_name')}
    #     it {should have_integer_values.in('year')}
    #
    #     # If you store a hash or an array of hashes in a field as a JSON string,
    #     # you can validate the values of these subfields by chaining on an +at+:
    #     it {should have_values_of(['M', 'F']).in('extra').at('gender')}
    #
    #     # Check for missing keys within subfields:
    #     it {should have_values_with_at_least_the_keys(['subfield1', 'subfield2']).in('fieldA')}
    #
    #     # Check for extra keys within subfields:
    #     it {should have_values_with_at_most_the_keys(['subfield1', 'subfield2', 'subfield3', 'subfield4']).in('fieldA')}
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
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def negative_failure_message
          raise NotImplementerError, 'Subclasses must implement this method'
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

        def negative_failure_message
          "expected #{@actual['short_name']} to not be #{@expected}"
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

        def negative_failure_message
          "expected #{@actual['short_name']} to not be editable by #{@expected}"
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

        def negative_failure_message
          if @expected == -1
            "expected #{@actual['short_name']} to run at some time"
          else
            "expected #{@actual['short_name']} to not run #{@expected}"
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

      class LastRunMatcher < ScraperInfoMatcher
        def months
          @multiplier = 2592000 # 30 days
          self
        end
        alias :month :months

        def weeks
          @multiplier = 604800
          self
        end
        alias :week :weeks

        def days
          @multiplier = 86400
          self
        end
        alias :day :days

        def hours
          @multiplier = 3600
          self
        end
        alias :hour :hours

        def minutes
          @multiplier = 60
          self
        end
        alias :minute :minutes

        def seconds
          @multiplier = 3600
          self
        end
        alias :second :seconds

        # @todo +last_run+ seems to follow British Summer Time, in which case it
        #   will be +00, not +01, for part of the year.
        def matches?(actual)
          super
          Time.now - Time.parse("#{@actual['last_run']}+01") < span
        end

        def span
          @expected * (@multiplier || 1)
        end

        def failure_message
          "expected #{@actual['short_name']} to have run within #{span} seconds"
        end

        def negative_failure_message
          "expected #{@actual['short_name']} to not have run within #{span} seconds"
        end
      end
      # @example
      #   it {should have_run_within(7).days}
      def have_run_within(expected)
        LastRunMatcher.new expected
      end

      class TableMatcher < ScraperInfoMatcher
        def matches?(actual)
          super
          actual['datasummary']['tables'].key?(@expected)
        end

        def failure_message
          "expected #{@actual['short_name']} to have a #{@expected} table"
        end

        def negative_failure_message
          "expected #{@actual['short_name']} to not have a #{@expected} table"
        end
      end
      # @example
      #   it {should have_a_table('swdata')}
      def have_a_table(expected)
        TableMatcher.new expected
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

        def failure_message
          "#{@actual['short_name']} #{failure_predicate}: #{difference.join ', '}"
        end

        def negative_failure_message
          "#{@actual['short_name']} #{negative_failure_predicate}: #{difference.join ', '}"
        end

        def failure_predicate
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def negative_failure_message
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def difference
          raise NotImplementerError, 'Subclasses must implement this method'
        end
      end

      class MissingKeysMatcher < KeysMatcher
        def difference
          keys = if @actual['datasummary']['tables'][@table]
            @actual['datasummary']['tables'][@table]['keys']
          else
            []
          end
          @expected - keys
        end

        def failure_predicate
          'is missing keys'
        end

        def negative_failure_predicate
          "isn't missing keys"
        end
      end
      # @example
      #   it {should have_at_least_the_keys(['fieldA', 'fieldB']).on('swdata')}
      def have_at_least_the_keys(expected)
        MissingKeysMatcher.new expected
      end

      class ExtraKeysMatcher < KeysMatcher
        def difference
          keys = if @actual['datasummary']['tables'][@table]
            @actual['datasummary']['tables'][@table]['keys']
          else
            []
          end
          keys - @expected
        end

        def failure_predicate
          'has extra keys'
        end

        def negative_failure_predicate
          'has no extra keys'
        end
      end
      # @example
      #   it {should have_at_most_the_keys(['fieldA', 'fieldB', 'fieldC', 'fieldD']).on('swdata')}
      def have_at_most_the_keys(expected)
        ExtraKeysMatcher.new expected
      end

      class CountMatcher < TablesMatcher
        def count
          if @actual['datasummary']['tables'][@table]
            @actual['datasummary']['tables'][@table]['count']
          else
            0
          end
        end

        def matches?(actual)
          super
          count == @expected
        end

        def failure_message
          "expected #{@actual['short_name']} to have #{@expected} rows, not #{count}"
        end

        def negative_failure_message
          "expected #{@actual['short_name']} to not have #{@expected} rows"
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

        def negative_failure_message
          "#{@actual['short_name']} isn't broken: #{exception_message}"
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
            if @actual['data']
              @actual['data'].map do |array|
                hash = {}
                @actual['keys'].each_with_index do |key,index|
                  hash[key] = array[index]
                end
                hash
              end
            else
              {}
            end
          else
            raise NotImplementerError, "Can only handle jsondict or jsonlist formats"
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
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def mismatches
          raise NotImplementerError, 'Subclasses must implement this method'
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

        def failure_message
          "#{failure_size} of #{items.size} #{failure_description}\n#{failures.map(&:inspect).join "\n"}"
        end

        def negative_failure_message
          "#{failure_size} of #{items.size} #{negative_failure_description}\n#{failures.map(&:inspect).join "\n"}"
        end

        def failure_description
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def negative_failure_description
          raise NotImplementerError, 'Subclasses must implement this method'
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

        def negative_failure_description
          "records set any of #{@expected.join ','}"
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

        def at(subfield)
          @subfield = subfield
          self
        end

        # @note +@subfield+ can be a hash or an array of hashes
        def matcher(meth)
          if @subfield
            items.send(meth) do |item|
              if blank? item[@field]
                meth == :reject
              else
                v = Yajl::Parser.parse item[@field]
                if Hash === v
                  if blank? v[@subfield]
                    meth == :reject
                  else
                    match? v[@subfield]
                  end
                elsif Array === v
                  v.all? do |w|
                    if Hash === w
                      if blank? w[@subfield]
                        meth == :reject
                      else
                        match? w[@subfield]
                      end
                    else
                      raise NotImplementerError, 'Can only handle subfields that are hashes or arrays of hashes'
                    end
                  end
                else
                  raise NotImplementerError, 'Can only handle subfields that are hashes or arrays of hashes'
                end
              end
            end
          else
            items.send(meth) do |item|
              if blank? item[@field]
                meth == :reject
              else
                match? item[@field]
              end
            end
          end
        end

        def matches
          matcher :select
        end

        def mismatches
          matcher :reject
        end

        def blank?(v)
          v.respond_to?(:empty?) ? v.empty? : !v
        end

        def failure_description
          if @subfield
            "#{@field}:#{@subfield} values #{failure_predicate}"
          else
            "#{@field} values #{failure_predicate}"
          end
        end

        def negative_failure_description
          if @subfield
            "#{@field}:#{@subfield} values #{negative_failure_predicate}"
          else
            "#{@field} values #{negative_failure_predicate}"
          end
        end

        def failure_predicate
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def negative_failure_predicate
          raise NotImplementerError, 'Subclasses must implement this method'
        end
      end

      class HaveBlankValues < FieldMatcher
        def match?(v)
          blank? v
        end

        def failure_predicate
          'are blank'
        end

        def negative_failure_predicate
          'are present'
        end
      end
      # @example
      #   it {should_not have_blank_values.in('name')}
      def have_blank_values
        HaveBlankValues.new nil
      end

      class HaveValuesOf < FieldMatcher
        def match?(v)
          @expected.include? v
        end

        def failure_predicate
          "aren't one of #{@expected.join ', '}"
        end

        def negative_failure_predicate
          "are one of #{@expected.join ', '}"
        end
      end
      # @example
      #   it {should have_values_of(['M', 'F']).in('gender')}
      def have_values_of(expected)
        HaveValuesOf.new expected
      end

      class HaveValuesMatching < FieldMatcher
        def match?(v)
          v[@expected]
        end

        def failure_predicate
          "don't match #{@expected.inspect}"
        end

        def negative_failure_predicate
          "match #{@expected.inspect}"
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
          if @subfield
            items.each do |item|
              unless blank? item[@field]
                v = Yajl::Parser.parse item[@field]
                if Hash === v
                  unless blank? v[@subfield]
                    counts[v[@subfield]] += 1
                  end
                elsif Array === v
                  v.each do |w|
                    if Hash === w
                      unless blank? w[@subfield]
                        counts[w[@subfield]] += 1
                      end
                    else
                      raise NotImplementerError, 'Can only handle subfields that are hashes or arrays of hashes'
                    end
                  end
                else
                  raise NotImplementerError, 'Can only handle subfields that are hashes or arrays of hashes'
                end
              end
            end
          else
            items.each do |item|
              unless blank? item[@field]
                counts[item[@field]] += 1
              end
            end
          end
          counts.select{|_,count| count > 1}.keys
        end

        def failure_predicate
          "aren't unique"
        end

        def negative_failure_predicate
          'are unique'
        end
      end
      # @example
      #   it {should have_unique_values.in('email')}
      def have_unique_values
        HaveUniqueValues.new nil
      end

      class HaveValuesStartingWith < FieldMatcher
        def match?(v)
          v.start_with? @expected
        end

        def failure_predicate
          "don't start with #{@expected}"
        end

        def negative_failure_predicate
          "start with #{@expected}"
        end
      end
      # @example
      #   it {should have_values_starting_with('http://').in('url')}
      def have_values_starting_with(expected)
        HaveValuesStartingWith.new expected
      end

      class HaveValuesEndingWith < FieldMatcher
        def match?(v)
          v.end_with? @expected
        end

        def failure_predicate
          "don't end with #{@expected}"
        end

        def negative_failure_predicate
          "end with #{@expected}"
        end
      end
      # @example
      #   it {should have_values_ending_with('Inc.').in('company_name')}
      def have_values_ending_with(expected)
        HaveValuesEndingWith.new expected
      end

      class HaveIntegerValues < FieldMatcher
        def match?(v)
          Integer(v) rescue false
        end

        def failure_predicate
          "aren't integers"
        end

        def negative_failure_predicate
          'are integers'
        end
      end
      # @example
      #   it {should have_integer_values.in('year')}
      def have_integer_values
        HaveIntegerValues.new nil
      end

      class FieldKeyMatcher < FieldMatcher
        def match?(v)
          w = Yajl::Parser.parse v
          if Hash === w
            difference(w).empty?
          elsif Array === w
            w.all? do |x|
              if Hash === x
                difference(x).empty?
              else
                raise NotImplementerError, 'Can only handle subfields that are hashes or arrays of hashes'
              end
            end
          else
            raise NotImplementerError, 'Can only handle subfields that are hashes or arrays of hashes'
          end
        end

        def difference(v)
          raise NotImplementerError, 'Subclasses must implement this method'
        end

        def failure_predicate
          "#{predicate}: #{difference.join ', '}"
        end

        def negative_failure_predicate
          "#{negative_predicate}: #{difference.join ', '}"
        end
      end

      class HaveValuesWithAtLeastTheKeys < FieldKeyMatcher
        def difference(v)
          @expected - v.keys
        end

        def predicate
          'are missing keys'
        end

        def negative_predicate
          "aren't missing keys"
        end
      end
      # @example
      #   it {should have_values_with_at_least_the_keys(['subfield1', 'subfield2']).in('fieldA')}
      def have_values_with_at_least_the_keys(expected)
        HaveValuesWithAtLeastTheKeys.new expected
      end

      class HaveValuesWithAtMostTheKeys < FieldKeyMatcher
        def difference(v)
          v.keys - @expected
        end

        def predicate
          'have extra keys'
        end

        def negative_predicate
          'have no extra keys'
        end
      end
      # @example
      #   it {should have_values_with_at_most_the_keys(['subfield1', 'subfield2', 'subfield3', 'subfield4']).in('fieldA')}
      def have_values_with_at_most_the_keys(expected)
        HaveValuesWithAtMostTheKeys.new expected
      end
    end
  end
end
