xml.instruct!
xml.declare! :DOCTYPE, :StartList, :SYSTEM, "IOFdata.dtd"
xml << render(:partial => "events/list_2", :locals => { :events => @events })
