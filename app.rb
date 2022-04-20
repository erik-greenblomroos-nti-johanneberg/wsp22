require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do 
session[:user_id] = "1"
slim(:home)
end

get('/login') do
slim(:login)
end

get('/register') do
slim(:register)
end


# get('/auction') do
#     # db = SQLite3::Database.new("db/database.db")
#     # db.results_as_hash = true
#     # result = db.execute("SELECT * FROM NFT")
#     # p result
#     # slim(:"auction/index",locals:{NFT:result})
#     redirect('/auction/index')
# end
get('/auction') do
    db = SQLite3::Database.new("db/database.db") 
    db.results_as_hash = true
    result = db.execute("SELECT * FROM NFT WHERE Status = ?", "active")
    slim(:"auction/index", locals:{result:result})
end


get('/auction/:nft_id/bid') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    db = SQLite3::Database.new("db/database.db") 
    db.results_as_hash = true
    result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"auction/bid", locals:{nft:result, user_result:user_result})
end

get('/inventory/:id/index') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/database.db") 
    db.results_as_hash = true
    result = db.execute("SELECT * FROM NFT WHERE OwnerId = ? AND Status = ?", id, "inactive")
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"inventory/index",locals:{result:result, user_result:user_result}) 
end

get('/inventory/:id/new') do
    slim(:"auction/new")
end
post('/inventory/:id/new') do
    user_id = params[:id].to_i
    db = SQLite3::Database.new("db/database.db")
    db.execute("INSERT INTO NFT (OwnerId, CreatorId, Name, Token, ) VALUES (?,?)", user_id, user_id, name, token)
    redirect('/auction')
end

get('/leaderboard') do
    slim(:"leaderboard/index")
end

post('/auction/:id/:nft_id/bid') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    db = SQLite3::Database.new("db/database.db") 
    db.results_as_hash = true

    # result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
    # user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first


    redirect('/auction')
end


