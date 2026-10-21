module Clubsite
  module MenuHelper
    def menu_item(name, url, css_class = '', home: false)
      classes = [menu_active_class(url, home), css_class].reject(&:blank?).join(' ')
      content_tag(:li, link_to(name, url), class: classes.presence)
    end

    private

    def menu_active_class(path, home)
      current = request.path
      if home
        ['', '/', '/pages/home'].include?(current) ? 'active' : nil
      else
        current == path ? 'active' : nil
      end
    end
  end
end
