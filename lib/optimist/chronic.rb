require 'chronic'


module Optimist

# Option for dates using Chronic gem.
# Mainly for compatibility with Optimist.
# Use of Chronic switches to United States formatted
# dates (MM/DD/YYYY) as opposed to DD/MM/YYYY

class ChronicDateOption < Option
  register_alias :chronic_date
  register_alias :'chronic::date'
  def type_format ; "=<date>" ; end
  def parse(paramlist, _neg_given)
    paramlist.map do |pg|
      pg.map do |param|
        parse_date_param(param)
      end
    end
  end

  private
  def parse_date_param(param)
    if param.respond_to?(:year) and param.respond_to?(:month) and param.respond_to(:day)
      return Date.new(param.year, param.month, param.day)
    end
    time = Chronic.parse(param)
    time ? Date.new(time.year, time.month, time.day) : Date.parse(param)
  rescue ArgumentError
    raise CommandlineError, "option '#{self.name}' needs a valid date"
  end
  
end

end
