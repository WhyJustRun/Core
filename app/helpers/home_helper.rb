module HomeHelper
  def render_club_tree(parent_clubs)
    res = '<ul>'
    parent_clubs.each { |club|
      res << '<li>' + link_to(club.location, club.url) + '</li>'
      res << render_club_tree(club.children)
    }
    res << '</ul>'
    res.html_safe
  end
end
