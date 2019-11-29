defmodule Twitter.Client do
  use GenServer

  def delete_account(userId) do
    Twitter.Server.delete_user(userId)
  end

  def tweet(userId,tweet) do
      GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendTweet, tweet})
  end

  def get_state(userId) do
    GenServer.call(String.to_atom("User"<>Integer.to_string(userId)),{:getState})
  end

  def follow_user(userId,tofollowID) do
    Twitter.Server.add_follower(userId,tofollowID)
  end

  def retweet(userId,tweets) do
    Enum.each(tweets,fn tweet ->
      GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendRetweet, tweet})
    end)
  end

  def queryMentions(userId) do
    key = "User"<>Integer.to_string(userId)
    {_,mentionsList, _} = GenServer.call(String.to_atom("User"<>Integer.to_string(userId)), {:queryTweet, "@"<>key})
    mentionsList
  end

  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end

  def handle_cast({:tweetLive,tweet},state) do
    {userId, nTweets, isOnline} = state
    if isOnline == true do
      IO.puts "#{tweet}"
    end
    {:noreply, {userId, nTweets, true}}
  end

  def handle_cast({:logout,_userId},state) do
    {userId, nTweets, _isOnline} = state
    IO.puts "User logged out: User#{userId}"
    {:noreply, {userId, nTweets, false}}
  end

  def handle_cast({:login,_userId},state) do
    {userId, nTweets, _isOnline} = state
    IO.puts "User logged in: User#{userId}"
    {:noreply, {userId, nTweets, true}}
  end

  def handle_cast({:subscribe, toFollowId},state) do
    {userId, nTweets, isOnline} = state
    if toFollowId != userId do
      GenServer.cast(:twitterServer,{:addFollower,userId,toFollowId})
      IO.puts "User#{userId} followed User#{toFollowId}."
    else
      IO.puts " "
    end
    {:noreply, {userId, nTweets, true}}
  end

  def handle_cast({:sendRetweet,tweet},state) do
    {userId, nTweets, isOnline} = state
    GenServer.cast(:twitterServer,{:tweet,userId,tweet<>"-RT'd by User#{userId}"})
    IO.puts "User#{userId} retweeted \"#{tweet}-RT'd by User#{userId}\""
    {:noreply, {userId, nTweets, true}}
  end

  def handle_cast({:sendTweet,tweet},state) do
    {userId, nTweets, isOnline} = state
    GenServer.cast(:twitterServer,{:tweet,userId,tweet<>"-by User#{userId}"})
    IO.puts "User#{userId} tweeted \"#{tweet}-by User#{userId}\""
    {:noreply, {userId, nTweets, true}}
  end

  def handle_call({:queryTweet,key},_,state) do
    {userId, nTweets, isOnline} = state
    list = GenServer.call(:twitterServer,{:fetchAllMentionsAndHashtags,key})
    {:reply,{userId, list, isOnline},state}
  end

  def start_link(userId,nTweets,isOnline) do
    {:ok,pid} = GenServer.start_link(__MODULE__, {userId,nTweets,isOnline},[name: String.to_atom("User"<>Integer.to_string(userId))])
    {:ok,pid}
  end


  def init({userId,nTweets,isOnline}) do
    #handleLiveTweets()
    {:ok,{userId, [], isOnline}}
  end
end
