namespace :clubs do
  
    desc "Outputs a JSON encoded array of all clubs in the database."
    task :list => :environment do
      # Disable logging so it doesn't corrupt the JSON output
      disabled_logger = Logger.new(nil)
      Rails.logger = disabled_logger
      ActiveRecord::Base.logger = disabled_logger
      
      print Club.all.to_json
    end
end
