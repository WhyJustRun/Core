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
    # Build the links with link_to/content_tag so the club-supplied acronym and
    # location are HTML-escaped -- a club admin must not be able to inject
    # markup onto the shared apex homepage.
    clubs.map { |club|
      link_to(club.url) { content_tag(:strong, "#{club.acronym} (#{club.location})") }
    }.to_sentence.html_safe
  end
end
