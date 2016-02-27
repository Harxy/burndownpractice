require "app"
require "rack/test"

RSpec.describe Sinatra::Application do
  include Rack::Test::Methods

  subject(:app) { Sinatra::Application }
  user = User.create(
    email: "test@test.com",
    password: 'hello',
  )
  graph = Graph.create(
    user: user,
    date_started: DateTime.now,
    name: "test",
    wordcount: 4000,
    days: 30,
    daily_wordcount: {}
  )
  it "/" do
    get "/index"
  end
end
