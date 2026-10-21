module Clubsite
  # Club branding uploads (header image, logo, custom stylesheet). Uploads are
  # stored on the shared data volume and thumbnailed; see Resource.
  class ResourcesController < BaseController
    def index
      authorize current_club, policy_class: ResourcePolicy
      @resources = Resource.where(club_id: current_club.id).index_by(&:key)
      @can_delete = ResourcePolicy.new(current_user, current_club).destroy?
    end

    def create
      authorize current_club, policy_class: ResourcePolicy

      key = params.dig(:resource, :key).to_s
      not_found_404 unless Resource::RESOURCE_KEYS.key?(key)

      begin
        Resource.save_for_club(current_club, key,
                               params.dig(:resource, :file), params.dig(:resource, :caption))
        flash[:success] = 'The resource has been uploaded.'
      rescue Resource::InvalidUpload => error
        flash[:danger] = error.message
      end
      redirect_to '/resources/index'
    end

    def destroy
      authorize current_club, policy_class: ResourcePolicy

      resource = Resource.where(club_id: current_club.id).find(params[:id])
      resource.destroy
      flash[:success] = 'The resource has been deleted.'
      redirect_to '/resources/index'
    end
  end
end
