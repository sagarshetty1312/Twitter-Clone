defmodule Proj4Test do
  use ExUnit.Case
  doctest Proj4

  # Initial setup for the test cases to work upon
  @tag testCase: 1
  test "tables created check" do
    IO.puts "###################################################"
    IO.puts "Check if the tables are created when the server is started"
    {:ok,pid} = Twitter.Server.start_link()
    assert :ets.whereis(:allUsers) != :undefined
    assert :ets.whereis(:tweetsMade) != :undefined
    assert :ets.whereis(:followers) != :undefined
    assert :ets.whereis(:following) != :undefined
    assert :ets.whereis(:mentionsHashtags) != :undefined
    IO.puts "Tables where created successfully"
    IO.puts "####################################################"
  end

  @tag testCase: 2
  test "user registration check" do
    IO.puts " "
    IO.puts "####################################################"
    IO.puts "Check weather users can be registered"
    {:ok,_} = Twitter.Server.start_link()
    IO.inspect "Register some users"
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts
    assert :ets.lookup(:allUsers, 1) != []
    assert :ets.lookup(:allUsers, 2) != []
    assert :ets.lookup(:allUsers, 3) != []
    IO.puts "The users were successfully added to the tables"
    IO.puts "#####################################################"
    IO.puts " "
  end

  @tag testCase: 3
  test "duplicate user addition" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "Check weather duplicate user can be registered"
    {:ok,_} = Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    IO.puts "Try adding the same user again"
    Twitter.Server.register_user(1,12,true) |> IO.puts
    [{_,clientPID,_}] = :ets.lookup(:allUsers, 1)
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 4
  test "deletion of an account" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "Delete an account and verify whether it is removed from all the tables"
    {:ok,_} = Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.delete_user(1) |> IO.puts
    assert :ets.lookup(:allUsers, 1) == []
    assert :ets.lookup(:following, 1) == []
    assert :ets.lookup(:followers, 1) == []
    assert :ets.lookup(:tweetsMade, 1) == []
    IO.puts "The user successfully removed from all the tables"
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 5
  test "deleting of an account not present in the system" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "Try deleting an account not present"
    Twitter.Server.start_link()
    IO.inspect "Register some users"
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts
    assert :ets.lookup(:allUsers, 1) != []
    assert :ets.lookup(:allUsers, 2) != []
    assert :ets.lookup(:allUsers, 3) != []
    IO.puts "Try deleting user 4 not present"
    Twitter.Server.delete_user(4) |> IO.puts
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 6
  test "Check if followers are getting adding to the follwers list" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "User follows another user check"
    Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts
    IO.puts "The followers list of user 1 before adding the followers:"
    IO.inspect Twitter.Server.get_followers(1)
    Twitter.Server.add_follower(2,1)
    Twitter.Server.add_follower(3,1)
    :timer.sleep(10) #since add followers function is a cast call, introduce a delay before checking th result
    IO.puts "The updated followers list of user1 is:"
    IO.inspect Twitter.Server.get_followers(1)
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 7
  test "sending tweets" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "User tweets a message and is displayed to his/her followers"
    Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts
    Twitter.Server.add_follower(2,1) #user 2 following user 1
    Twitter.Server.add_follower(3,1) #user 3 following user 1
    #all the users are currently active. So, they should recieve the any tweet made by User 1
    :timer.sleep(10)
    tweet_string = "check tweet"
    Twitter.Client.tweet(1,tweet_string)
    :timer.sleep(10)
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 8
  test "sending tweets offline check" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "User tweets made by a user not displayed to logged of users"
    Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts
    Twitter.Server.add_follower(2,1) #user 2 following user 1
    Twitter.Server.add_follower(3,1) #user 3 following user 1
    Twitter.Server.logout_user(2) #logging out user 2
    :timer.sleep(10)
    tweet_string = "check tweet"
    Twitter.Client.tweet(1,tweet_string) #since user 2 is logged out,it would not recieve the tweet made by user 1
    :timer.sleep(10)
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 9
  test "check login and logout" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "Check if a user can be logged in"
    Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts ##user would be logged in when registering
    Twitter.Server.login_user(1)
    {_,_,status} = Twitter.Client.get_state(1)
    assert status == true ##verify whether the status is true
    Twitter.Server.logout_user(1)
    {_,_,status} = Twitter.Client.get_state(1)
    assert status == false #verify whether the state of the client gets updated to false
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 10
  test "retweet" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "Retweet functionality"
    Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts
    Twitter.Server.register_user(4,1,true)
    Twitter.Server.add_follower(2,1)
    Twitter.Server.add_follower(3,1)
    Twitter.Server.add_follower(4,2)
    :timer.sleep(10)
    tweet_string = "#COP5615 is great"
    Twitter.Client.tweet(1,tweet_string) #users 2 and 3 should have recieved the message

    # # user 2 querying the hashtag and retweeting to its followers
    {_,list,_} = Twitter.Main.queryByHashtag(1,"#COP5615")

    Twitter.Client.retweet(2, list)#since user 4 follows user 2, it should recieve the retweet made by user 2 live
    :timer.sleep(20)
    IO.puts "#########################################################"
    IO.puts " "
  end

  @tag testCase: 11
  test "query mentions" do
    IO.puts " "
    IO.puts "#########################################################"
    IO.puts "Query mentions functionality"
    #Register some users
    Twitter.Server.start_link()
    Twitter.Server.register_user(1,1,true) |> IO.puts
    Twitter.Server.register_user(2,1,true) |> IO.puts
    Twitter.Server.register_user(3,1,true) |> IO.puts

    #user1 mentioning user 2 in his tweet
    tweet = "Hello there @User#{2}."
    Twitter.Client.tweet(1, tweet)
    :timer.sleep(10)

    #user2 querying for his mentions
    mentions = Twitter.Client.queryMentions(2)
    #Print out all the tweets that mentioned user 2
    Enum.each(mentions,fn mention -> IO.puts(mention) end)
  end



end
