namespace :sessions do
    desc "Clear expired sessions"
    task :trim => :environment do
        sql = 'DELETE FROM sessions WHERE updated_at < DATE_SUB(NOW(), INTERVAL 90 DAY);'
        ApplicationRecord.connection.execute(sql)
    end
end
