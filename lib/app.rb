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

get '/graph/:id/finished' do
  setup!
  @graph = Graph.find(params[:id])
  erb :finished
end

post '/graph/:id/finished' do
  setup!
  @graph = Graph.find(params[:id])
  case params[:option]
  when 'push_date'
    days_updated = Date.today.mjd - @graph.finish_date_object.mjd + 3
    @graph.update_attributes(:days => days_updated)
    redirect to('/index')
  when 'complete'
    mark_completed(@graph)
    redirect to('/index')
  end
end

def mark_completed(graph)
  graph.update_attributes(:completed => true)
end

get '/graph/:id' do
  setup!
  @graph = Graph.find(params[:id])
  if @graph.finish_date_object.mjd < Date.today.mjd
    redirect to("/graph/#{params[:id]}/finished")
  end
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
  if params['adjust_wordcount']
    wordcount = params['adjust_wordcount'].to_i - graph.cumulative
    add_wordcount(wordcount, time, graph, user)
  else
    add_wordcount(params['wordcount'].to_i, time, graph, user)
  end
  graph.save
  user.save
  redirect to('/graph/' + graph.id)
end

def add_wordcount(wordcount, time, graph, user)
  if (graph.daily_wordcount[time] && wordcount)
    graph.daily_wordcount[time] += wordcount.to_i
    user.wordcount_badge += wordcount.to_i
  else
    graph.daily_wordcount[time] = wordcount.to_i
    user.wordcount_badge += wordcount.to_i
  end
end

post '/complete/:id' do
  setup!
  graph = Graph.find_by(:_id => params[:id])
  mark_completed(graph)
  redirect to('/index')
end

post '/delete/:id' do
  setup!
  Graph.any_in(:_id => [params[:id]]).destroy_all
  redirect to('/index')
end

get '/new' do
  setup!
  erb :new
end

get '/about' do
  @user = current_user
  @graphs = Graph.where(user: session[:user_id].to_s)
  erb :about
end

get '/contact' do
  @user = current_user
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
