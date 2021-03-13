# https://blog.kurttomlinson.com/posts/how-to-run-cron-jobs-with-the-whenever-gem-in-a-docker-container
ENV.each_key do |key|
  env key.to_sym, ENV[key]
end

set :environment, ENV["RAILS_ENV"]

job_type :rake, "cd :path && :environment_variable=:environment :bundle_command rake :task :output"

every 1.day do
  rake "sessions:trim"
end

