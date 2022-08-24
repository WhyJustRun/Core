namespace :clubs do
  
    desc "Outputs a JSON encoded array of all clubs in the database."
    task :list => :environment do
      # Disable logging so it doesn't corrupt the JSON output
      Rails.logger = Logger.new(nil)
      
      print Club.all.to_json
    end
end
