class Panel::DashboardController < PanelController

  def show
    redirect_to :panel_trades
  end

  # use this to continue a session
  def ping
    respond_to do |f|
      f.json  do
        render json: {}
      end
    end
  end

end
