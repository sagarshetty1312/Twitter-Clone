defmodule Twitter.Server do
  use GenServer

  def start_link() do
    {:ok,pid} = GenServer.start_link(__MODULE__, :noargs, [name: :twitterServer])
    initialise_db()
    {:ok,pid}
  end

  def get_state(pid) do
    GenServer.call(pid,{:getState})
  end

  def initialise_db() do
    # tweets table can have the client user id as the key
    # and the tweet as the values. Time stamped?
    :ets.new(:tweets, [:bag,:named_table,:public])
    :ets.new(:followers,[:bag,:named_table,:public])
    :ets.new(:following,[:bag,:named_table,:public])
    :ets.new(:allUsers,[:set,:named_table,:public])
  end

  def register_user(userId,nTweets) do
    GenServer.call(:twitterServer,{:registerUser,userId,nTweets})
  end

  def delete_user(userId) do
    GenServer.call(:twitterServer,{:deleteUser,userId})
  end

  def handle_call({:registerUser,userId,nTweets},_from,state) do

    if :ets.lookup(:allUsers, userId) == [] do
      {:ok,pid} = Twitter.Client.start_link(userId,nTweets)
      :ets.insert(:allUsers,{userId,pid})
      :ets.insert(:following,{userId,[]})
      :ets.insert(:tweets,{userId,[]})
      if :ets.lookup(:followers, userId) == [ ] do
        :ets.insert(:followers,{userId,[ ]})
      end
      "Registration Successfull"
    else
      "Registration Failed: UserID is already in use."
    end

    {:reply,state,state}

  end

  def handle_call({:deleteUser,userId},_from,state) do
   response=
    if :ets.lookup(:allUsers, userId) != [] do
      :ets.delete(:allUsers,userId)
      :ets.delete(:following,userId)
      :ets.delete(:followers,userId)
      :ets.delete(:tweets,userId)
      "User #{userId} removed"
    else
      "User could not be found"
    end
    {:reply,response,state}
  end


  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end

  def init(:noargs) do
    {:ok,%{}}
  end

end
