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
    :ets.new(:mentionsAndHashTags, [:set, :public, :named_table])
  end

  def register_user(userId,nTweets,isOnline) do
    GenServer.call(:twitterServer,{:registerUser,userId,nTweets,isOnline})
  end

  def loginUser(userId,nTweets,isOnline) do
    GenServer.call(:twitterServer,{:loginUser,userId,nTweets,isOnline})
  end

  def logoutUser(userId,nTweets,isOnline) do
    GenServer.call(:twitterServer,{:logoutUser,userId,nTweets,isOnline})
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

  def retweet(userId,tweet) do
    GenServer.cast(:twitterServer,{:tweet,userId,"RT:"<>tweet})
  end

  def getTweetsMade(userId) do
    [tuple] = :ets.lookup(:tweetsMade, userId)
    elem(tuple,1)
  end

  def insert_tag(tag,tweet) do
    [tuple] =
      if :ets.lookup(:mentionsAndHashTags, tag) == [] do
        [nil]
      else
        :ets.lookup(:mentionsAndHashTags, tag)
      end
    if tuple ==nil do
      :ets.insert(:mentionsAndHashtags,{tag,tweet})
    else
      list = elem(tuple,1)
      newList = [tweet|list]
      :ets.insert(:mentionsAndHashtags,{tag,newList})
    end
  end

  def handle_call({:registerUser,userId,nTweets,isOnline},_from,state) do
    response=
      if :ets.lookup(:allUsers, userId) == [] do
        {:ok,pid} = Twitter.Client.start_link(userId,nTweets,isOnline)
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

  def handle_call({:loginUser,userId,nTweets,isOnline},_from,state) do
    response=
      if :ets.lookup(:allUsers, userId) == [] do
        "User: #{userId} not found. Login failed."
      else
        [_,pid] = :ets.lookup(:allUsers, userId)
        if pid == nil do
          {:ok,pid} = Twitter.Client.start_link(userId,nTweets,true)
          :ets.insert(:allUsers,{userId,pid})
        end
        "User #{userId} logged out successfully."
      end
    {:reply,response,state}
  end

  def handle_call({:logoutUser,userId,nTweets,isOnline},_from,state) do
    response=
      if :ets.lookup(:allUsers, userId) == [] do
        "User: #{userId} not found. Logout failed."
      else
        [_,pid] = :ets.lookup(:allUsers, userId)
        Process.exit(pid,:kill)
        :ets.insert(:allUsers,{userId,nil})
        "User #{userId} logged out successfully."
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

  def handle_cast({:addFollower,userId,tofollowID},state) do
    if :ets.lookup(:allUsers, tofollowID) != [] do
      update_followers_list(tofollowID,userId)
      update_following_list(userId,tofollowID)
    end
    {:noreply,state}
  end

  def handle_cast({:tweet,userId,tweet},state) do
    [tuple] = :ets.lookup(:tweetsMade, userId)
    tweetsList = elem(tuple,1)
    updatedTweetsList = [tweet | tweetsList]
    :ets.insert(:tweetsMade,{userId,updatedTweetsList})

    followers = get_followers(userId)


  #  Enum.each(followers, fn(follower) ->
  #       send(follower , {:tweet, [tweet] ++ ["-Tweet from user: "] ++ [user_pid] ++ ["forwarded to follower: "] ++ [follower_pid] })
  #      end)

    #hashtags in tweet
    hashtagsList = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet) |> Enum.concat
    Enum.each(hashtagsList, fn(hashtag)->
      insert_tag(hashtag,tweet)
    end)

    mentionsList = Regex.scan(~r/\B@[a-zA-Z0-9_]+/, tweet) |> Enum.concat
    Enum.each(mentionsList, fn(mention) ->
      insert_tag(mention,tweet)
    end)

  #  Enum.each(mentionsList, fn(follower) ->
  #       send(follower , {:tweet, [tweet] ++ ["-Tweet from user: "] ++ [user_pid] ++ ["forwarded to follower: "] ++ [follower_pid] })
  #      end)

    {:noreply,state}
  end

  def init(:noargs) do
    {:ok,%{}}
  end

end
