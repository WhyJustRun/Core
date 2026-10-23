namespace :admin do
  desc 'Grants the global administrator role to a user: rails admin:grant_global_admin[USER_ID]'
  task :grant_global_admin, [:user_id] => :environment do |_task, args|
    user = User.find_by(id: args[:user_id]) || abort("No user with ID #{args[:user_id].inspect}")
    abort "User #{user.id} (#{user.name}) has no account" if user.email.blank?

    group = Group.find_or_create_by!(club_id: nil, access_level: 100) do |g|
      g.name = 'Global Administrator'
      g.description = 'Platform-wide administrator: all club privileges everywhere, plus the admin dashboard.'
    end
    privilege = Privilege.find_or_create_by!(user_id: user.id, group_id: group.id)
    puts "#{user.name} (##{user.id}) is a global administrator (privilege ##{privilege.id}, group ##{group.id})."
  end
end
