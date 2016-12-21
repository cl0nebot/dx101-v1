Money.infinite_precision = true
MoneyRails.configure do |config|

  config.register_currency = {
    priority: 200,
    iso_code: 'SMU',
    name: 'Standard Membership Unit',
    symbol: '',
    symbol_first: true,
    subunit: nil,
    subunit_to_unit: 100,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 200,
    iso_code: 'PMU',
    name: 'Preferred Membership Unit',
    symbol: '',
    symbol_first: true,
    subunit: nil,
    subunit_to_unit: 100,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'XBT',
    name: 'Bitcoin',
    symbol: '',
    symbol_first: true,
    subunit: 'Satoshi',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'LTC',
    name: 'Litecoin',
    symbol: '',
    symbol_first: true,
    subunit: 'Lite-toshi',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'PPC',
    name: 'Peercoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'XDG',
    name: 'Dogecoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'QRK',
    name: 'Quarkcoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'AUR',
    name: 'Auroracoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'MAX',
    name: 'Maxcoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'MZC',
    name: 'Mazacoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'XPM',
    name: 'Primecoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'DRK',
    name: 'Darkcoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

  config.register_currency = {
    priority: 300,
    iso_code: 'BC',
    name: 'Blackcoin',
    symbol: '',
    symbol_first: true,
    subunit: '',
    subunit_to_unit: 100000000,
    thousands_separator: ',',
    decimal_mark: '.'
  }

end
