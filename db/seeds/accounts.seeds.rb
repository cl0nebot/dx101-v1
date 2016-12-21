Finance::Asset.find_or_create_by! name: 'MUs'
Finance::Asset.find_or_create_by! name: 'Hot' # customer coin in our hot wallet
Finance::Asset.find_or_create_by! name: 'Cold' # customer coin in our cold storage
Finance::Expense.find_or_create_by! name: 'Withdraw Fees'
