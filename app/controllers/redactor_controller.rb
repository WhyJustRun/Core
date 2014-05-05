require 'fileutils'

class RedactorController < ApplicationController
  before_filter :authenticate_user!
  # since this request is coming via PHP, we don't have an authenticity token
  skip_before_filter  :verify_authenticity_token

  def upload_image
    data = params[:file]
    image_types = ['image/png', 'image/jpg', 'image/gif',
                   'image/jpeg', 'image/pjpeg']
    @url = nil
    if image_types.include? data.content_type
      @url = store_file(data)
    end

    respond_to :json, :html
  end

  def upload_file
    data = params[:file]
    @url = store_file(data)
    @filename = data.original_filename
    respond_to :json, :html
  end

  protected

  def store_file(data)
    raise "not authorized" unless RedactorPolicy.new(current_user).store_file?
    extension = File.extname(data.original_filename)
    root_path = Settings.dataFolder[Rails.env]
    root_url = Settings.dataURL[Rails.env]
    random = SecureRandom.urlsafe_base64
    random_folder_1 = SecureRandom.random_number(9).to_s
    random_folder_2 = SecureRandom.random_number(9).to_s
    folder = 'files/' + random_folder_1 + "/" + random_folder_2
    relative_path = "%s/%s%s" % [folder, random, extension]

    # ensure the folder structure exists
    FileUtils.mkpath(root_path + folder)

    File.open(root_path + relative_path, 'wb') do |file|
      file.write(data.read)
    end

    root_url + relative_path
  end
end
