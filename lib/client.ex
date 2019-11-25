defmodule Twitter.Client do
  use GenServer

  def sign_up(userId,nTweets,isOnline) do
    Twitter.Server.register_user(userId,nTweets,isOnline)
  end

  def delete_account(userId) do
    Twitter.Server.delete_user(userId)
  end

  def send_tweet(userId,tweet) do
    Twitter.Server.tweet(userId,tweet)
  end

  def start_link(userId,nTweets,isOnline) do
    {:ok,pid} = GenServer.start_link(__MODULE__, {userId,nTweets,isOnline},[name: String.to_atom("User"<>Integer.to_string(userId))])
    {:ok,pid}
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


  def init({userId,nTweets,isOnline}) do
    {:ok,%{:ID => userId, :nTweets => nTweets,:isOnline => isOnline}}
  end


end

