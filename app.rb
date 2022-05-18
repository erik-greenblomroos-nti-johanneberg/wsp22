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

#Kollar ifall användaren är inloggad
before('/inventory/:nft_id/update') do
    if session[:user_id] == nil
        redirect('/')
    end
end

#Kollar ifall användaren är inloggad
before('/inventory/new') do
    if session[:user_id] == nil
        redirect('/')
    end
end

#Kollar ifall användaren är inloggad
before('/inventory/:nft_id/delete') do
    if session[:user_id] == nil
        redirect('/')
    end
end

#Kollar ifall användaren är inloggad
before('/auction/bid/:nft_id') do
    if session[:user_id] == nil
        redirect('/')
    end
end
# kollar ifall personen är inloggad
before ('/login') do
    if session[:logging] != nil
        if Time.now - session[:logging] < 5
            redirect('/error/You_are_logging_in_too_fast._Please_wait_5_second_before_you_try_again.')
        end
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
# @see Model#get_active_nft
# @see Model#get_user
get('/auction') do
    db = connect_db
    id = session[:user_id]
    result = get_active_nft()
    user_result = get_user(id)
    slim(:"auction/index", locals:{result:result, user_result:user_result})
end

# Display bid baserat på nft_id
# Session[integer] Id
# @param [String] :id, Id av NFT 
# @see Model#get_nft
# @see Model#get_user
# @see Model#owner_name
get('/auction/bid/:nft_id') do
    id = session[:user_id]
    nft_id = params[:nft_id].to_i
    result = get_nft(nft_id)
    user_result = get_user(id)
    owner = owner_name(nft_id)
    slim(:"auction/bid", locals:{nft:result, user_result:user_result, owner:owner})
end

# Display Inventorypage
# @see Model#get_inactive_nft
# @see Model#get_user
get('/inventory') do
    id = session[:user_id].to_i
    result = get_inactive_nft(id)
    user_result = get_user(id)
    slim(:"inventory/index",locals:{result:result, user_result:user_result}) 
end

# Display Inventory/new page
get('/inventory/new') do
    slim(:"inventory/new")
end



# Display nft utifrån :nft_id
# @param [String] :id, Id av NFT
# @see Model#is_active
# @see Model#owner_id
# @see Model#get_nft
# @see Model#get_user
get('/inventory/:nft_id/update') do
    #Lägg till så att den kollar ifall användaren äger den
    id = session[:user_id].to_i
    nft_id = params[:nft_id].to_i
    if is_active(nft_id)
        redirect('/error/This_NFT_is_already_in_auction')
    end
    if id != owner_id(nft_id)
        redirect('/error/You_do_not_own_this_property')
    end

    result = get_nft(nft_id)
    user_result = get_user(id)
    slim(:"inventory/update",locals:{nft:result, user_result:user_result})
end

# Visar :error_msg på skärmen 
# @param [String] message, the error message
get('/error/:error_msg') do
    error_message = params[:error_msg].split("_").join(" ")
    slim(:"/error", locals:{error_message:error_message})
end

# Skapar ett nytt bid och redirectar till '/auction' eller '/error/:error_message'
# @param [String] :id, Id of the User
# @param [Integer] amount, The bid amount 
# @see Model#is_active
# @see Model#balance
# @see Model#user_owns_nft
# @see Model#min_bid
# @see Model#has_lead
# @see Model#id_of_lead
# @see Model#user_bid
post('/auction/:nft_id') do
    user_id = session[:user_id].to_i
    nft_id = params[:nft_id].to_i
    bid_amount = params[:bid].to_i
    if is_active(nft_id) == false
        redirect('/error/NFT_isnt_in_an_auction')
    end
    if bid_amount > balance(user_id)
        redirect('/error/Your_balance_is_too_low')
    end
    if user_owns_nft(user_id, nft_id)
        redirect('/error/You_cant_bid_at_your_own_NFT')
    end
    if bid_amount <= min_bid(nft_id)
        redirect('/error/Your_bid_was_too_low')
    end
    if has_lead(nft_id)
       current_lead = id_of_lead(nft_id)
       if current_lead == user_id
        redirect('/error/You_cant_bid_if_you_already_have_the_highest_bid')
       end
    end

    user_bid(user_id, nft_id, bid_amount)
    redirect('/auction')
end

# Updaterar NFT och redirectar till '/auktion'
# @param [String] :id, the ID of the NFT
# @param [Integer] amount, the startprice
# @param [Integer] deadline, Time till deadline
# @param [Integer] amount, the increment amount
# @see Model#user_sell
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
# @param [String] name, name of the NFT
# @param [String] route, The route of the picture 
# @param [String] token, the token of the NFT
# @param [String] amount, the increment amount
# @param [String] description, the description of the NFT
# @see Model#nft_name_exists
# @see Model#token_exists
# @see Model#url_exists
# @see Model#add_nft
post ('/inventory') do
user_id = session[:user_id]
name = params[:name]
url = params[:URL]
token = params[:token]
description = params[:description]
    if name.length < 3
        redirect('/error/The_name_of_the_NFT_must_be_atleast_3_characters_long')
    end
    if nft_name_exists(name)
        redirect('/error/That_NFT_name_already_exists')
    end
    if token_exists(token)
        redirect('/error/That_token_already_exists_..._How?')
    end
    if url_exists(url)
        redirect('/error/That_picture_route_already_exists')
    end
add_nft(name, url, token, user_id, description)
redirect('/inventory')
end


# Loggar in, redirectar till '/auction' eller '/error/:error_message'
# @param [String] username, user
# @param [String] password, pwd
# @see Model#check_user
# @see Model#pwd_match
# @see Model#login
post('/login') do
session[:logging] = Time.now
user = params[:user]
pwd = params[:pwd]
    if user == ""
        redirect('/error/Username_is_empty')   
    end
    if pwd == ""
        redirect('/error/Password_is_empty')   
    end
    if check_user(user).empty?
        redirect('/error/Wrong_password_or_username')   
    end
    if pwd_match(user, pwd) == false
        redirect('/error/Wrong_password_or_username')
    end
    if login(user, pwd)
        user_id = get_userid(user)
        session[:user_id] = user_id
        role = get_role(user)
        session[:role] = role
        redirect('/auction')
    else
        redirect('/error/Wrong_password_or_username')
    end

end

# Registerar använderen, redirecatar till '/auction' eller '/error/:error_message'
# @param [String] username, The name
# @param [String] password, The password
# @param [String] repeat-password, The repeated password
# @param [String] mail, The mail
# @see Model#user_exists
# @see Model#register
post('/register') do
user = params["user"]
if user.length < 3
    redirect('/error/Name_must_be_atleast_3_characters_long')
end
pwd = params["pwd"]
conf_pwd = params["conf_pwd"]
mail = params["mail"]

if mail == ""
    redirect('/error/Mail_is_empty')
end
if pwd.length < 8
    redirect('/error/Password_must_be_atleast_8_characters_long')
end
if user_exists(user)
    redirect('/error/There_is_already_a_user_named_that')
end
if pwd != conf_pwd
    redirect('/error/The_passwords_do_not_match')
end
register(user,pwd,conf_pwd,mail)
redirect('/login')
end

# Ändrar Session[:user_id] till nil och redirecter till '/'
post("/logout") do
session[:user_id] = nil
redirect('/')
end

# Tar bort nft, redirectar till '/auction'
# @param [integer] :id, Id of the NFT
# @see Model#remove
post("/auction/:nft_id/delete") do
nft_id = params[:nft_id]
remove(nft_id)
redirect('/auction')
end