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
    id = session[:user_id]
    result = get_active_nft()
    user_result = get_user(id)
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
    result = get_nft(nft_id)
    user_result = get_user(id)
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
    result = get_inactive_nft(id)
    user_result = get_user(id)
    slim(:"inventory/index",locals:{result:result, user_result:user_result}) 
end

# Display Inventory/new page
get('/inventory/new') do
    slim(:"inventory/new")
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
    result = get_nft(nft_id)
    user_result = get_user(id)
    slim(:"inventory/sell",locals:{nft:result, user_result:user_result})
    else
        redirect('/error/NFT_is_already_in_auction')
    #ERROR
    end
end

get('/error/:error_msg') do
    error_message = params[:error_msg].split("_").join(" ")
    slim(:"/error", locals:{error_message:error_message})
end

# Skapar ett nytt bid och redirectar till '/auction'
# Session[integer] Id
# Params[String] to integer, NFT_Id
# Params[Integer], Bidamount
post('/auction/:nft_id') do
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
post('/inventory/:nft_id/update') do 
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

post ('/inventory') do
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

post("/auction/:nft_id/delete") do
#måste ha admin behörighet
nft_id = params[:nft_id]
remove(nft_id)
redirect('/auction')
end