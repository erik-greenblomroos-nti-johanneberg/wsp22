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


get('/inventory/owned') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM NFT")
    slim(:"inventory/owned",locals:{NFT:result}) #Byt ut till redirect('/inventory/:id/owned') för att få personligt storage
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



