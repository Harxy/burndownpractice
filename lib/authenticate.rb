module Authenticate
  def authenticate!
    unless session[:user_id]
      session[:original_request] = request.path_info
      redirect '/signin'
    end
  end
end
