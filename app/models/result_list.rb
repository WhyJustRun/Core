class ResultList < ApplicationRecord
  LIVE_STATUS = 'live'
  FINAL_STATUS = 'final'

  belongs_to :event
  belongs_to :user

  validates :type, inclusion: {
    in: %w(live final),
    message: "Result list type must be live or final"
  }

  # One-way synchronizes the result list to the results/courses tables
  def sync_result_list
    if type != FINAL_STATUS
      raise 'Can only sync results using a finalized result list'
    end

    if invalid?
      raise 'Result list must be valid before syncing can be performed'
    end


  end

  # Resolves conflicts using a list of resolutions
  # resolution hash: name, class, organisation, id
  def self.resolve_result_list_user_conflicts(resolutions, data)
    # TODO
    data
  end

  # Returns a list of conflicts
  # conflict hash: name, class, organisation
  def self.result_list_user_conflicts(event_id, data)
    parser = ResultListParser.new data, event_id
    parser.find_user_conflicts
  end
end
