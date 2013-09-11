namespace :sessions do
  desc "Clear expired sessions (more than 2 weeks old)"
  task :cleanup => :environment do
    sql = "DELETE FROM sessions WHERE (updated_at < '#{Date.today - 1.month}')"
    ActiveRecord::Base.connection.execute(sql)
  end
end
