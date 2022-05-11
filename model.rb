module Model

    # Kopplar till databasen och returnerar db
    def connect_db
        db = SQLite3::Database.new("db/database.db") 
        db.results_as_hash = true
        return db
    end
    # Kollar ifall en nft redan finns i auktionen, returnerar false eller true
    def is_in_auction(nft_id)
        db = connect_db
        status = db.execute("SELECT Status FROM NFT WHERE Id = ?", nft_id).first["Status"]      
            if status == "inactive"
                return false
            else
                return true
            end
        end

    # Ändrar User's Balance och genom att subtrahera deras bidamount
    def take_money(user_id, bidamount)
    db = connect_db
    balance = db.execute("SELECT Balance FROM User WHERE Id = ?", user_id.to_i).first["Balance"]
    new_balance = balance.to_i - bidamount.to_i
    db.execute("UPDATE User SET Balance = ? WHERE Id = ?", new_balance, user_id.to_i)
    end
    # Ändrar User's Balance och genom att adderas deras tidigare bidamount
    def give_money(user_id, bidamount)
        db = connect_db
        balance = db.execute("SELECT Balance FROM User WHERE Id = ?", user_id.to_i).first["Balance"]
        new_balance = balance.to_i + bidamount.to_i
        db.execute("UPDATE User SET Balance = ? WHERE Id = ?", new_balance, user_id.to_i)
    end
    # Skapar ett Bid för en NFT
    # Kollar ifall nft är "active" om inte, error
    # Kollar ifall user's balance är högre eller lika med detas bid, annars error
    # Kollar ifall users's bid är högre än tidigare bid:et
    # Kollar ifall user äger NFT'n , annars Error
    # Kollar ifall user redan har högsta bid'et, annars error
    #
    def user_bid(user_id, nft_id, bid_amount)
        db = connect_db
        if is_in_auction(nft_id) == true
        bid_amount = bid_amount.to_i
        min_bid = db.execute("SELECT Startprice FROM NFT WHERE Id = ?", nft_id).first["Startprice"]
        current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last
        owner = db.execute("SELECT OwnerId FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
        balance = db.execute("SELECT Balance FROM User WHERE Id = ?", user_id.to_i).first["Balance"]
            if bid_amount <= balance
                if bid_amount > min_bid 
                    if user_id.to_i != owner
                        if current_lead == nil
                            current_time = Time.now.to_s
                            db.execute("INSERT INTO Bid (Bidamount, Bidtime, Userid, NFTid) VALUES(?,?,?,?)",bid_amount, current_time,user_id,nft_id)
                            db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?",bid_amount, nft_id)
                            take_money(user_id, bid_amount)
                        else
                            current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
                            if user_id.to_i != current_lead
                                current_time = Time.now.to_s
                                give_money(current_lead, min_bid)
                                db.execute("INSERT INTO Bid (Bidamount, Bidtime, Userid, NFTid) VALUES(?,?,?,?)",bid_amount, current_time,user_id,nft_id)
                                db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?",bid_amount, nft_id)
                                take_money(user_id, bid_amount)
                            else
                                #ERROR
                                redirect('/error/You_cant_bid_if_you_already_have_the_highest_bid')
                            end

                        end
                        new_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
                        latest_bid = db.execute("SELECT Id FROM Bid WHERE UserId = ?", new_lead).last["Id"]
                        db.execute("INSERT INTO user_bid_relation (UserId, BidId) VALUES(?,?)",new_lead, latest_bid)
                    else
                        # ERROR -
                        redirect('/error/You_cant_bid_at_your_own_NFT')
                    end
                else
                    # ERROR
                    redirect('/error/Your_bid_was_too_low')
                end
            else
                #ERROR
                redirect('/error/Your_balance_is_too_low')
            end
        else 
        #ERROR
        redirect('/error/NFT_isnt_in_an_auction')
        end

    end


    # def create_deadline(deadline)
    #     current_time = Time.now
    # end


    #hinner inte mer
    def user_sell(user_id, nft_id, startprice, deadline, increment)
    db = connect_db
    user_id = session[:user_id].to_i
    status = db.execute("SELECT Status FROM NFT WHERE Id = ?", nft_id).first["Status"]
    owner = db.execute("SELECT OwnerId FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
    p startprice
    if status == "inactive"
        if user_id == owner
            db.execute("UPDATE NFT SET Startprice = ?, Increment = ?, Status = ?, Deadline = ? WHERE Id =?", startprice.to_i, increment, "active", deadline, nft_id)
        else
            #ERROR
            redirect('/error/You_do_now_own_this_property')
           
        end
    else
        #ERROR
        redirect('/error/This_NFT_is_already_in_auction')
    end
    end

    def remove_bids(nft_id)

    end

    def add_nft(name, url, token, user_id, description)
        db = connect_db
        db.execute("INSERT INTO NFT (OwnerId, CreatorId, Name, Status, Token, Description, Currentvalue, URL) VALUES(?,?,?,?,?,?,?,?)",user_id, user_id,name,"inactive",token,description,0,url)
    end

    def register(user,pwd,conf_pwd, mail)
    db = connect_db
    result = db.execute("SELECT Id FROM User WHERE Name=?", user)
    if result.empty?
        if pwd == conf_pwd
            pwd_digest = BCrypt::Password.create(pwd)
            db.execute("INSERT INTO User(Name, Password, Mail, Status, Role, Balance) VALUES(?,?,?,?,?,?)",user, pwd_digest, mail,"active", 0, 0)
            user_id = db.execute("SELECT Id FROM User WHERE Name=?", user)
            session[:user_id] = user_id
        else
            #ERROR
            redirect('/error/The_passwords_do_not_match')
        end
    else
        redirect('/login')
        redirect('/error/There_is_already_a_user_named_that')
    end
    end

    def login(user, pwd)
    db = connect_db
    result = db.execute("SELECT Id,Password FROM User WHERE Name=?", user)
        if result.empty?
            #ERROR
            redirect('/error/Wrong_password_or_username')
        end
    user_id = result.first["Id"]
    pwd_digest = result.first["Password"]
        if BCrypt::Password.new(pwd_digest) == pwd
                session[:role] = db.execute("SELECT Role FROM User WHERE Id = ?", user_id).first["Role"]
                session[:user_id] = user_id
                redirect('/auction')
        else
            #ERROR
            redirect('/error/Wrong_password_or_username')
        end
    end
end

def delete_relation(nft_id)
    db = connect_db
    db.results_as_hash = false
    bidlist = db.execute("SELECT Id FROM Bid WHERE NFTid = ?", nft_id).to_a
    i = 0
    p bidlist
    p bidlist.length
    while i < bidlist[0].length
        db.execute("DELETE user_bid_relation WHERE BidId = ?", bidlist[i][0])
        i += 1
    end

end

def deactivate_nft(nft_id)
db = connect_db
#deavitvate
db.execute("UPDATE NFT SET Status = ? WHERE Id = ?","inactive", nft_id )
current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last
if current_lead != nil
    current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
    min_bid = db.execute("SELECT Startprice FROM NFT WHERE Id = ?", nft_id).first["Startprice"]
    give_money(current_lead, min_bid)
end
delete_relation(nft_id)
end

