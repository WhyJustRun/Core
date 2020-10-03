class Official < ApplicationRecord
  belongs_to :official_classification
  belongs_to :user
end
