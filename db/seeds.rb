# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

ClubCategory.create(name: "Club")
ClubCategory.create(name: "NationalRegion")
ClubCategory.create(name: "NationalFederation")
ClubCategory.create(name: "IOF")
ClubCategory.create(name: "Other")
ClubCategory.create(name: "IOFRegion")
ClubCategory.create(name: "School")
ClubCategory.create(name: "Company")
ClubCategory.create(name: "Military")

EventClassification.create(name: "International", iof_3_0_name: "International", iof_2_0_3_name: "int", description: "Large event with international attendance")
EventClassification.create(name: "National", iof_3_0_name: "National", iof_2_0_3_name: "nat", description: "National championship or national event")
EventClassification.create(name: "Regional", iof_3_0_name: "Regional", iof_2_0_3_name: "reg", description: "Canada Cup, A-meet, or provincial championship")
EventClassification.create(name: "Local", iof_3_0_name: "Local", iof_2_0_3_name: "loc", description: "Weekend event or B-meet")
EventClassification.create(name: "Club", iof_3_0_name: "Club", iof_2_0_3_name: "other", description: "Weekday event or event not relevant to other clubs")

MapStandard.create(name: "ISOM2000", description: "Older IOF forest standard", color: "rgba(104,208,124,1)")
MapStandard.create(name: "ISSOM", description: "IOF sprint standard", color: "rgba(229,0,122,1)")
MapStandard.create(name: "Other", description: "Club standard", color: "rgba(252,178,63,1)")
MapStandard.create(name: "ISOM2017", description: "IOF forest standard", color: "rgba(52,193,78,1)")
MapStandard.create(name: "ISSkiOM", description: "Ski-O standard", color: "rgba(174,174,179,1)")

OfficialClassification.create(name: "O100", description: "Organize and plan C events")
OfficialClassification.create(name: "O200", description: "Organize and plan B events. Control C events")
OfficialClassification.create(name: "O300", description: "Organize and plan regional level Canada Cup events such as WCOCs")
OfficialClassification.create(name: "O400", description: "Organize and plan all events")
OfficialClassification.create(name: "O500", description: "Control all events. Act as a World Ranking Event Advisor")
OfficialClassification.create(name: "IOF EA", description: "IOF Event Adviser")

Role.create(name: "Event Director", description: "Has overall responsibility for the event. Ensures everything and everyone is organised.")
Role.create(name: "Course Planner", description: "Is responsible for the competitors from the moment they leave the start line until they enter the finish chute, which includes planning the courses, printing the maps and control descriptions, and setting out controls and water in the forest.")
Role.create(name: "Host", description: "Greets People")
Role.create(name: "Controller", description: "Confirms the course meets required standards. Usually only for bigger events.")
Role.create(name: "Organizer", description: "Standard type of organiser. Takes care of most aspects of the event. Used mainly for small events, where there is no distinction between course planner and meet director.")
Role.create(name: "Membership", description: "Signs up new and returning members. Ensures waiver has been understood and signed")
Role.create(name: "Coach", description: "Coaches athletic and navigational techniques to newcomers and experienced orienteers")
Role.create(name: "Assistant", description: "General assistant, doing whatever is needed.")
Role.create(name: "Permit", description: "Gets permits for the event from landowners.")