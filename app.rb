require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do 
slim(:login)
end

get('/auction') do
slim(:auction)
end
