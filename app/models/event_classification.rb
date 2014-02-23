class EventClassification < ActiveRecord::Base
  CLUB_ID = 5
  LOCAL_ID = 4
  REGIONAL_ID = 3
  NATIONAL_ID = 2
  INTERNATIONAL_ID = 1

  has_many :events
end
