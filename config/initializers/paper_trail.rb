module PaperTrail

  def self.serializer
    PaperTrail::Serializers::JSON
  end

  class Version < ActiveRecord::Base
    belongs_to :user
  end

end
