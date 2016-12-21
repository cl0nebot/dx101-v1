class UniqueToParentValidator < ActiveModel::EachValidator
  
  def validate_each(record, attr, value)
    nest = record.send(options[:parent]).send(record.class.name.pluralize.parameterize.underscore) || []
    obj = nest.where("#{attr.to_s} = ?", value).first
    record.errors[attr] << (options[:message] || "of #{record.class.name.downcase} must be unique to #{options[:parent]}") unless obj.nil? or obj == record
  end

end
