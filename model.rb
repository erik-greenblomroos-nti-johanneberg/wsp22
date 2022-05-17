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


    def balance(user_id)
        db = connect_db
        balance = db.execute("SELECT Balance FROM User WHERE Id = ?", user_id.to_i).first["Balance"]
        return balance
    end

    def user_owns_nft(user_id, nft_id)
        db = connect_db
        owner = db.execute("SELECT OwnerId FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
        if user_id.to_i == owner
            return true
        else
            return false
        end
    end

    def min_bid(nft_id)
        db = connect_db
        min_bid = db.execute("SELECT Startprice FROM NFT WHERE Id = ?", nft_id).first["Startprice"]
        return min_bid
    end

    def is_a_lead(nft_id)
        db = connect_db
        lead_id = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last
        if lead_id == nil
            return false
        else
            return true
        end
    end
    
    def id_of_lead(nft_id)
        db = connect_db
        lead_id = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
        return lead_id
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
        #Kan lägga till så att owner och min_bid hämtas samtidigt
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
                            end
                        end
                        new_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
                        latest_bid = db.execute("SELECT Id FROM Bid WHERE UserId = ?", new_lead).last["Id"]
                        db.execute("INSERT INTO user_bid_relation (UserId, BidId) VALUES(?,?)",new_lead, latest_bid)
                    else
                        # ERROR -
                    end
                else
                    # ERROR
                end
            else
                #ERROR
            end
        else 
        #ERROR
        end

    end
    def owner_id(nft_id)
        db = connect_db
        owner_id = db.execute("SELECT Status,Id FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
        return owner_id
    end

    def is_active(nft_id)
        db = connect_db
        status = db.execute("SELECT Status FROM NFT WHERE Id = ?", nft_id).first["Status"]
        if status == "active"
            return true
        else
            return false
        end
    end
    # def create_deadline(deadline)
    #     current_time = Time.now
    # end


    #hinner inte mer
    def user_sell(user_id, nft_id, startprice, deadline, increment)
        db = connect_db
        db.execute("UPDATE NFT SET Startprice = ?, Increment = ?, Status = ?, Deadline = ? WHERE Id =?", startprice.to_i, increment, "active", deadline, nft_id)   
    end

    def add_nft(name, url, token, user_id, description)
        db = connect_db
        db.execute("INSERT INTO NFT (OwnerId, CreatorId, Name, Status, Token, Description, Currentvalue, URL) VALUES(?,?,?,?,?,?,?,?)",user_id, user_id,name,"inactive",token,description,0,url)
    end

    def user_exists(user)
        db = connect_db
        result = db.execute("SELECT Id FROM User WHERE Name=?", user)
        if result.empty?
            return false
        else
            return true
        end
    end


    def register(user,pwd,conf_pwd, mail)
    db = connect_db
    result = db.execute("SELECT Id FROM User WHERE Name=?", user)
    if result.empty?
        if pwd == conf_pwd
            pwd_digest = BCrypt::Password.create(pwd)
            db.execute("INSERT INTO User(Name, Password, Mail, Status, Role, Balance) VALUES(?,?,?,?,?,?)",user, pwd_digest, mail,"active", 0, 0)
            user_id = db.execute("SELECT Id FROM User WHERE Name=?", user)
        else
            #ERROR
        end
    else
        #ERROR
    end
    end

    def get_userid(user)
        db = connect_db
        result = db.execute("SELECT Id FROM User WHERE Name=?", user).first["Id"]
        return result
    end

    def check_user(user)
        db = connect_db
        result = db.execute("SELECT Id,Password FROM User WHERE Name=?", user)
        return result
    end

    def pwd_match(user, pwd)
        db = connect_db
        pwd_digest = db.execute("SELECT Password FROM User WHERE Name=?", user).first["Password"]
        if BCrypt::Password.new(pwd_digest) == pwd
            return true
        else
            return false
        end
    end

    def get_role(user)
        db = connect_db
        role = db.execute("SELECT Role FROM User WHERE Name=?", user).first["Role"]
        return role
    end

    def login(user, pwd)
    db = connect_db
    result = db.execute("SELECT Id,Password FROM User WHERE Name=?", user)
    user_id = result.first["Id"]
    pwd_digest = result.first["Password"]
        if BCrypt::Password.new(pwd_digest) == pwd
            return true
        else
            #ERROR
        end
    end


    def delete_relation(nft_id)
        db = connect_db
        db.results_as_hash = false
        bidlist = db.execute("SELECT Id FROM Bid WHERE NFTid = ?", nft_id).to_a
        i = 0
        while i < bidlist.length
            num = bidlist[i][0]
            db.execute("DELETE FROM user_bid_relation WHERE BidId = ?", num)
            i = i + 1
        end
        db.execute("DELETE FROM Bid WHERE NFTid = ?", nft_id)
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

    def remove(nft_id)
        db = connect_db
        deactivate_nft(nft_id)
        current_value = db.execute("SELECT Currentvalue FROM NFT WHERE Id = ?", nft_id).first["Currentvalue"]
        p current_value
        db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?", current_value, nft_id)

    end

    def get_nft(nft_id) 
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
        return result
    end
    def get_user(id)
        db = connect_db
        user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
        return user_result
    end

    def get_inactive_nft(id)
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE OwnerId = ? AND Status = ?", id, "inactive")
        return result
    end
    def get_active_nft()
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE Status = ?", "active")
        return result
    end
end