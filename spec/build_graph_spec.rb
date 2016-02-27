require 'build_graph'
require 'date'
require 'time'

RSpec.describe BuildGraph do
  date = Date.today
  let(:graph){ double(:graph,
                      "daily_wordcount" => {
    (date - 2).strftime("%F") => 50,
    (date - 1).strftime("%F") => 0,
    date.strftime("%F") => 250,
  },

  "date_started" => date - 2,
  "wordcount" => wordcount,
  "days" => days,
  "wordcount_per_day" => wordcount/days,
  "finish_date" => date.strftime("%F") )}

  let(:builder) { BuildGraph.new(graph: graph) }

  describe ".burndown_data" do
    context "no remainder" do
      let(:wordcount) { 300 }
      let(:days) { 3 }

      it 'builds the data for the burndown' do
        expect(builder.burndown_data).to include(
          (date -1).strftime("%F") => 100
        )
      end
    end

    context "with remainder" do
      let(:wordcount) { 271 }
      let(:days) { 3 }

      it 'does not leave a remainder' do
        expect(builder.burndown_data).to include(
          date.strftime("%F") => 0
        )
      end
    end

    describe ".user_data" do
      let(:wordcount) { 300 }
      let(:days) { 3 }
      it 'builds the data for the users graph' do
        expect(builder.user_data).to include(
          (date - 2).strftime("%F") => 250
        )
      end

      it 'includes days when no words were written' do
        expect(builder.user_data).to include(
          date.strftime("%F") => 0
        )
      end
    end
  end
end
