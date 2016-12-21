class Admin::UsersController < AdminController

  load_and_authorize_resource

  def index
  end

  def show
  end

  def add_funds
    # TODO: make this dynamic for now setting it to calc subunits at 100
    amount = BigDecimal.new params[:funds][:amount]
    currency = params[:funds][:currency]
    if amount and amount > 0
      amount_subunit = amount * 100
      @user.add_funding('Adding Funds', amount_subunit, currency)
      flash[:success] = 'Funds added'
    else
      flash[:error] = 'Submit an amount greater than zero.'
    end
    redirect_to request.referrer
  end

end
