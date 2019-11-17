defmodule Twitter.Main do

  def create_users(0,_nTweets) do
     "Created all the users"
  end

  def create_users(numUsers,nTweets) do
    userId =  numUsers

    Twitter.Client.sign_up(userId,nTweets)
    create_users(numUsers-1,nTweets)
  end
end
