defmodule Twitter.Client do
  use GenServer

  #def sign_up(userId,nTweets,isOnline) do
  #  Twitter.Server.register_user(userId,nTweets,isOnline)
  #end

  #def login(userId,nTweets,isOnline) do
  #  Twitter.Server.loginUser(userId,nTweets)
  #end

  #def logout(userId,nTweets) do
  #  Twitter.Server.logoutUser(userId,nTweets)
  #end

  def delete_account(userId) do
    Twitter.Server.delete_user(userId)
  end

  def send_tweet(userId,tweet) do
    Twitter.Server.tweet(userId,tweet)
  end

  def send_retweet(userId, tweet) do
    Twitter.Server.retweet(userId,tweet)
  end

  def get_state(pid) do
    GenServer.call(pid,{:getState})
  end

  def follow_user(userId,tofollowID) do
    Twitter.Server.add_follower(userId,tofollowID)
  end

  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end

  def handle_cast({:tweetLive,tweet},_from,state) do
    IO.puts "Live tweet: #{tweet}"
    {:noreply, state}
  end

  def handle_cast({:logout,userId},state) do
    {userId, nTweets, isOnline} = state
    IO.puts "User logged out: user#{userId}"
    {:noreply, {userId, nTweets, false}}
  end

  def handle_cast({:login,userId},state) do
    {userId, nTweets, isOnline} = state
    IO.puts "User logged in: user#{userId}"
    {:noreply, {userId, nTweets, true}}
  end

  def handleLiveTweets() do
    receive do
      {:tweetLive,tweet} -> IO.puts "Live tweet: #{tweet}"
    end
    handleLiveTweets()
  end

  def start_link(userId,nTweets,isOnline) do
    {:ok,pid} = GenServer.start_link(__MODULE__, {userId,nTweets,isOnline},[name: String.to_atom("User"<>Integer.to_string(userId))])
    {:ok,pid}
  end

  def init({userId,nTweets,isOnline}) do
    #handleLiveTweets()
    {:ok,{userId, nTweets, isOnline}}
  end
end
