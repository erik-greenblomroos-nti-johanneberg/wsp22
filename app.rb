require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

include Model

#Kollar ifall användaren är inloggad
before('/inventory') do
    if session[:user_id] == nil
        redirect('/')
    end
end
#Kollar ifall användaren är inloggad
before('/auction') do
    if session[:user_id] == nil
        redirect('/')
    end
end
#Display Landingpage
get('/') do 
slim(:home)
end
#Display Loginpage
get('/login') do
slim(:login)
end
#Registerpage
get('/register') do
slim(:register)
end

# Display Auctionpage
# Hjälpfunktion Kopplar med databasen
# Hämtar allt från Bid
# Session[integer] Id
# Hämtar allt från User där Id = Id, tar första som matchar

get('/auction') do
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE Status = ?", "active")
    bid_results = db.execute("SELECT * FROM Bid")
    id = session[:user_id]
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"auction/index", locals:{result:result, user_result:user_result})
end

# Display bid baserat på nft_id
# Session[integer] Id
# Params[String] to integer NFT_Id
# Hämtar allt från NFT där NFT_Id = NFT_Id
# Hämtar allt från User där Id = Id

get('/auction/bid/:nft_id') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"auction/bid", locals:{nft:result, user_result:user_result})
end

# Display Inventorypage
# Session[integer] Id
# Hjälpfunktion Kopplar med databasen
# Hämtar allt från User där UserId = Id, tar första som matchar
# Hämtar allt från User där Id = id
get('/inventory') do
    id = session[:user_id].to_i
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE OwnerId = ? AND Status = ?", id, "inactive")
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"inventory/index",locals:{result:result, user_result:user_result}) 
end

# Display Inventorypage
get('/inventory/new') do
    slim(:"inventory/new")
end

# Params[String] to integer, användarens id
# Kopplar till databasen
# Lägger till ny NFT ägaren tilldelas till användarens id
#
post('/inventory/:id/new') do
    user_id = params[:id].to_i
    db = connect_db
    db.execute("INSERT INTO NFT (OwnerId, CreatorId, Name, Token, ) VALUES (?,?)", user_id, user_id, name, token)
    redirect('/auction')
end

# get('/leaderboard') do
#     slim(:"leaderboard/index")
# end

# Display nft utifrån nft_id
# Kollar ifall den ska vara på auktion sidan eller inte
#
get('/inventory/sell/:nft_id') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    if is_in_auction(nft_id) == false 
    db = connect_db
    result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
    user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
    slim(:"inventory/sell",locals:{nft:result, user_result:user_result})
    else
        redirect('/error/NFT_is_already_in_auction')
    #ERROR
    end
end
# Display Inventory/new
get('/inventory/new') do
    slim(:"inventory/new")
end

get('/error/:error_msg') do
    error_message = params[:error_msg].split("_").join(" ")
    slim(:"/error", locals:{error_message:error_message})
end

# Skapar ett nytt bid och redirectar till '/auktion'
# Session[integer] Id
# Params[String] to integer, NFT_Id
# Params[Integer], Bidamount
post('/auction/:id/:nft_id/bid') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    bid_amount = params[:bid]
    user_bid(id, nft_id, bid_amount)
    redirect('/auction')
end

# Updaterar NFT och redirectar till '/auktion'
# Session[integer] Id
# Params[String] to integer, NFT_Id
# Params[Integer], startprice
# Params[Integer], deadline
# Params[Integer], increment
post('/inventory/:id/:nft_id/sell') do 
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    startprice = params[:startprice]
    deadline = params[:deadline]
    increment = params[:increment]
    user_sell(id, nft_id, startprice, deadline, increment)
    redirect('/auction')

end


# Skapar NFT och redirectar till '/inventory'
# Session[integer], user_id
# Params[String], name
# Params[String], URL
# Params[String], token
# Params[String], description

post ('/inventory/new') do
user_id = session[:user_id]
name = params[:name]
url = params[:URL]
token = params[:token]
description = params[:description]
add_nft(name, url, token, user_id, description)
redirect('/inventory')
end

# Se model.rb

post('/login') do
user = params[:user]
pwd = params[:pwd]
login(user, pwd)
end

# Skickar iväga data till hjälpdunktionen register() och redirecatar till '/auction'
# Params[String], user
# Params[String], pwd
# Params[String], cond_pwd
# Params[String], mail
post('/register') do
user = params["user"]
pwd = params["pwd"]
conf_pwd = params["conf_pwd"]
mail = params["mail"]
register(user,pwd,conf_pwd,mail)
redirect('/login')
end

# Ändrar Session[:user_id] till nil och redirecter till '/'

post("/logout") do
session[:user_id] = nil
redirect('/')
end

post("/auction/remove/:nft_id")
#måste ha admin behörighet
nft_id = params[:nft_id]
deactivate_nft(nft_id)

end