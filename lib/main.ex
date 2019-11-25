defmodule Twitter.Main do

  def create_users(0,_nTweets,_isOnline) do
     "Created all the users"
  end

  def create_users(numUsers,nTweets,isOnline) do
    userId =  numUsers
    Twitter.Client.sign_up(userId,nTweets,isOnline)
    create_users(numUsers-1,nTweets,isOnline)
  end
end
