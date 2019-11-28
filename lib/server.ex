defmodule Twitter.Server do
  use GenServer

  def start_link() do
    {:ok,pid} = GenServer.start_link(__MODULE__, :noargs, [name: :twitterServer])
    initialise_db()
    {:ok,pid}
  end

  def init(:noargs) do
    {:ok,%{}}
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
    :ets.new(:mentionsHashtags, [:set, :public, :named_table])
  end

  #def register_user(userId,nTweets,isOnline) do
  #  GenServer.call(:twitterServer,{:registerUser,userId,nTweets,isOnline})
  #end

  #def loginUser(userId,nTweets,isOnline) do
  #  GenServer.call(:twitterServer,{:loginUser,userId,nTweets})
  #end

  #def logoutUser(userId,nTweets,isOnline) do
  #  GenServer.call(:twitterServer,{:logoutUser,userId,nTweets})
  #end

  def delete_user(userId) do
    GenServer.call(:twitterServer,{:deleteUser,userId})
  end

  #def add_follower(userId,tofollowID) do
  #  GenServer.cast(:twitterServer,{:addFollower,userId,tofollowID})
  #end

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

  #def tweet(userId,tweet) do
  #  GenServer.cast(:twitterServer,{:tweet,userId,tweet})
  #end

  #def retweet(userId,tweet) do
  #  GenServer.cast(:twitterServer,{:tweet,userId,"RT:"<>tweet})
  #end

  def getTweetsMade(userId) do
    [tuple] = :ets.lookup(:tweetsMade, userId)
    elem(tuple,1)
  end

  def insert_tag(tag,tweet) do
    [tuple] =
      if :ets.lookup(:mentionsHashtags, tag) == [] do
        [nil]
      else
        :ets.lookup(:mentionsHashtags, tag)
      end
    if tuple ==nil do
      :ets.insert(:mentionsHashtags,{tag,[tweet]})
    else
      list = elem(tuple,1)
      newList = [tweet|list]
      :ets.insert(:mentionsHashtags,{tag,newList})
    end
  end

  def handle_call({:registerUser,userId,nTweets,isOnline},_from,state) do
    response=
      if :ets.lookup(:allUsers, userId) == [] do
        {:ok,pid} = Twitter.Client.start_link(userId,nTweets,isOnline)
        :ets.insert(:allUsers,{userId,pid,:online})
        :ets.insert(:following,{userId,[]})
        :ets.insert(:tweetsMade,{userId,[]})
        if :ets.lookup(:followers, userId) == [ ] do
          :ets.insert(:followers,{userId,[ ]})
      end
      #"Registration Successfull"
      "Registration Successful with Id: user#{userId}"
    else
      "Registration Failed. UserID: user#{userId} is already in use."
    end
    {:reply,response,state}
  end

  def handle_call({:loginUser,userId,nTweets},_from,state) do
    response=
      if :ets.lookup(:allUsers, userId) == [] do
        "User: #{userId} not found. Login failed."
      else
        [{_,pid,state}] = :ets.lookup(:allUsers, userId)
        if state == :offline do
          #{:ok,pid} = Twitter.Client.start_link(userId,nTweets,true)
          :ets.insert(:allUsers,{userId,pid,:online})
          GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)),{:login,userId})
        end
      end
    {:reply,response,state}
  end

  def handle_call({:logoutUser,userId,nTweets},_from,state) do
    response=
      if :ets.lookup(:allUsers, userId) == [] do
        "User Id: user#{userId} not found. Logout failed."
      else
         [{_,pid,state}] = :ets.lookup(:allUsers, userId)
        :ets.insert(:allUsers,{userId,pid,:offline})
        GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)),{:logout,userId})
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

  def handle_cast({:displayAllFollowing,userId},state) do
    if :ets.lookup(:allUsers, userId) != [] do
      [{_,list}] = :ets.lookup(:following, userId)
      IO.puts "user#{userId} follows:"
      IO.inspect list
    end
    {:noreply,state}
  end

  def handle_cast({:displayAllMentionsAndHashtags, key},state) do
    if :ets.lookup(:mentionsHashtags, key) != [] do
      [{_,list}] = :ets.lookup(:mentionsHashtags, key)
      IO.puts "List of #{key}:"
      IO.inspect list
    end
    {:noreply,state}
  end

  def handle_call({:fetchAllMentionsAndHashtags, key},_, state) do
    list = if :ets.lookup(:mentionsHashtags, key) != [] do
      [{_,list}] = :ets.lookup(:mentionsHashtags, key)
      list
    else
      []
    end
    {:reply,state,list}
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
    tweetLive(tweet, followers, userId)
  #  Enum.each(followers, fn(follower) ->
  #       send(follower , {:tweet, [tweet] ++ ["-Tweet from user: "] ++ [user_pid] ++ ["forwarded to follower: "] ++ [follower_pid] })
  #      end)

    #hashtags in tweet
    hashtagsList = Regex.scan(~r/\B#[a-zA-Z0-9_]+/, tweet) |> Enum.concat
    Enum.each(hashtagsList, fn(hashtag)->
      insert_tag(hashtag,tweet)
    end)

    mentionsList = Regex.scan(~r/\B@User[0-9]+/, tweet) |> Enum.concat
    Enum.each(mentionsList, fn(mention) ->
      insert_tag(mention,tweet)
    end)
    mentionedUserIds = Enum.map(mentionsList,fn x -> String.slice(x,5..-1) |> String.to_integer end)
    validUserIds = checkForExistence(mentionedUserIds)
    tweetLive(tweet, validUserIds, userId)

    #mentionsList = Regex.scan(~r/\B@User[a-zA-Z0-9_]+/, tweet) |> Enum.concat
    #Enum.each(mentionsList, fn(mention) ->
    #  insert_tag(mention,tweet)
    #end)

  #  Enum.each(mentionsList, fn(follower) ->
  #       send(follower , {:tweet, [tweet] ++ ["-Tweet from user: "] ++ [user_pid] ++ ["forwarded to follower: "] ++ [follower_pid] })
  #      end)
    #IO.puts "Tweet: #{tweet} processed successfully."
    {:noreply,state}
  end

  def checkForExistence([]) do
    []
  end

  def checkForExistence(mentionedUserIds) do
    [head|tail] = mentionedUserIds
    cond do
      :ets.lookup(:allUsers, head) == [] -> checkForExistence(tail)
      true -> [head | checkForExistence(tail)]
    end
  end

  def tweetLive(tweet, userList, userId) do
    Enum.each(userList, fn(toUser) ->
      [{_,_,state}] = :ets.lookup(:allUsers, toUser)
      if state == :online do
        #send(pid , {:tweetLive, tweet<>"-Tweet from: "<>userId})
        GenServer.cast(String.to_atom("User"<>Integer.to_string(toUser)),{:tweetLive,"User#{toUser} received: "<>tweet})
      end
    end)
  end

end
