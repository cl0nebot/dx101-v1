module DateHelper

  def timeago time, options = {}
    options[:class] ||= "timeago"
    content_tag(:time, time.to_s, options.merge(:datetime => time.getutc.iso8601)) if time
  end

  def fmt_date date
    date.strftime("%m/%d/%Y")
  end

end
