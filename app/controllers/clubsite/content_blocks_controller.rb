module Clubsite
  # jEditable POST target for editing content blocks in place.
  class ContentBlocksController < BaseController
    def update
      content_block = current_club.content_blocks.find_by(id: entity_id(params[:id].to_s))
      return render plain: 'Not Found', status: :not_found if content_block.nil?

      authorize content_block
      content_block.update(content: params[:value])
      # jEditable swaps the response into the block, so return the stored HTML.
      render html: content_block.content.to_s.html_safe
    end

    private

    def entity_id(id)
      id.sub('content-block-', '')
    end
  end
end
