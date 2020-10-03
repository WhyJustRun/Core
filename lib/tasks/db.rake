namespace :db do
  
  desc "Populate database with example data. NOTE: the database should be seeded first."
  task :populate_example_data => :environment do
    club = Club.create(
      name: "Orienteering Club",
      acronym: "OC",
      location: "The Cloud",
      lat: 49,
      lng: -123,
      country: "CAN",
      timezone: "America/Vancouver",
      visible: 1,
      domain: "localhost:3001",
      club_category: ClubCategory.find_by(name: 'Club'),
      layout: "default",
      use_map_urls: 1
    )
    
    admin_group = Group.create(name: 'Administrator', access_level: 100, description: 'Has access to user details and can merge user accounts. Also has all the privileges of Webmasters and Executives.', club: club)
    webmaster_group = Group.create(name: 'Webmaster', access_level: 90, description: 'Club webmasters can edit privileges and have all the privileges of Executives.', club: club)
    executive_group = Group.create(name: 'Executive', access_level: 80, description: 'Can add/modify events, maps, event organizers, resource pages.', club: club)
    
    admin = User.create(club: club, name: "Admin", email: "admin@example.com", password: "password", password_confirmation: "password")
    webmaster = User.create(club: club, name: "Webmaster", email: "webmaster@example.com", password: "password", password_confirmation: "password")
    executive = User.create(club: club, name: "Executive", email: "executive@example.com", password: "password", password_confirmation: "password")
    
    Privilege.create(user: admin, user_group: admin_group)
    Privilege.create(user: webmaster, user_group: webmaster_group)
    Privilege.create(user: executive, user_group: executive_group)
  end
end
