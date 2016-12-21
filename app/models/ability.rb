class Ability

  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    if user.admin?
      can :manage, :all
    else
      can :manage, EmailAddress, user: user
      can :manage, CryptoAddress, user: user
      can :manage, Trade, user: user
      can :read, TradeTransaction, user: user
    end
  end

end
