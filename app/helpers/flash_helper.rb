module FlashHelper

  def simple_flash_error
    raw(flash[:error] ? '<div data-alert class="alert-box error f-15">'+flash[:error]+' <a href="#" class="close">&times;</a></div>' : '')
  end

  def simple_flash_success
    raw(flash[:success] ? '<div data-alert class="alert-box success f-15">'+flash[:success]+' <a href="#" class="close">&times;</a></div>' : '')
  end

  def simple_flash
    raw(simple_flash_error + simple_flash_success)
  end

end
