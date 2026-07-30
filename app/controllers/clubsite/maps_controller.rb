module Clubsite
  # Read-only map pages: listing, detail, usage report, plus serving map file
  # downloads and uploaded map renderings.
  class MapsController < BaseController
    # Serves uploaded media files through MediaStore. Shared with
    # CoursesController, which serves uploaded course maps the same way.
    module MediaServing
      CONTENT_TYPES = {
        '.png' => 'image/png',
        '.jpg' => 'image/jpeg',
        '.jpeg' => 'image/jpeg',
        '.gif' => 'image/gif',
        '.pdf' => 'application/pdf'
      }.freeze

      private

      # Serves the uploaded file (or one of its generated thumbnails) for the
      # given media type, falling back to the bundled default image when
      # nothing has been uploaded (the legacy app served the default with a
      # 200 as well).
      def serve_media(type, id_param, thumbnail)
        id = begin
          Integer(id_param)
        rescue ArgumentError, TypeError
          not_found_404
        end

        store = MediaStore.new(current_club.id, type)
        path = if thumbnail
                 not_found_404 unless store.valid_thumbnail?(thumbnail)
                 store.thumbnail_path(id, thumbnail)
               else
                 store.file_path(id)
               end
        path ||= MediaStore.default_image_path(type).to_s

        extension = File.extname(path).downcase
        send_file path, disposition: 'inline',
                        type: CONTENT_TYPES.fetch(extension, 'application/octet-stream')
      end
    end

    include MediaServing

    DROPBOX_DIRECT_DOWNLOAD_HOST = 'dl.dropboxusercontent.com'.freeze

    def index
      # The map markers are fetched client-side from /api/maps.json
      @edit = edit_maps?

      respond_to do |format|
        format.html
        # Advertised iframe embed; reuses the html template with the embed
        # layout picked by BaseController#club_layout.
        format.embed { render :index, formats: :html }
      end
    end

    def show
      @map = current_club.maps.find(params[:id])
      @events = current_club.events.where(map_id: @map.id).includes(:series).order(:date)
      @edit = edit_maps?
    end

    def report
      @maps = current_club.maps.order(:name)
    end

    def download
      map = current_club.maps.find(params[:id])
      # The legacy privilege for downloading map files (maps.viewOCAD) is level
      # 0, which every visitor (including anonymous) satisfies, so there is no
      # privilege check here.
      not_found_404 if map.file_url.blank?

      redirect_to direct_download_url(map.file_url), allow_other_host: true
    end

    # Displays a rendering of the map file (manually uploaded)
    def rendering
      serve_media('Map', params[:id], params[:thumbnail])
    end

    private

    def edit_maps?
      user_signed_in? && MapPolicy.new(current_user, Map.new(club: current_club)).edit?
    end

    # Make direct downloads work for Dropbox (it's broken in some browsers
    # without the dl=1 parameter)
    def direct_download_url(url)
      uri = URI.parse(url)
      uri.query = 'dl=1' if uri.host == DROPBOX_DIRECT_DOWNLOAD_HOST && uri.query.blank?
      uri.to_s
    rescue URI::InvalidURIError
      url
    end
  end
end
