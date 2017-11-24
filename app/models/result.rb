class Result < ActiveRecord::Base
  belongs_to :user
  belongs_to :course

  @@iof_status = {
    :inactive => 'Inactive',
    :did_not_start => 'DidNotStart',
    :active => 'Active',
    :finished => 'Finished',
    :ok => 'OK',
    :mis_punch => 'MissingPunch',
    :did_not_enter => 'DidNotEnter',
    :did_not_finish => 'DidNotFinish',
    :disqualified => 'Disqualified',
    :not_competing => 'NotCompeting',
    :sport_withdrawal => 'SportWithdrawal',
    :over_time => 'OverTime',
    :moved => 'Moved',
    :moved_up => 'MovedUp',
    :cancelled => 'Cancelled'
  }

  @@readable_status = {
    :ok => 'Finished',
    :inactive => 'Inactive',
    :did_not_start => 'DNS',
    :active => 'In Progress',
    :finished => 'Unofficial',
    :mis_punch => 'MP',
    :did_not_enter => 'DNE',
    :did_not_finish => 'DNF',
    :disqualified => 'DSQ',
    :not_competing => 'NC',
    :sport_withdrawal => 'Sport Withdrawal',
    :over_time => 'Over Time',
    :moved => 'Moved',
    :moved_up => 'Moved Up',
    :cancelled => 'Cancelled',
  }

  # CompetitorStatus from the IOF standard
  validates_inclusion_of :status, :in => @@iof_status.keys

  def status
    read_attribute(:status).to_sym
  end

  def status= (value)
    write_attribute(:status, value.to_s)
  end

  def iof_status
    @@iof_status[status]
  end

  def iof_status= (value)
    self.status = @@iof_status.key(value)
  end

  def readable_status
    @@readable_status[status]
  end

  def readable_status= (value)
    self.status = @@readable_status.key(value)
  end

  def time
    if not time_seconds.nil? then
      Time.utc(0) + time_seconds
    end
  end
end
