namespace :clubs do
  
    desc "Outputs a JSON encoded array of all clubs in the database."
    task :list => :environment do
      print Club.all.to_json
    end
end
