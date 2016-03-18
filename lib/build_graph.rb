class BuildGraph
  attr_reader :graph

  def initialize(graph:)
    @graph = graph
  end

  def burndown_data
    data = {}
    date = graph.date_started
    cumulative_wordcount = graph.wordcount
    data[(date - 1).strftime("%F")] = cumulative_wordcount
    while date <= Date.today do
      cumulative_wordcount -= graph.wordcount_per_day
      cumulative_wordcount = 0 if cumulative_wordcount < 0
      data[date.strftime("%F")] = cumulative_wordcount
      date += 1
    end
    data
  end

  def full_burndown_data
    data = {}
    date = graph.date_started
    cumulative_wordcount = graph.wordcount
    data[(date - 1).strftime("%F")] = cumulative_wordcount
    while @graph.finish_date_object.mjd > date.mjd do
      cumulative_wordcount -= graph.wordcount_per_day
      cumulative_wordcount = 0 if cumulative_wordcount < 0
      data[date.strftime("%F")] = cumulative_wordcount
      date += 1
    end
    data[graph.finish_date] = 0
    data
  end

  def user_data
    date = graph.date_started - 1
    words_left_to_write = graph.wordcount
    data = {}
    (date..Date.today).each do |now|
      words_left_to_write -= graph.daily_wordcount[now.strftime("%F")] || 0
      data[now.strftime("%F")] = words_left_to_write
    end
    data
  end
end
