class << self

  def create_user d
    e = EmailAddress.find_or_initialize_by email: d[:email]
    if e.new_record?
      password = d[:password] || 'testP@ss'
      u = User.create! first_name: d[:first_name], last_name: d[:last_name], password: password, password_confirmation: password
      u.grant :admin if d[:admin]
      e.user = u
      e.verified_at = Time.now
      e.primary_at = Time.now
      e.save!
      ####
      if Rails.env.development?
        Finance.crypto_currencies.each do |c|
          u.add_funding Money.new(100000000000, c)
        end
      end
      ####
    end
  end

end

[{first_name: 'Larron', last_name: 'Armstead', email: 'larron@101.net', admin: true},
 {first_name: 'Rob', last_name: 'Hof', email: 'rhof@101.net', admin: true}].each do |u|
  create_user u
end
