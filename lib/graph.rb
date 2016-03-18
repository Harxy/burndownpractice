require 'mongoid'

class Graph
  include Mongoid::Document

  field :user, type: String
  field :date_started, type: Date
  field :name, type: String
  field :wordcount,   type: Integer
  field :days, type: Integer
  field :daily_wordcount, type: Hash
  field :desc, type: String
  field :completed, type: Boolean, default: false
  def wordcount_per_day
    wordcount / days
  end

  def cumulative
    daily_wordcount.each_value.inject(0){|key, value| key += value}
  end

  def current_burndown
    (Date.today.mjd - date_started.mjd + 1)*wordcount_per_day
  end

  def on_track?
    current_burndown <= cumulative
  end

  def requires_to_get_on_track
    current_burndown - cumulative
  end

  def fancy_finish_date
    (date_started + days - 1).strftime("%B %-d, %Y")
  end

  def fancy_start_date
    date_started.strftime("%B %-d, %Y")
  end

  def finish_date_object
    (date_started + days)
  end
  
  def finish_date
    (date_started + days - 1).strftime("%F")
  end

  def days_left
    days = Date.parse(finish_date).mjd - Date.today.mjd + 1
    days <= 2 ? 2 : days
  end

  def words_left
    wordcount - cumulative
  end

  def current_required_wordcount
    words_left / (days_left - 1)
  end
end
