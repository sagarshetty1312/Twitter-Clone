defmodule Twitter.Main do

  def start(numUsers,nTweets,isOnline) do
    {:ok,pid} = Twitter.Server.start_link()
    numToLogout = round(numUsers/2)
    userList = Enum.to_list(1..numUsers)
    #Simulation functions
    create_users(numUsers,nTweets,true)
    listLoggedOut = logoutUsers(userList, numToLogout)
    loginUsers(listLoggedOut)
    subscribeAllUsersTo(userList, listLoggedOut)
    :timer.sleep(1000)
    tweetRandom(userList,nTweets)
    tweetwithHashtag(userList,"#COP5615 is great")
    tweetToRandUser(userList,userList)
    :timer.sleep(1000)
    GenServer.cast(:twitterServer, {:displayAllMentionsAndHashtags, "#COP5615"})
    #for i <- userList, do: GenServer.cast(:twitterServer, {:displayAllFollowing, i})
    :timer.sleep(:infinity)
  end

  def create_users(0,_nTweets,_isOnline) do
     "Created all the users"
  end

  def create_users(numUsers,nTweets,isOnline) do
    userId =  numUsers
    #Twitter.Client.sign_up(userId,nTweets,isOnline)
    GenServer.call(:twitterServer,{:registerUser,userId,nTweets,isOnline}) |> IO.puts
    create_users(numUsers-1,nTweets,isOnline)
  end

  def getRandomUser(userId, userList) do
    cond do
      userId == nil -> Enum.random(userList)
      true -> List.delete(userList, userId)
    end
  end
  
  def logoutUsers(userList, 0) do
    IO.puts "Logged out the users"
    []
  end

  def logoutUsers(userList, numberLeft) do
    curUser = getRandomUser(nil,userList)
    GenServer.call(:twitterServer,{:logoutUser,curUser,0})
    [curUser|logoutUsers(List.delete(userList,curUser), numberLeft-1)]
  end

  def loginUsers([]) do
    IO.puts "Logged in the users"
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
      end
      simulateSubscribe(userId, tail)
  end

  def tweetRandom([],_nTweets) do
    IO.puts "Random tweeting done."
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

  def tweetToRandUser([],userList) do

  end

  def tweetToRandUser(usersLeft,userList) do
    [userId|tail] = userList
    toUser = Enum.random(userList)
    tweet = "Hello there @User#{toUser}."
    GenServer.cast(String.to_atom("User"<>Integer.to_string(userId)), {:sendTweet, tweet})
    tweetToRandUser(tail,usersLeft)
  end
end
