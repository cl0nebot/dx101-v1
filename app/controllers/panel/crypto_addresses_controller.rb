class Panel::CryptoAddressesController < PanelController

  load_and_authorize_resource only: [:edit, :update, :show, :hide]
  before_action :set_address, only: [:edit, :update, :show, :hide]

  def index
    @crypto_type = params[:crypto_type]
    @addresses = @current_user.crypto_addresses.visible.paginate page: (params[:page]||1).to_i, per_page: 10
    if @crypto_type and Finance.crypto_currencies.include? @crypto_type.to_sym
      @addresses = @addresses.send @crypto_type
    end
  end

  def new
    @crypto_type = params[:crypto_type]
    @address = @current_user.crypto_addresses.new
  end

  def create
    @crypto_type = params[:crypto_address][:currency]
    @label = params[:crypto_address][:label]
    if @crypto_type
      @address = @current_user.crypto_addresses.new currency: @crypto_type.to_sym, label: @label
      if @address.save
        redirect_to :panel_wallet_addresses, flash: {success: "#{Finance.crypto_name_by_currency(@crypto_type)} address successfully created"}
      else
        redirect_to request.referrer, flash: {error: 'There has been an error, try again or contact support if the issue persists'}
      end
    end
  end

  def edit
  end

  def update
    @label = params[:crypto_address][:label]
    @address.update_attribute :label, @label
    redirect_to panel_wallet_address_path(@address), flash: {success: "Address successfully updated"}
  end

  def show
    @deposits = @address.crypto_deposits
  end

  def hide
    @address.hide
    redirect_to request.referrer
  end

private

  def set_address
    @address = @crypto_address if @crypto_address
  end

end
