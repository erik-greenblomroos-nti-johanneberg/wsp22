
def connect_db
    db = SQLite3::Database.new("db/database.db") 
    db.results_as_hash = true
    return db
end

def user_bid(user_id, nft_id, bid_amount)
    db = connect_db
    bid_amount = bid_amount.to_i
    # Kan implementera så att man även måste betala en minimum increment
    min_bid = db.execute("SELECT Startprice FROM NFT WHERE Id = ?", nft_id).first["Startprice"]
    current_lead = db.execute("SELECT Userid FROM Bid WHERE NFTid = ?", nft_id).last["Userid"]
    owner = db.execute("SELECT OwnerId FROM NFT WHERE Id = ?", nft_id).first["OwnerId"]
    if bid_amount > min_bid && user_id.to_i != current_lead
        if user_id.to_i != owner 
        current_time = Time.now.to_s
        db.execute("INSERT INTO Bid (Bidamount, Bidtime, Userid, NFTid) VALUES(?,?,?,?)",bid_amount, current_time,user_id,nft_id)
        db.execute("UPDATE NFT SET Startprice = ? WHERE Id = ?",bid_amount, nft_id)
        else
            # ERROR -
            "You can't bid at your own NFT"
        end
    else
        # ERROR - Budet är för lågt
        "Your bid was too low"
    end

end