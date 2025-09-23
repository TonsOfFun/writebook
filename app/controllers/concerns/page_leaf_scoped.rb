module PageLeafScoped extend ActiveSupport::Concern
  included do
    before_action :set_leaf
  end

  private
    def set_leaf
      @leaf = Current.user.leaves.find(params[:page_id])
    end
end
