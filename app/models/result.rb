class Result < ActiveRecord::Base
  belongs_to :user
  belongs_to :course
	
  @@iof_status = {
    :inactive => 'Inactive', 
    :did_not_start => 'DidNotStart', 
    :active => 'Active', 
    :finished => 'Finished', 
    :ok => 'OK', 
    :mis_punch => 'MisPunch', 
    :did_not_finish => 'DidNotFinish', 
    :disqualified => 'Disqualified', 
    :not_competing => 'NotCompeting', 
    :sport_withdrawal => 'SportWithdr', 
    :over_time => 'OverTime', 
    :moved => 'Moved', 
    :moved_up => 'MovedUp', 
    :cancelled => 'Cancelled'
  }
	
  # CompetitorStatus from the IOF standard
  validates_inclusion_of :status, :in => @@iof_status.keys
	
  def status
    read_attribute(:status).to_sym
  end
  
  def iof_status
    @@iof_status[status]
  end
	
  def iof_status= (value)
    self.status = @@iof_status.key(value)
  end
  
  def status= (value)
    write_attribute(:status, value.to_s)
  end
  
  def time
    if not time_seconds.nil? then
      time_seconds.since(Time.utc(0))
    end
  end
end
