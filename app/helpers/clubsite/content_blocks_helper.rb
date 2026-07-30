module Clubsite
  module ContentBlocksHelper
    # Renders the club's content blocks for a key, each wrapped in
    # <div id="content-block-<id>" class="content-block"> (plus wjr-editable
    # for users who may edit, so editable.js attaches the in-place editor).
    # Ported from the CakePHP ContentBlockHelper::render.
    def render_content_blocks(key, start_wrapper = nil, end_wrapper = nil)
      editable = user_signed_in? && current_user.has_privilege?(Settings.privileges.contentBlock.edit, current_club)
      css_class = editable ? 'content-block wjr-editable' : 'content-block'

      blocks = ContentBlock.for_key(key, current_club)
      safe_join(blocks.map do |block|
        parts = []
        parts << start_wrapper.html_safe if start_wrapper
        # Content is admin-authored HTML.
        parts << content_tag(:div, block.content.to_s.html_safe,
                             id: "content-block-#{block.id}", class: css_class)
        parts << end_wrapper.html_safe if end_wrapper
        safe_join(parts)
      end)
    end
  end
end
