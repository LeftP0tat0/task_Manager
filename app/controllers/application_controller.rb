require './config/environment'

class ApplicationController < Sinatra::Base

  #set up Config

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    enable :sessions
    set :session_secret, "password_security"
  end

  #set @user to curent user
  #go to index

  get '/' do
    @user = current_user if is_logged_in?
    erb :index
  end

  #signup  page
  #check to make sure user is not logged in

  get '/signup' do
    if is_logged_in?
      redirect '/tasks'
    else
      erb :'/users/signup'
    end
  end

  post '/signup' do
    user = User.new(:username => params[:username], :email => params[:email], :password => params[:password])
    if user.save && user.username != "" && user.email != ""
      session[:user_id] = user.id
      redirect to "/tasks"
    else
      redirect '/signup'
    end
    redirect to "/tasks"
  end

  #login page 
  #check if user is logged in

  get '/login' do
    if is_logged_in?
      redirect '/tasks'
    else
      erb :'/users/login'
    end
  end

  post '/login' do
    user = User.find_by(:username => params[:username])

    if user && user.authenticate(params[:password])
      session[:user_id] = user.id
    end
    redirect '/tasks'
  end

  get "/users/:slug" do
    @user = User.find_by_slug(params[:slug])
    erb :'/users/show'
  end
   

  get '/logout' do
    session.clear
    redirect "/login"
  end

  #tasks

  post '/task' do
    if !params[:content].empty?
      task = Task.create(:content => params[:content])
      current_user.tasks << task
      current_user.save
      redirect '/tasks'
    else
      redirect to '/tasks/new'
    end
  end

  get '/tasks' do
    if is_logged_in?
      @user = current_user
      @tasks = Task.all
      erb :"/users/show"
    else
      redirect '/login'
    end
  end

  #tasks new

  get '/tasks/new' do
    if is_logged_in?
      @user = current_user
      erb :'/tasks/create_task'
    else
      redirect to '/login'
    end
  end

  get '/tasks/:id' do
    if is_logged_in?
      @user = current_user
      @task = Task.find_by_id(params[:id])
      erb :'/tasks/show_task'
    else
      redirect to '/login'
    end
  end

  #tasks edit

  get '/tasks/:id/edit' do
    @task = Task.find_by_id(params[:id])
    if is_logged_in? && @task.user == current_user
      erb :'/tasks/edit_task'
    else
      redirect 'login'
    end
  end

  patch '/tasks/:id' do
    @task = Task.find_by_id(params[:id])
    if params[:delete] == "on"
      redirect to "/tasks/#{params[:id]}/delete"
    else
      if params[:task_completed] == "on"
        @task.update(:status => "done")
        @task.save
      else
      @task.update(:status => "notdone")
      @task.save
      end
      if !params[:content].empty?
        @task.update(:content => params[:content])
        @task.save
        redirect 'login'
      else
        redirect 'login'
      end
    end

  end

  #tasks delete

  get '/tasks/:id/delete' do
    @task = Task.find_by_id(params[:id])
    if current_user == @task.user
      @task.delete
      redirect to '/tasks'
    else
      redirect to "/tasks/#{params[:id]}"
    end
  end


  #helpers 

  helpers do
    def current_user
      User.find(session[:user_id])
    end

    def is_logged_in?
      !!session[:user_id]
    end

  end

end
