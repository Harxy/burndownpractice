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
set :public_folder, "public"

configure do
  Mongoid.load!("./mongoid.yml")
end

enable :sessions

def setup!
  authenticate!
  @graphs = Graph.where(user: session[:user_id].to_s)
  @user = current_user
end

get '/' do
  setup!
  redirect to('/index')
end

get '/index' do
  setup!
  erb :index
end

get '/graph/:id' do
  setup!
  @graphs = Graph.where(user: session[:user_id].to_s)
  @graph = Graph.find(params[:id])
  graph_data = BuildGraph.new(graph: @graph)
  @data = graph_data.burndown_data
  @user_data = graph_data.user_data
  @full_data = graph_data.full_burndown_data
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
    password_salt: password_salt,
    wordcount_badge: 0
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
  if user
    if user.password == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
      session[:user_id] = user._id
      session[:user_name] = user.username
    end
  end
  redirect to('/index')
end

get "/signout" do
  session[:user_name] = nil
  session[:user_id] = nil
  redirect "/signin"
end

post '/graph/:id' do
  setup!
  user = current_user
  graph = Graph.find(params[:id])
  time = Date.today.strftime("%F")

  if (graph.daily_wordcount[time] && params['wordcount'])
    graph.daily_wordcount[time] += params['wordcount'].to_i
    user.wordcount_badge += params['wordcount'].to_i
  else
    graph.daily_wordcount[time] = params['wordcount'].to_i
    user.wordcount_badge += params['wordcount'].to_i
  end

  if (graph.daily_wordcount[time] && params['adjust_wordcount'])
    tmp = params['adjust_wordcount'].to_i - graph.cumulative
    if graph.daily_wordcount[time]
      graph.daily_wordcount[time] += tmp
      user.wordcount_badge += tmp
    else
      graph.daily_wordcount[time] = tmp
      user.wordcount_badge += tmp
    end
  end
  graph.save
  user.save
  redirect to('/graph/' + graph.id)
end

post '/delete/:id' do
  setup!
  Graph.any_in(:_id => [params[:id]]).destroy_all
  redirect to('/index')
end

get '/new' do
  setup!
  @graphs = Graph.where(user: session[:user_id].to_s)
  erb :new
end

get '/about' do
  @graphs = Graph.where(user: session[:user_id].to_s)
  erb :about
end

get '/contact' do
  @graphs = Graph.where(user: session[:user_id].to_s)
  erb :contact
end

post '/new' do
  setup!
  if params['wordcount'].to_i > params['days'].to_i
    graph = Graph.create(
      user: session[:user_id],
      desc: params['desc'],
      date_started: Date.today.strftime("%F"),
      name: params['name'],
      wordcount: params['wordcount'].to_i,
      days: params['days'].to_i,
      daily_wordcount: {}
    )
    redirect to('/graph/' + graph.id)
  end
  redirect to('/new')
end

def current_user
  User.find_by(_id: session[:user_id])
end
