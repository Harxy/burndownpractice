require 'mongoid'

class Graph
  include Mongoid::Document

  field :user, type: String
  field :date_started, type: Date
  field :name, type: String
  field :wordcount,   type: Integer
  field :days, type: Integer
  field :daily_wordcount, type: Hash

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

  def finish_date
    (date_started + days - 1).strftime("%F")
  end
end
