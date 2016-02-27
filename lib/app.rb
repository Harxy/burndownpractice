$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'graph'
require 'user'
require 'sinatra'
require 'chartkick'
require 'time'
require 'strftime'
require 'authenticate'
require 'bcrypt'
require 'build_graph'

include Authenticate
set :static, true
set :public_folder, "#{File.dirname(__FILE__)}/public"

configure do
  Mongoid.load!("./mongoid.yml")
end

enable :sessions

get '/' do
  redirect to('/index')
end

get '/index' do
  authenticate!
  @graphs = Graph.where(user: session[:user_id].to_s)
  erb :index
end

get '/graph/:id' do
  authenticate!
  @graphs = Graph.where(user: session[:user_id].to_s)
  @graph = Graph.find(params[:id])
  graph_data = BuildGraph.new(graph: @graph)
  @data = graph_data.burndown_data
  @user_data = graph_data.user_data
  erb :graph
end

get '/signup' do
  erb :signup
end

post '/signup' do
  password_salt = BCrypt::Engine.generate_salt
  password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)
  user = User.create(
    email: params['email'],
    password: password_hash,
    username: params['username'],
    password_salt: password_salt
  )
  session[:user_id] = user._id
  session[:user_name] = user.username
  redirect to('/index')
end

get '/signin' do
  erb :signin
end

post '/signin' do
  user = User.find_by(username: params['username']) if User.find_by(username: params['username'])
  if user.password == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
    session[:user_id] = user._id
    session[:user_name] = user.username
  end
  redirect to('/index')
end

get "/signout" do
  session[:user_name] = nil
  session[:user_id] = nil
  redirect "/signin"
end

  post '/graph/:id' do
    authenticate!
    graph = Graph.find(params[:id])
    time = Date.today.strftime("%F")
    if graph.daily_wordcount[time]
      graph.daily_wordcount[time] += params['wordcount'].to_i
    else
      graph.daily_wordcount[time] = params['wordcount'].to_i
    end
    graph.save
    redirect to('/graph/' + graph.id)
  end

  get '/new' do
    authenticate!
    @graphs = Graph.where(user: session[:user_id].to_s)
    erb :new
  end

  post '/new' do
    authenticate!
    graph = Graph.create(
      user: session[:user_id],
      date_started: Date.today.strftime("%F"),
      name: params['name'],
      wordcount: params['wordcount'].to_i,
      days: params['days'].to_i,
      daily_wordcount: {}
    )
    redirect to('/graph/' + graph.id)
  end
