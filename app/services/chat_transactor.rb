class ChatTransactor

  attr_accessor :client

  def initialize
    @client = HipChat::Client.new ENV['hipchat_api_token'], api: 'v2'
  end

  def self.notify room, from, msg, options = {}
    hipchat = ChatTransactor.new
    hipchat.notify room, from, msg, options
  end

  def notify room, from, msg, options = {}
    unless Rails.env.test?
      @client[room].send(from, msg, options)
      Logger.new("#{Rails.root}/log/chat_transactor.log").info({room: room, from: from, msg: msg}.to_json)
    end
  end

end
