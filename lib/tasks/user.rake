namespace :user do
  desc 'Create a user'
  task :create, [:first_name, :last_name, :email, :password, :admin] => [:environment] do |t, args|
    args = {admin: false}.merge args
    args[:admin] = ['true', '1'].include? args[:admin]
    begin
      u = User.create! first_name: args[:first_name], last_name: args[:last_name], password: args[:password], password_confirmation: args[:password]
      u.email_addresses.create! email: args[:email], verified_at: Time.now, primary_at: Time.now
      u.grant :admin if args[:admin]
      puts "#{args[:first_name]}'s account has been created."
    rescue => e
      puts e.message
    end
  end
end
