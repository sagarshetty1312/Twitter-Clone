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
    :ets.new(:tweetsMade, [:set,:named_table,:public])
    :ets.new(:followers,[:set,:named_table,:public])
    :ets.new(:following,[:set,:named_table,:public])
    :ets.new(:allUsers,[:set,:named_table,:public])
  end

  def register_user(userId,nTweets) do
    GenServer.call(:twitterServer,{:registerUser,userId,nTweets})
  end

  def delete_user(userId) do
    GenServer.call(:twitterServer,{:deleteUser,userId})
  end

  def add_follower(userId,tofollowID) do
    GenServer.cast(:twitterServer,{:addFollower,userId,tofollowID})
  end

  def get_followers(userId) do
    [tuple] = :ets.lookup(:followers, userId)
    elem(tuple,1)
  end

  def update_followers_list(toFollowId,userId) do
    followersList = get_followers(toFollowId)
    updatedFollowersList = [userId|followersList]
    :ets.insert(:followers,{toFollowId,updatedFollowersList})
  end

  def get_following(userId) do
    [tuple] =:ets.lookup(:following, userId)
    elem(tuple,1)
  end

  def update_following_list(userId,tofollowID) do
    followingList = get_following(userId)
    updatedFollowingList = [tofollowID|followingList]
    :ets.insert(:following,{userId,updatedFollowingList})
  end

  def tweet(userId,tweet) do
    GenServer.cast(:twitterServer,{:tweet,userId,tweet})
  end

  def getTweetsMade(userId) do
    [tuple] = :ets.lookup(:tweetsMade, userId)
    elem(tuple,1)
  end

  def handle_call({:registerUser,userId,nTweets},_from,state) do

    response=
      if :ets.lookup(:allUsers, userId) == [] do
        {:ok,pid} = Twitter.Client.start_link(userId,nTweets)
        :ets.insert(:allUsers,{userId,pid})
        :ets.insert(:following,{userId,[]})
        :ets.insert(:tweetsMade,{userId,[]})
        if :ets.lookup(:followers, userId) == [ ] do
          :ets.insert(:followers,{userId,[ ]})
      end
      "Registration Successfull"
    else
      "Registration Failed: UserID is already in use."
    end

    {:reply,response,state}

  end

  def handle_call({:deleteUser,userId},_from,state) do
   response=
    if :ets.lookup(:allUsers, userId) != [] do
      :ets.delete(:allUsers,userId)
      :ets.delete(:following,userId)
      :ets.delete(:followers,userId)
      :ets.delete(:tweetsMade,userId)
      "User #{userId} removed"
    else
      "User could not be found"
    end
    {:reply,response,state}
  end

  def handle_call({:getState},_from,state) do
    {:reply,state,state}
  end

  def handle_cast({:tweet,userId,tweet},state) do
    [tuple] = :ets.lookup(:tweetsMade, userId)
    tweetsList = elem(tuple,1)
    updatedTweetsList = [tweet | tweetsList]
    :ets.insert(:tweetsMade,{userId,updatedTweetsList})

    {:noreply,state}
  end

  def handle_cast({:addFollower,userId,tofollowID},state) do
    if :ets.lookup(:allUsers, tofollowID) != [] do
      update_followers_list(tofollowID,userId)
      update_following_list(userId,tofollowID)
    end
    {:noreply,state}
  end




  def init(:noargs) do
    {:ok,%{}}
  end

end
