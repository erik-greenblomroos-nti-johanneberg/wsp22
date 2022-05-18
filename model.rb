module Model

    # Kopplar till databasen och returnerar db
    def connect_db
        db = SQLite3::Database.new("db/database.db") 
        db.results_as_hash = true
        return db
    end

    # Ändrar User's Balance
    # @param [Integer] user_id användarens id
    # @param [Integer] bid_amount storhet på bud
    def take_money(user_id, bidamount)
        db = connect_db
        balance = db.execute("SELECT Balance FROM User WHERE Id = ?", user_id).first["Balance"]
        new_balance = balance.to_i - bidamount.to_i
        db.execute("UPDATE User SET Balance = ? WHERE Id = ?", new_balance, user_id)
    end
    # Ändrar User's Balance
    # @param [Integer] user_id användarens id
    # @param [Integer] bid_amount storhet på bud
    def give_money(user_id, bidamount)
        db = connect_db
        p user_id
        balance = balance(user_id)
        new_balance = balance.to_i + bidamount.to_i
        db.execute("UPDATE User SET Balance = ? WHERE Id = ?", new_balance, user_id)
    end

    # Hämtar User's Balance
    # @param [Integer] user_id användarens id
    # @return [Integer] the balance of the user
    def balance(user_id)
        db = connect_db
        balance = db.execute("SELECT Balance FROM User WHERE Id = ?", user_id.to_i).first["Balance"]
        return balance
    end

    # Returnerar true eller false ifall user_id äger NFT
    # @param [Integer] user_id användarens id
    # @param [Integer] nft_id Id till NFT
    # @return [true] if user owns NFT
    # @return [false] if user owns NFT
    def user_owns_nft(user_id, nft_id)
        db = connect_db
        owner = db.execute("SELECT OwnerId FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
        if user_id.to_i == owner
            return true
        else
            return false
        end
    end

    
    # returnerar min_bud från NFT
    # @param [Integer] nft_id Id till NFT
    # @return [Integer] the minimum bid
    def min_bid(nft_id)
        db = connect_db
        min_bid = db.execute("SELECT Startprice FROM NFT WHERE Id = ?", nft_id).first["Startprice"]
        return min_bid
    end

    # kollar ifall det finns det finns Bids till NFT
    # @param [Integer] nft_id Id till NFT
    # @return [true] om det finns bud på NFT
    # @return [false] om det inte finns bud på NFT
    def has_lead(nft_id)
        db = connect_db
        lead_id = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last
        if lead_id == nil
            return false
        else
            return true
        end
    end

    # Hitta Id på User som skapade senaste Bid på NFT 
    # @param [Integer] nft_id Id till NFT
    # @return [Integer] Id till senaste budgivare till NFT
    def id_of_lead(nft_id)
        db = connect_db
        lead_id = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
        return lead_id
    end

    # Skapar ett Bid för en NFT
    # @param [Integer] user_id Id till User
    # @param [Integer] nft_id Id till NFT
    # @param [Integer] bid_amount storhet på bud
    def user_bid(user_id, nft_id, bid_amount)
        db = connect_db
        current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last
        min_bid = min_bid(nft_id)
        if current_lead == nil
            current_time = Time.now.to_s
            db.execute("INSERT INTO Bid (Bidamount, Bidtime, Userid, NFTid) VALUES(?,?,?,?)",bid_amount, current_time,user_id,nft_id)
            db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?",bid_amount, nft_id)
            take_money(user_id, bid_amount)
        else
                current_lead = current_lead["Userid"]
                current_time = Time.now.to_s
                give_money(current_lead, min_bid)
                db.execute("INSERT INTO Bid (Bidamount, Bidtime, Userid, NFTid) VALUES(?,?,?,?)",bid_amount, current_time,user_id,nft_id)
                db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?",bid_amount, nft_id)
                take_money(user_id, bid_amount)
        
        end
        new_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
        latest_bid = db.execute("SELECT Id FROM Bid WHERE UserId = ?", new_lead).last["Id"]
        db.execute("INSERT INTO user_bid_relation (UserId, BidId) VALUES(?,?)",new_lead, latest_bid)
    end

    # Hitta Id till ägare av NFT
    # @param [Integer] nft_id Id till NFT
    # @return [Integer] Id til ägare av NFT
    def owner_id(nft_id)
        db = connect_db
        owner_id = db.execute("SELECT OwnerId FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
        return owner_id
    end

    # Kollar ifall nft är tilldelad "active" i attributen Status
    # @param [Integer] nft_id Id till NFT
    # @return [true] om attributen Status är "active"
    # @return [false] om attributen Status inte är "active"
    def is_active(nft_id)
        db = connect_db
        status = db.execute("SELECT Status FROM NFT WHERE Id = ?", nft_id).first["Status"]
        if status == "active"
            return true
        else
            return false
        end
    end

   
    # Lägger upp NFT på auction
    # @param [Integer] user_id Id till User
    # @param [Integer] nft_id Id till NFT
    # @param [Integer] startprice priset på NFT
    # @param [String] deadline Tiden tills deadline
    # @param [Integer] increment minimum inkrementering på bud
    def user_sell(user_id, nft_id, startprice, deadline, increment)
        db = connect_db
        db.execute("UPDATE NFT SET Startprice = ?, Increment = ?, Status = ?, Deadline = ? WHERE Id =?", startprice.to_i, increment, "active", deadline, nft_id)   
    end

    # Lägger till NFT
    # @param [String] name namn på NFT
    # @param [String] url routen till bilden
    # @param [String] tokent token till NFT
    # @param [Integer] user_id Id till User
    # @param [String] description förklaring av NFT
    def add_nft(name, url, token, user_id, description)
        db = connect_db
        db.execute("INSERT INTO NFT (OwnerId, CreatorId, Name, Status, Token, Description, Currentvalue, URL) VALUES(?,?,?,?,?,?,?,?)",user_id, user_id,name,"inactive",token,description,0,url)
    end

    # Kollar ifall user finns
    # @param [String] user namn på user
    # @return [true] om usern finns
    # @return [false] om usern inte finns
    def user_exists(user)
        db = connect_db
        result = db.execute("SELECT Id FROM User WHERE Name=?", user)
        if result.empty?
            return false
        else
            return true
        end
    end

    # Skapar användare
    # @param [String] user namn på user
    # @param [String] pwd lösenord
    # @param [String] conf_pwd repeat-lösenord
    # @param [String] mail mail från user
    def register(user,pwd,conf_pwd, mail)
    db = connect_db
    result = db.execute("SELECT Id FROM User WHERE Name=?", user)
            pwd_digest = BCrypt::Password.create(pwd)
            db.execute("INSERT INTO User(Name, Password, Mail, Status, Role, Balance) VALUES(?,?,?,?,?,?)",user, pwd_digest, mail,"active", 0, 0)
    end

    # returnerar Id från User
    # @param [String] user namn på user
    # @return [Integer] Id til användare
    def get_userid(user)
        db = connect_db
        result = db.execute("SELECT Id FROM User WHERE Name=?", user).first["Id"]
        return result
    end

    # returnerar Id och Password från User med Name user
    # @param [String] user namn på user
    # @return [Hash] 
    #   * :Id [Integer] id av användaren
    #   * :Password [String] Krypterat lösenord
    # @return [nil] om tom
    def check_user(user)
        db = connect_db
        result = db.execute("SELECT Id,Password FROM User WHERE Name=?", user)
        return result
    end

    # kollar ifall pwd är samma som Password för User
    # @param [String] user namn på user
    # @param [String] pwd lösenord
    # @return [true] om lösenorden matchar
    # @return [false] om lösenorden inte matchar
    def pwd_match(user, pwd)
        db = connect_db
        pwd_digest = db.execute("SELECT Password FROM User WHERE Name=?", user).first["Password"]
        if BCrypt::Password.new(pwd_digest) == pwd
            return true
        else
            return false
        end
    end
   
    # Hämtar role från User
    # @param [String] user namn på user
    # @return [Integer] rolen på user
    def get_role(user)
        db = connect_db
        role = db.execute("SELECT Role FROM User WHERE Name=?", user).first["Role"]
        return role
    end

    # Loggar in
    # @param [String] user namn på user
    # @param [String] pwd lösenord
    # @return [true] om lösenorden matchar
    # @return [false] om lösenorden inte matchar
    def login(user, pwd)
    db = connect_db
    pwd_digest = db.execute("SELECT Password FROM User WHERE Name=?", user).first["Password"]
        if BCrypt::Password.new(pwd_digest) == pwd
            return true
        else
            return false
        end
    end

    # Tar bort alla bid_relations som har bids på NFTs 
    # @param [Integer] nft_id Id på NFT
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


    # Ändrar attributen Status i NFT till "inactive"
    # @param [Integer] nft_id Id på NFT
    def deactivate_nft(nft_id)
        db = connect_db
        db.execute("UPDATE NFT SET Status = ? WHERE Id = ?","inactive", nft_id )
        current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last
            if current_lead != nil
                current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
                min_bid = db.execute("SELECT Startprice FROM NFT WHERE Id = ?", nft_id).first["Startprice"]
                give_money(current_lead, min_bid)
            end
        delete_relation(nft_id)
    end

    # Uppdaterar attributen Startprice i NFT till Currentvalue
    # @param [Integer] nft_id Id på NFT
    def remove(nft_id)
        db = connect_db
        deactivate_nft(nft_id)
        current_value = db.execute("SELECT Currentvalue FROM NFT WHERE Id = ?", nft_id).first["Currentvalue"]
        db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?", current_value, nft_id)
    end
   
    # Hämtar all data från NFT
    # @param [Integer] nft_id Id på NFT
    # @return [Hash] 
    #   * :Id [Integer] id av NFT
    #   * :OwnderId [Integer] Id av ägare
    #   * :CreatorId [Integer] id av skaparen
    #   * :Name [String] namn på NFT
    #   * :Status [String] Status till NFT
    #   * :Token [String] Token till NFT
    #   * :Description [String] förklaring av NFT
    #   * :Deadline [Integer] tid tills deadline
    #   * :Increment [Integer] minimum ökning av NFT i auction
    #   * :Startprice [Integer] Tillfälligt pris av NFT
    #   * :Currentvalue [Integer] Pris som NFT senast såldes för
    #   * :URL [String] route till bilden
    # @return [nil] om tom
    def get_nft(nft_id) 
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE Id = ?", nft_id).first
        return result
    end
    
    # Hämtar all data från User
    # @param [Integer] id id på user
    # @return [Hash] 
    #   * :Id [Integer] id av user
    #   * :Name [String] namn på user
    #   * :Password [String] krypterat lösenord
    #   * :Mail [String] mail till user
    #   * :Balance [Integer] Balance av user
    #   * :Sold [Integer] mängden sålda NFT
    #   * :Status [String] Status av användare
    #   * :Role [Integer] Rolen av user
    # @return [nil] om tom
    def get_user(id)
        db = connect_db
        user_result = db.execute("SELECT * FROM User WHERE Id = ?", id).first
        return user_result
    end
    
    # Hämtar all data från NFT med Status "inactive"
    # @param [Integer] id id på user
    # @return [Hash] 
    #   * :Id [Integer] id av user
    #   * :Name [String] namn på user
    #   * :Password [String] krypterat lösenord
    #   * :Mail [String] mail till user
    #   * :Balance [Integer] Balance av user
    #   * :Sold [Integer] mängden sålda NFT
    #   * :Status [String] Status av användare
    #   * :Role [Integer] Rolen av user
    # @return [nil] om tom
    def get_inactive_nft(id)
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE OwnerId = ? AND Status = ?", id, "inactive")
        return result
    end
   
    
    # Hämtar all data från NFT med Status "active"
    # @return [Hash] 
    #   * :Id [Integer] id av NFT
    #   * :OwnderId [Integer] Id av ägare
    #   * :CreatorId [Integer] id av skaparen
    #   * :Name [String] namn på NFT
    #   * :Status [String] Status till NFT
    #   * :Token [String] Token till NFT
    #   * :Description [String] förklaring av NFT
    #   * :Deadline [Integer] tid tills deadline
    #   * :Increment [Integer] minimum ökning av NFT i auction
    #   * :Startprice [Integer] Tillfälligt pris av NFT
    #   * :Currentvalue [Integer] Pris som NFT senast såldes för
    #   * :URL [String] route till bilden
    # @return [nil] om tom
    def get_active_nft()
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE Status = ?", "active")
        return result
    end
    
    # hämtar namn på ägare av NFT
    # @param [Integer] nft_id Id på NFT
    # @return [String] Namn på ägare av NFT
    def owner_name(nft_id)
        db = connect_db
        owner_id = owner_id(nft_id)
        owner_name = db.execute("SELECT Name FROM User WHERE Id = ?", owner_id).first["Name"]
        return owner_name
    end

    # Kollar ifall NFT med token finns
    # @param [String] token token av NFT
    # @return [true] om NFT finns
    # @return [false] om NFT inte finns
    def token_exists(token)
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE Token = ?", token).last
        if result != nil
            return true
        else
            return false
        end
    end

   
    # Kollar ifall NFT med URL finns
    # @param [String] url route till bild
    # @return [true] om NFT finns
    # @return [false] om NFT inte finns
    def  url_exists(url)
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE URL = ?", url).last
        if result != nil
            return true
        else
            return false
        end
    end
   
    # Kollar ifall NFT med Name finns
    # @param [String] name namn på NFT
    # @return [true] om NFT finns
    # @return [false] om NFT inte finns
    def nft_name_exists(name)
        db = connect_db
        result = db.execute("SELECT * FROM NFT WHERE Name = ?", name).last
        if result != nil
            return true
        else
            return false
        end
    end

end