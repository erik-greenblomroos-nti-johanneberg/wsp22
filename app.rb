require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do 
slim(:login)
end

get('/auction') do
    # db = SQLite3::Database.new("db/database.db")
    # db.results_as_hash = true
    # result = db.execute("SELECT * FROM NFT")
    # p result
    # slim(:"auction/index",locals:{NFT:result})
    redirect('/auction/index')
end

get('/auction/index') do
    slim(:"auction/index")
end


