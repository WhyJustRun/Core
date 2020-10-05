require 'nokogiri'

module Validators
  # Checks for an IOF XML 3.0 ResultList
  class ResultListValidator < ActiveModel::Validator
    def validate(record)
      record.errors[:base] << 'IOF XML 2.0 is not supported. Please export your results in IOF XML 3.0 format.'

      record.errors[:base] << 'IOF XML must be a Result List'

      record.errors[:base] << 'Invalid XML'
    end
  end
end