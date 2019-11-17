defmodule Twitter.Client do
  use GenServer

  def sign_up(userId,nTweets) do
    Twitter.Server.register_user(userId,nTweets)
  end

  def delete_account(userId) do
    Twitter.Server.delete_user(userId)
  end

  def start_link(userId,nTweets) do
    {:ok,pid} = GenServer.start_link(__MODULE__, {userId,nTweets})
    {:ok,pid}
  end

  def get_state(pid) do
    GenServer.call(pid,{:getState})
  end

  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end


  def init({userId,nTweets}) do
    {:ok,%{:ID => userId, :nTweets => nTweets}}
  end


end

