module Clubsite
  # Base for all controllers served on club domains. Resolves the club from the
  # request host, runs the request in the club's timezone, and picks the club's
  # layout.
  class BaseController < ApplicationController
    LAYOUTS = %w[default other].freeze

    before_action :set_current_club
    around_action :use_club_time_zone
    layout :club_layout

    helper_method :current_club, :club_resources

    rescue_from Pundit::NotAuthorizedError, with: :not_authorized

    private

    def set_current_club
      # Match with the port first so development domains like
      # demo.localhost:3000 work, then without it (production domains carry no
      # port, whatever port the server actually runs on).
      @current_club = Club.find_by(domain: request.host_with_port) || Club.find_by(domain: request.host)
      return if @current_club.present?

      redirected = Club.find_by(redirect_domain: request.host_with_port) ||
                   Club.find_by(redirect_domain: request.host)
      if redirected
        redirect_to "#{redirected.domain_protocol}://#{redirected.domain}#{request.fullpath}",
                    status: :moved_permanently, allow_other_host: true
      else
        render plain: "No club website exists for this domain. Contact support@whyjustrun.ca for help.",
               status: :not_found
      end
    end

    def current_club
      @current_club
    end

    def club_resources
      @club_resources ||= Resource.for_club(current_club)
    end

    def use_club_time_zone(&block)
      if current_club
        Time.use_zone(current_club.timezone, &block)
      else
        yield
      end
    end

    def club_layout
      return 'clubsite/embed' if request.format == :embed

      name = current_club&.layout
      name = 'default' unless LAYOUTS.include?(name)
      "clubsite/#{name}"
    end

    def not_authorized
      redirect_to '/', alert: 'You are not authorized to access that page. Please switch to a different account or ask your club webmaster for permissions'
    end
  end
end
