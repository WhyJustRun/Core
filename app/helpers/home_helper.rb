module HomeHelper
  def render_club_tree(parent_clubs)
    res = '<ul>'
    parent_clubs.each { |club|
      if (club.visible == true)
        res << '<li>' + link_to(club.location, club.url) + '</li>'
        res << render_club_tree(club.children)
      end
    }
    res << '</ul>'
    res.html_safe
  end

  def formatted_clubs_list(clubs)
    list = []
    clubs.each { |c|
      str = '<a href="' + c.url + '"><strong>' + c.acronym + ' (' + c.location + ')</strong></a>'
      list << str.html_safe
    }

    list.to_sentence.html_safe
  end
end
