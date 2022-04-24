require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

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

get('/auction') do
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE Status = ?", "active")
    bid_results = db.execute("SELECT * FROM Bid")
    slim(:"auction/index", locals:{result:result})
end


get('/auction/bid') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"auction/bid", locals:{nft:result, user_result:user_result})
end

get('/inventory/:id/index') do
    id = params[:id].to_i
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE OwnerId = ? AND Status = ?", id, "inactive")
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"inventory/index",locals:{result:result, user_result:user_result}) 
end

get('/inventory/:id/new') do
    slim(:"auction/new")
end
post('/inventory/:id/new') do
    user_id = params[:id].to_i
    db = connect_db
    db.execute("INSERT INTO NFT (OwnerId, CreatorId, Name, Token, ) VALUES (?,?)", user_id, user_id, name, token)
    redirect('/auction')
end

get('/leaderboard') do
    slim(:"leaderboard/index")
end

post('/auction/:nft_id/bid') do 
    nft_id = params[:nft_id]
    redirect('/auction/bid')
end
post('/auction/:id/:nft_id/bid') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    bid_amount = params[:bid]
    user_bid(id, nft_id, bid_amount)
    redirect('/auction')
end
get('/inventory/sell') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    p result
    p user_result


    slim(:"inventory/sell",locals:{nft:result, user_result:user_result})
end
post('/inventory/:id/:nft_id/sell') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    redirect('/inventory/sell')
end


