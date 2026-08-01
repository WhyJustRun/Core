require 'fileutils'

class RedactorController < ApplicationController
  before_action :authenticate_user!
  # since this request is coming via PHP, we don't have an authenticity token
  skip_before_action  :verify_authenticity_token

  # Extensions accepted by the rich-text "insert file" button. The stored file
  # is served from the data host, and browsers pick how to render it from its
  # extension -- so anything that can be interpreted as HTML/script (.html,
  # .svg, .xml, .js, ...) is deliberately excluded to prevent stored XSS.
  ALLOWED_FILE_EXTENSIONS = %w[
    png jpg jpeg gif webp
    pdf txt csv
    doc docx xls xlsx ppt pptx odt ods odp
    zip
  ].freeze

  # The "insert image" button is restricted further to raster image types.
  ALLOWED_IMAGE_EXTENSIONS = %w[png jpg jpeg gif webp].freeze

  def upload_image
    @url = store_file(params[:file], ALLOWED_IMAGE_EXTENSIONS)
    respond_to :json, :html
  end

  def upload_file
    data = params[:file]
    @url = store_file(data, ALLOWED_FILE_EXTENSIONS)
    @filename = data.original_filename if @url
    respond_to :json, :html
  end

  protected

  # Stores an uploaded file under a random name, keeping only an allowlisted
  # extension derived from the original filename. Returns the public URL, or
  # nil when the upload is missing or its extension is not allowed.
  def store_file(data, allowed_extensions)
    raise "not authorized" unless RedactorPolicy.new(current_user).store_file?
    return nil if data.blank?

    extension = File.extname(data.original_filename.to_s).delete_prefix('.').downcase
    return nil unless allowed_extensions.include?(extension)

    root_path = Settings.dataFolder
    root_url = Settings.dataURL
    random = SecureRandom.urlsafe_base64
    random_folder_1 = SecureRandom.random_number(9).to_s
    random_folder_2 = SecureRandom.random_number(9).to_s
    folder = 'files/' + random_folder_1 + "/" + random_folder_2
    relative_path = "%s/%s.%s" % [folder, random, extension]

    # ensure the folder structure exists
    FileUtils.mkpath(root_path + folder)

    File.open(root_path + relative_path, 'wb') do |file|
      file.write(data.read)
    end

    root_url + relative_path
  end
end
