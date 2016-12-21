class Admin::FinanceController < AdminController

  def show
    @asset_holdings_balance = Finance::Asset.balance nil, {name: 'Asset Holdings'}
    @trans_revenue_balance = Finance::Revenue.balance nil, {category: :user_transaction_sales}
  end

end
