defmodule Twitter.Main do

  def start(numUsers,nTweets) do
    :global.register_name(:main, self())
    {:ok,pid} = Twitter.Server.start_link()
    IO.puts "Server started with pid #{inspect pid}"
    numToLogout = round(numUsers/2)
    userList = Enum.to_list(1..numUsers)

    #Simulation functions
    startTime = System.system_time(:millisecond)
    create_users(numUsers,nTweets,true)
    waitFor(:userCreationResp, numUsers)
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "Created #{numUsers}users in #{timeDiff}ms"

    startTime = System.system_time(:millisecond)
    listLoggedOut = logoutUsers(userList, numToLogout)
    waitFor(:userLogoutResp, numToLogout)
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "Logged out #{numToLogout} random users in #{timeDiff}ms"

    startTime = System.system_time(:millisecond)
    loginUsers(listLoggedOut)
    waitFor(:userLoginResp, numToLogout)
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "Logged in the same #{numToLogout} users in #{timeDiff}ms"

    startTime = System.system_time(:millisecond)
    subscribeAllUsersTo(userList, listLoggedOut)
    waitFor(:userFollowingResp, numUsers * length listLoggedOut)
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "Every user followed #{numToLogout} users. Completed in #{timeDiff}ms"

    #:timer.sleep(1000)
    startTime = System.system_time(:millisecond)
    tweetRandom(userList,nTweets)
    tweetwithHashtag(userList,"#COP5615 is great")
    usersMentioned = tweetToRandUser(userList,userList)
    waitFor(:userTweet, (numUsers+2)*nTweets)#Every user sends mention and hashtag once
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "Every user tweeted #{nTweets+2} times.Total number #{(numUsers+2)*nTweets} . Completed in #{timeDiff}ms"

    #:timer.sleep(2000)
    startTime = System.system_time(:millisecond)
    queryByMention(usersMentioned)
    waitFor(:queryTweet, length usersMentioned)
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "#{length usersMentioned} users queried their mentions. Completed in #{timeDiff}ms"

    startTime = System.system_time(:millisecond)
    randUser = Enum.random(userList)
    #{_,list,_} =
      queryByHashtag(randUser,"#COP5615")
    waitFor(:queryTweet, 1)
    timeDiff = System.system_time(:millisecond) - startTime
    IO.puts "Random User#{randUser} queried #COP5615. Completed in #{timeDiff}ms"

    startTime = System.system_time(:millisecond)
    #retweetTweets(randUser,list)
    timeDiff = System.system_time(:millisecond) - startTime
    #IO.puts "User#{randUser} retweeted #{length list} tweets. Completed in #{timeDiff}ms"
    #GenServer.cast(:twitterServer, {:displayAllMentionsAndHashtags, "#COP5615"})
    #for i <- userList, do: GenServer.cast(:twitterServer, {:displayAllFollowing, i})
    :timer.sleep(:infinity)
  end

  def create_users(0,_nTweets,_isOnline) do
     "Created all the users"
  end

  def create_users(numUsers,nTweets,isOnline) do
    userId =  numUsers
    #Twitter.Client.sign_up(userId,nTweets,isOnline)
    GenServer.call(:twitterServer,{:registerUser,userId,nTweets,isOnline}) #|> IO.puts
    create_users(numUsers-1,nTweets,isOnline)
  end

  def getRandomUser(userId, userList) do
    cond do
      userId == nil -> Enum.random(userList)
      true -> List.delete(userList, userId)
    end
  end
  
  def logoutUsers(userList, 0) do
    #IO.puts "Logged out the users"
    []
  end

  def logoutUsers(userList, numberLeft) do
    curUser = getRandomUser(nil,userList)
    GenServer.call(:twitterServer,{:logoutUser,curUser,0})
    [curUser|logoutUsers(List.delete(userList,curUser), numberLeft-1)]
  end

  def loginUsers([]) do
    #IO.puts "Logged in the users"
  end

  def loginUsers(listLoggedOut) do
    [head|tail] = listLoggedOut
    GenServer.call(:twitterServer,{:loginUser,head,0})
    loginUsers(tail)
  end

  def subscribeAllUsersTo([], _listToSubscribe) do
    []
  end

  def subscribeAllUsersTo(userList, listToSubscribe) do
    [head|tail] = userList
    simulateSubscribe(head, listToSubscribe)
    subscribeAllUsersTo(tail, listToSubscribe)
  end

  def simulateSubscribe(userId, []) do
    []
  end

  def simulateSubscribe(userId, listToSubscribe) do
      [head|tail] = listToSubscribe
      if head !=userId do
        GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:subscribe, head})
      else
        Twitter.Server.sendAcknowledgement(:userFollowingResp)
      end
      simulateSubscribe(userId, tail)
  end

  def tweetRandom([],_nTweets) do
    #IO.puts "Random tweeting done."
  end

  def tweetRandom(userList,nTweets) do
    [userId|tail] = userList
    simulateRandTweetsFor(userId,nTweets)
    tweetRandom(tail,nTweets)
  end

  def simulateRandTweetsFor(_userId,0) do
    []
  end

  def simulateRandTweetsFor(userId,nTweetsLeft) do
    tweet = "Tweet No #{nTweetsLeft}: Pumpkin spice is back"
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendTweet, tweet})
    simulateRandTweetsFor(userId,nTweetsLeft-1)
  end

  def tweetwithHashtag([],_tweet) do
    []
  end

  def tweetwithHashtag(userList,tweet) do
    [userId|tail] = userList
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendTweet, tweet})
    tweetwithHashtag(tail,tweet)
  end

  def tweetToRandUser([],_userList) do
    []
  end

  def tweetToRandUser(usersLeft,userList) do
    [userId|tail] = usersLeft
    toUser = Enum.random(userList)
    tweet = "Hello there @User#{toUser}."
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendTweet, tweet})
    [toUser|tweetToRandUser(tail,usersLeft)]
  end

  def queryByMention([]) do
    []
  end

  def queryByMention(userList) do
    [userId|tail] = userList
    key = "User"<>Integer.to_string(userId)
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:queryTweet, "@"<>key})
    queryByMention(tail)
  end

  def queryByHashtag(userId,key) do
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:queryTweet, key})
  end

  def retweetTweets(_randUser,[]) do
    []
  end

  def retweetTweets(userId,tweetList) do
    [head|tail] = tweetList
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendRetweet, head})
    retweetTweets(userId,tail)
  end

  def waitFor(response, 0), do: nil
  def waitFor(response, numUsers) do
    receive do
      {_response} -> []#IO.puts "Response #{numUsers}"
      #{_} ->IO.puts "do nothing"
    end
    waitFor(response, numUsers-1)
  end
end
