module Clubsite
  # Collects Open Graph meta tags for the layout head, which yields
  # :open_graph (see layouts/clubsite/_head.html.erb).
  module OpenGraphHelper
    def og_tag(property, value)
      content_for :open_graph, tag.meta(property: property, content: value)
    end
  end
end
