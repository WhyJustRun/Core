class ContentBlock < ApplicationRecord
  belongs_to :club

  # Default content seeded the first time a key is read for a club, keyed by
  # `order`. Ported from the CakePHP ContentBlock.default.* configuration.
  DEFAULTS = {
    'general_information' => { 1 => '<h2>Welcome!</h2>' },
    'general_maps_information' => { 1 => 'No map information has been entered yet.' },
    'contact' => { 1 => 'No contact information has been entered yet.' }
  }.freeze

  # Returns the club's content blocks for a key, ordered by `order`. If the
  # club has none yet, seeds them from DEFAULTS (matching the CakePHP
  # ContentBlocksController::view behavior).
  def self.for_key(key, club)
    blocks = club.content_blocks.where(key: key).order(:order).to_a
    return blocks if blocks.any?

    defaults = DEFAULTS[key]
    return [] if defaults.nil?

    defaults.map do |order, content|
      club.content_blocks.create!(key: key, order: order, content: content)
    end
  end
end
