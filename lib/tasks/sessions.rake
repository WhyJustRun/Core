namespace :sessions do
    desc "Clear expired sessions"
    task :trim => :environment do
        sql = 'DELETE FROM sessions WHERE updated_at < DATE_SUB(NOW(), INTERVAL 90 DAY);'
        ActiveRecord::Base.connection.execute(sql)
    end
end
