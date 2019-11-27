defmodule Twitter.Main do

  def start(numUsers,nTweets,isOnline) do
    {:ok,pid} = Twitter.Server.start_link()
    create_users(numUsers,nTweets,true)
    numToLogout = round(numUsers/2)
    listLoggedOut = logoutUsers(Enum.to_list(1..numUsers), numToLogout)
    loginUsers(listLoggedOut)
    #:timer.sleep(:infinity)
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

  def logoutUsers(userList, 0) do
    IO.puts "Logged out the users"
    []
  end

  def logoutUsers(userList, numberLeft) do
    curUser = Enum.random(userList)
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

end
