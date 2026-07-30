module Clubsite
  # The club home page, a fixed set of static pages, and dynamic Resources
  # pages that are edited in place with jEditable.
  class PagesController < BaseController
    # The only static templates /pages/:page may render. Arbitrary params are
    # never rendered as template paths.
    STATIC_PAGES = %w[contact resources admin export].freeze

    def home
      render :other if current_club.layout == 'other'
    end

    def show
      if params[:page].match?(/\A\d+\z/)
        show_dynamic_page(params[:page])
      elsif STATIC_PAGES.include?(params[:page])
        show_static_page(params[:page])
      else
        render_not_found
      end
    end

    def create
      @page = current_club.pages.new(page_params)
      # Section is hardcoded for now
      @page.section = 'Resources'
      authorize @page

      if @page.save
        flash[:success] = 'The page has been added.'
      else
        flash[:danger] = 'The page could not be added.'
      end
      redirect_to '/pages/resources'
    end

    # jEditable POST target for editing a page's content or title in place.
    def update
      page = current_club.pages.find_by(id: entity_id(params[:id].to_s))
      return render_not_found if page.nil?

      authorize page
      if params[:value].present?
        page.update(content: params[:value])
        content = params[:value]
      elsif params[:name].present?
        page.update(name: params[:name])
        content = params[:name]
      else
        # This should never happen, but somehow it does..
        content = nil
      end
      render plain: content
    end

    def destroy
      page = current_club.pages.find_by(id: params[:id])
      return render_not_found if page.nil?

      authorize page
      page.destroy
      redirect_to '/pages/resources'
    end

    private

    def show_dynamic_page(id)
      @page = current_club.pages.find_by(id: id)
      return render_not_found if @page.nil?

      render :display
    end

    def show_static_page(name)
      case name
      when 'resources'
        @pages = current_club.pages.where(section: 'Resources').select(:id, :name)
      when 'admin'
        authorize current_club, :admin?, policy_class: PagePolicy
        @allow_show_duplicates = current_user.has_privilege?(Settings.privileges.user.merge, current_club)
      end
      render name
    end

    def page_params
      params.require(:page).permit(:name, :content)
    end

    def entity_id(id)
      id.sub('page-resource-', '').sub('title-', '')
    end

    def render_not_found
      render plain: 'Not Found', status: :not_found
    end
  end
end
