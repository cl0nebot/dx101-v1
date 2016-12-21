namespace :cron do

  desc 'Checks the sidekiq enqueued count and notifies hipchat when breaching our threshold.'
  task :enqueued_monitor, [:threshold, :room] => [:environment] do |t, args|
    stats = Sidekiq::Stats.new
    room = args[:room] || 'Dev'
    if stats.enqueued >= args[:threshold].to_i
      ChatTransactor.notify room, "Sidekiq#{' [Dev]' if Rails.env.development?}", "Our sidekiq enqueud count has breached the threshold limit of #{args[:threshold]}.", {notify: true, color: 'red'}
    end
  end

  desc 'Checks the sidekiq retries count and notifies hipchat when breaching our threshold.'
  task :retries_monitor, [:threshold, :room] => [:environment] do |t, args|
    room = args[:room] || 'Dev'
    if Sidekiq::RetrySet.new.size >= args[:threshold].to_i
      ChatTransactor.notify room, "Sidekiq#{' [Dev]' if Rails.env.development?}", "Our sidekiq retries count has breached the threshold limit of #{args[:threshold]}.", {notify: true, color: 'red'}
    end
  end

end
