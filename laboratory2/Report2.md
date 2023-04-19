# FAF.PTR16.1 -- Project 1
> **Performed by:** Tafune Cristian-Sergiu, group FAF-202
> **Verified by:** asist. univ. Alexandru Osadcenco

## P1W1

In this week the focus of the laboratory work was on setting up the Docker image and making the actors thast would read the incoming streams from the image.

**Minimal Task** -- Create an actor that would print on the screen the tweets it receives from the SSE Reader. You can only print the text of the tweet to save on screen space.

To initialize the actor, an argument that is the link to the SSE stream needs to be passed. The URL link is used to create a new connection to the stream. The actor then waits for the incoming messages and prints them to the screen.

```elixir
def start_link(name, url) do
    GenServer.start_link(__MODULE__, url, name: name)
end
```

`HTTPoison.get!()` is used to create a new connection to the stream. The options are set to receive the stream indefinitely and to send the stream to the actor itself.

```elixir
def init(url) do
    HTTPoison.get!(url, [], [recv_timeout: :infinity, stream_to: self()])
    {:ok, nil}
end
```

The actor has a handle_info function with `HTTPoison.AsyncChunk` argument used to receive the incoming messages. The messages are then decoded and printed to the screen.

```elixir
def handle_info(%HTTPoison.AsyncChunk{chunk: chunk}, _state) do
    "event: \"message\"\n\ndata: " <> message = chunk
    {success, response} = Jason.decode(String.trim(message))
    if success == :ok do
        tweet = Map.get(response, "message") |> Map.get("tweet") |> Map.get("text")
        IO.inspect(tweet)
    end
    {:noreply, nil}
end
```

**Main Task** -- Create a second Reader actor that will consume the second stream provided by the Docker image.

The second actor is created and works in the same way as the first one as it is an actor that can be created multiple times with multiple links to the streams. The only difference is that the second actor is created with a different name and different link to the stream.

**Main Task** -- Simulate some load on the actor by sleeping every time a tweet is received. Suggested time of sleep – 5ms to 50ms. Consider using Poisson distribution. Sleep values / distribution parameters need to be parameterizable.

For this particular task, a different actor was created - Printer actor. The printer actor receives the tweets from both Reader actors and prints them to the screen. The printer actor also has a sleep function that is called every time a tweet is received. The sleep function takes a random value between 5 and 50 milliseconds and sleeps for that amount of time.

On itialization, the actor receives 3 arguments: the name of the actor, minimum sleep time and maximum sleep time.

```elixir
def start_link(name, min_time, max_time) do
    GenServer.start_link(__MODULE__, {name, min_time, max_time}, name: name)
end

def init({name, min_time, max_time}) do
    {:ok, {name, min_time, max_time}}
end
```

The Printer actor has a handle_info function that receives the tweets from the Reader actors. The tweets are then printed to the screen and the sleep function is called.

```elixir
def handle_info({:tweet, tweet}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    IO.puts "#{name}: #{inspect tweet}"
    {:noreply, {name, min_time, max_time}}
end
```

**Bonus Task** -- Create an actor that would print out every 5 seconds the most popular hashtag in the last 5 seconds.

The HashtagPrinter actor gets initialized with an empty list. The actor then waits for the tweets from the Reader actors and adds them to the list. Every 5 seconds, the actor sorts the list and prints the most popular hashtag.

```elixir
def start_link do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
end

def init(hashtagMap) do
    Process.send_after(self(), :getMostUsedHashtag, 5000)
    {:ok, hashtagMap}
end
```

The receives the message and if the hashtag exists in the map, it increments the value by 1. If the hashtag does not exist in the map, it is added to the map with a value of 1.

```elixir
def handle_info({:tweet, hashtagList}, hashtagMap) do
    hashtagMap = Enum.reduce(hashtagList, hashtagMap, fn hashtag, hashtagMap ->
        case Map.get(hashtagMap, hashtag) do
        nil -> Map.put(hashtagMap, hashtag, 1)
        count -> Map.put(hashtagMap, hashtag, count + 1)
        end
    end)
    {:noreply, hashtagMap}
end
```

After 5 seconds, the actor takes the highest value from the map and prints it to the screen. After printing the most popular hashtag, the map is cleared and the actor waits for 5 more seconds by sending itself the `:getMostUsedHashtag` message.

```elixir
def handle_info(:getMostUsedHashtag, hashtagMap) do
    {mostUsedHashtag, count} = hashtagMap |> Map.to_list |> Enum.max_by(fn {_, count} -> count end)
    IO.puts("\n")
    IO.inspect "Most used hashtag: #{mostUsedHashtag} with #{count} occurences."
    IO.puts("\n")
    hashtagMap = %{}
    Process.send_after(self(), :getMostUsedHashtag, 5000)
    {:noreply, hashtagMap}
end
```

**Flow Diagram of Week 1**

![Flow Diagram of Week 1](/laboratory2/diagrams/flowchart/flowchart-week1.png)

**Sequence Diagram of Week 1**
![Sequence Diagram of Week 1](/laboratory2/diagrams/sequence/sequence-week1.png)

## P1W2

**Minimal Task** -- Create a Worker Pool to substitute the Printer actor from previous week. The pool will contain 3 copies of the Printer actor which will be supervised by a Pool Supervisor. Use the one-for-one restart policy.

For this task, the Supervisor module was used to create a Pool Supervisor. The Pool Supervisor has 3 children: Printer1, Printer2 and Printer3. The children are created with the `:one_for_one` strategy.

On itialization, the actor takes the arguments `min_time` and `max_time` and creates the Pool Supervisor with the 3 Printer actors. The `min_time` and `max_time` are passed to all the printers as arguments.

```elixir
def start_link(min_time, max_time) do
    Supervisor.start_link(__MODULE__, {min_time, max_time}, name: __MODULE__)
end

def init({min_time, max_time}) do
    children = [
      %{
        id: :printer1,
        start: {Lab2P1W1.Printer, :start_link, [:printer1, min_time, max_time]}
      },
      %{
        id: :printer2,
        start: {Lab2P1W1.Printer, :start_link, [:printer2, min_time, max_time]}
      },
      %{
        id: :printer3,
        start: {Lab2P1W1.Printer, :start_link, [:printer3, min_time, max_time]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
end
```

On top of this worker pool, there is another Supervisor that is responsible for the initalization of the Reader actors, HashtagPrinter actor and the supervisor from above. The main supervisor is called in the `laboratory2.ex` file.

```elixir
def init({min_time, max_time}) do
    children = [
      %{
        id: :workerPool,
        start: {Lab2P1W2.WorkerPool, :start_link, [min_time, max_time]}
      },
      %{
        id: :reader1,
        start: {Lab2P1W1.Reader, :start_link, [:reader1, "http://localhost:4000/tweets/1"]}
      },
      %{
        id: :reader2,
        start: {Lab2P1W1.Reader, :start_link, [:reader2, "http://localhost:4000/tweets/2"]}
      },
      %{
        id: :hashtagPrinter,
        start: {Lab2P1W1.HashtagPrinter, :start_link, []}
      },
    ]

    Supervisor.init(children, strategy: :one_for_one)
end
```

**Minimal Task** -- Create an actor that would mediate the tasks being sent to the Worker Pool. Any tweet that this actor receives will be sent to the Worker Pool in a Round Robin fashion. Direct the Reader actor to sent it’s tweets to this actor.

The mediator in this laboratory work is called "Load Balancer". The Load Balancer actor receives the tweets from the Reader actors and sends them to the Worker Pool in a Round Robin fashion. The Load Balancer actor also has a counter that is incremented every time a tweet is received. The counter is used to determine which printer to send the tweet to (in case the actor exists or is alive).

On initialization, the Load Balancer actor gets the number of printers from the Worker Pool and creates a counter that is used to determine which printer to send the tweet to.

```elixir
def handle_info({:tweet, tweet}, {current, _num}) do
    currentNumWorkers = Lab2P1W2.WorkerPool.getNumWorkers()
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      tweetToSend = Map.get(tweet, "text") |> Lab2P1W3.BadWordChecker.checkAndChange()
      hashtagToSend = Map.get(tweet, "entities") |> Map.get("hashtags") |> Enum.map(fn x -> Map.get(x, "text") end)
      send(id_gen, {:tweet, tweetToSend})
      if(hashtagToSend != []) do
        send(Lab2P1W1.HashtagPrinter, {:tweet, hashtagToSend})
      end
    end
    {:noreply, {rem(current + 1, currentNumWorkers), currentNumWorkers}}
end
```

**Main Task** -- Occasionally, the SSE events will contain a “kill message”. Change the actor to crash when such a message is received. Of course, this should trigger the supervisor to restart the crashed actor.

For this task a new `handle_info` function was created inside the Reader actor. The function checks if the tweet data contains the `panic` message. If it does, tweet is sent to the Load Balancer actor and will choose the next printer that will receive the kill message. When the printer receives it, `exit(:crash)` will be called.

```elixir
#Panic message found in tweet being sent to Load Balancer
def handle_info(%HTTPoison.AsyncChunk{chunk: "event: \"message\"\n\ndata: {\"message\": panic}\n\n"}, _state) do
    send(Lab2P1W2.LoadBalancer, :panic)
    {:noreply, nil}
end

#Load Balancer sends tweet to printer
def handle_info(:panic, {current, _num}) do
    currentNumWorkers = Lab2P1W2.WorkerPool.getNumWorkers()
    id_gen = :"printer#{current + 1}"
    if Process.whereis(id_gen) != nil do
      send(id_gen, :panic)
    end
    {:noreply, {rem(current + 1, currentNumWorkers), currentNumWorkers}}
end

#Printer receives kill message
def handle_info(:panic, {name, min_time, max_time}) do
    IO.puts "#{name}: Panicked and killed itself."
    exit(:crash)
    {:noreply, {name, min_time, max_time}}
end
```

**Flow Diagram of Week 2**

![Flow Diagram of Week 2](/laboratory2/diagrams/flowchart/flowchart-week2.png)

**Sequence Diagram of Week 2**
![Sequence Diagram of Week 2](/laboratory2/diagrams/sequence/sequence-week2.png)

# P1W3

**Minimal Task** -- Any bad words that a tweet might contain mustn’t be printed. Instead, a set of stars should appear, the number of which corresponds to the bad word’s length. Consult the Internet for a list of bad words.

For this task, a simple function was made that checks if the tweet contains any bad words. It uses a Regex to check if the tweet contains any of the bad words from a JSON list of bad words. If it does, the bad word is replaced with a string of stars with the same length as the bad word.

```elixir
def checkAndChange(tweet) do
    jason = File.read!("lib/bad-words.json")
    bad_words = Jason.decode!(jason)
    tweet = Regex.replace(~r/(\w+)/, tweet, fn word ->
      if Enum.member?(bad_words, String.downcase(word)) do
        String.replace(String.downcase(word), ~r/./, "*")
      else
        word
      end
    end)
end
```

**Main Task** -- Create an actor that would manage the number of Worker actors in the Worker Pool. When the actor detects an increase in incoming tasks, it should instruct the Worker Pool to also increase the number of workers. Conversely, if the number of tasks in the stream is low, the actor should dictate to reduce the number of workers (down to a certain limit). The limit, and any other parameters of this actor, should of course be parameterizable.

For this task, a new actor was created called "Manager". For the manager to work a set of functions were added to the Worker Pool Supervisor. The functions are used to get the number of workers and to add or remove workers from the pool.

```elixir
#Gets the number of Printers in the Worker Pool
def getNumWorkers() do
    Supervisor.count_children(Lab2P1W2.WorkerPool) |> Map.get(:specs)
end

#Gets the list of workers in the Worker Pool (PID)
def whichWorkers() do
    IO.inspect(Supervisor.which_children(Lab2P1W2.WorkerPool))
    Supervisor.which_children(Lab2P1W2.WorkerPool)
end

#Adds a new worker to the Worker Pool
def addWorker() do
    id = getNumWorkers() + 1
    Supervisor.start_child(Lab2P1W2.WorkerPool, %{
      id: "printer#{id}",
      start: {Lab2P1W1.Printer, :start_link, [:"printer#{id}", 10, 50]}
    })
    IO.inspect("Added worker printer#{id}")
end

#Removes a worker from the Worker Pool
def removeWorker() do
    workers = whichWorkers() |> Enum.map(fn {id, _, _, _} -> id end)
    Supervisor.terminate_child(Lab2P1W2.WorkerPool, List.first(workers))
    Supervisor.delete_child(Lab2P1W2.WorkerPool, List.first(workers))
    IO.inspect("Removed worker #{List.first(workers)}")
end
```

The Manager actor on initialization calculates the current load of the application by checking the queue size of the Printers. If the current load is greater than a specified threshold and the number of workers is less than the maximum number of workers, the Manager actor will add a new worker to the Worker Pool. If the current load is less than a specified threshold and the number of workers is greater than the minimum number of workers, the Manager actor will remove a worker from the Worker Pool. The Manager actor will check the current load every 5 seconds.

```elixir
#Checks the current load of actors
def calcLoad() do
    currentWorkers = Lab2P1W2.WorkerPool.whichWorkers() |> Enum.map(fn {_, pid, _, _} -> pid end)
    numWorkers = Enum.count(currentWorkers)
    currentLoad = Enum.reduce(currentWorkers, 0, fn pid, acc ->
      {_, queue} = Process.info(pid, :message_queue_len)
      acc + queue
    end)
    {numWorkers, currentLoad}
end

#Checks the current load and adds/removes workers from the Worker Pool
def handle_info(:manage, {time_check, max_worker, min_worker}) do
    {numWorkers, currentLoad} = calcLoad()
    laFormula = (currentLoad / numWorkers) / 100
    IO.inspect("Current load: #{laFormula}")
    cond do
      laFormula > 0.8 and numWorkers < max_worker ->
        Lab2P1W2.WorkerPool.addWorker()
      laFormula < 0.2 and numWorkers > min_worker ->
        Lab2P1W2.WorkerPool.removeWorker()
      true ->
        :no_change
    end
    Process.send_after(self(), :manage, time_check)
    {:noreply, {time_check, max_worker, min_worker}}
end
```

**Flow Diagram of Week 3**

![Flow Diagram of Week 3](/laboratory2/diagrams/flowchart/flowchart-week3.png)

**Sequence Diagram of Week 3**
![Sequence Diagram of Week 3](/laboratory2/diagrams/sequence/sequence-week3.png)

# P1W4

**Minimal Task** -- Besides printing out the redacted tweet text, the Worker actor must also calculate two values: the Sentiment Score and the Engagement Ratio of the tweet. To compute the Sentiment Score per tweet you should calculate the mean of emotional scores of each word in the tweet text. A map that links words with their scores is provided as an endpoint in the Docker container. If a word cannot be found in the map, it’s emotional score is equal to 0.

Engagement Ratio is calculated as the ratio of the number of favourites plus the number of retweets to the number of followers of the user who posted the tweet. If the user has no followers, the Engagement Ratio is equal to 0.

```elixir
def handle_info({:tweet, {id, tweet}}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    followerCount = Map.get(tweet, "user") |> Map.get("followers_count")
    retweetCount = if Map.get(tweet, "retweeted_status") == nil do
      Map.get(tweet, "retweet_count")
    else
      Map.get(tweet, "retweeted_status") |> Map.get("retweet_count")
    end
    favoriteCount = if Map.get(tweet, "retweeted_status") == nil do
      Map.get(tweet, "favorite_count")
    else
      Map.get(tweet, "retweeted_status") |> Map.get("favorite_count")
    end

    if followerCount != 0 do
      engagement = (retweetCount + favoriteCount) / followerCount |> Float.ceil(2)
      send(Aggregator, {:addToList, {id, "engagement", engagement}})
    else
      send(Aggregator, {:addToList, {id, "engagement", 0.0}})
    end
    {:noreply, {name, min_time, max_time}}
end
```

**Main Task** -- Break up the logic of your current Worker into 3 separate actors: one which redacts the tweet text, another that calculates the Sentiment Score and lastly, one that computes the Engagement Ratio.

The Redacter actor is responsible for redacting the tweet text. The actor receives the tweet text and uses the function mentioned in P1W3 to redact the tweet text. The actor then prints the redacted tweet text.

```elixir
def handle_info({:tweet, {id, tweet}}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    tweetToPrint = Map.get(tweet, "text") |> BadWordChecker.checkAndChange()
    IO.inspect tweetToPrint
    {:noreply, {name, min_time, max_time}}
end
```

The Engagement Calculator actor is responsible for calculating the Engagement Ratio. The actor receives the tweet and calculates the Engagement Ratio. The actor then prints the Engagement Ratio. The code is similar to the one from the previous task.

The Sentiment Calculator actor is responsible for calculating the Sentiment Score. The sentiment score is calculated by getting the emotional score of each word in the tweet text and then calculating the mean of the emotional scores. The actor then prints the Sentiment Score.

```elixir
defp calculatePerUser(pid, tweet) do
    user = Map.get(tweet, "user") |> Map.get("screen_name")
    tweetToProcess = Map.get(tweet, "text") |> String.downcase() |> String.split(" ", trim: true)
    sum = Enum.map(tweetToProcess, fn x -> GenServer.call(pid, {:getscore, x}) end)
    score = Enum.sum(sum) / Enum.count(sum) |> Float.ceil(2)
    {user, score}
end

def handle_info({:tweet, {id, tweet}}, {name, min_time, max_time}) do
    :rand.uniform(max_time - min_time) + min_time |> Process.sleep
    {user, score} = calculatePerUser(WorkerPoolSupervisor.getSpecificWorker(:emotionreader), tweet)
    IO.inspect("Sentiment score for #{user}: #{score}")
    {:noreply, {name, min_time, max_time}}
end
```

**Main Task** -- Modify your current implementation of the Worker Pool to make it generic. A Generic Worker Pool should be able to create a pool of Workers specified at initialization. This modification should allow for the creation of an arbitrary number of Worker Pools. Depending on your current implementation, there might be a lot of things to change (or not).

The Generic Worker Pool Supervisor on initialization receives a specific number for the number of workers to be created and what type of worker to be created. The Generic Worker Pool Supervisor then creates the specified number of workers and adds them to the Generic Worker Pool.

```elixir
def init({id, type, min_time, max_time, num_workers, _name}) do
    children =
        for i <- 1..num_workers,
        do: %{
            id: :"#{id}#{i}",
            start: {type, :start_link, [:"#{id}#{i}", min_time, max_time]}
            }

    Supervisor.init(children, strategy: :one_for_one)
end
```

**Main Task** -- Create 3 Worker Pools that would process the tweet stream in parallel. Each Pool will have the respective workers from the previous task.

A new actor was created similar to Load Balancer called Generic Load Balancer. The Generic Load Balancer will check the number of workers inside every Generic Worker Pool and will sent the tweet data to all the 3 Generic Worker Pool workers based on round robin. The same way the panic messages will be handled by the Generic Load Balancer.

```elixir
#The initialization of the Generic Load Balancer
def getTheNumbers() do
    workers = WorkerPoolSupervisor.getWorkers()
    redacterPID = Enum.find(workers, fn {id, _pid} -> id == :workerpoolredacter end) |> elem(1)
    engagementPID = Enum.find(workers, fn {id, _pid} -> id == :workerpoolengagement end) |> elem(1)
    sentimentPID = Enum.find(workers, fn {id, _pid} -> id == :workerpoolsentiment end) |> elem(1)
    numRedacters = Supervisor.count_children(redacterPID) |> Map.get(:specs)
    numEngagement = Supervisor.count_children(engagementPID) |> Map.get(:specs)
    numSentiment = Supervisor.count_children(sentimentPID) |> Map.get(:specs)
    {numRedacters, numEngagement, numSentiment}
end

def start_link() do
    {numRedacters, numEngagement, numSentiment} = getTheNumbers()
    GenServer.start_link(__MODULE__, {numRedacters, numEngagement, numSentiment, 0}, name: __MODULE__)
end
```

**Flow Diagram of Week 4**

![Flow Diagram of Week 4](/laboratory2/diagrams/flowchart/flowchart-week4.png)

**Sequence Diagram of Week 4**
![Sequence Diagram of Week 4](/laboratory2/diagrams/sequence/sequence-week4.png)

# P1W5

**Minimal Task** -- Create an actor that would collect the redacted tweets from Workers and would print them in batches. Instead of printing the tweets, the Worker should now send them to the Batcher, which then prints them. The batch size should be parametrizable.

The Batcher actor receives the redacted tweets from the Redacter actor and stores them in a list. If the list reaches the size set at the initialization, the Batcher actor prints the list and clears the list. If the list does not reach the size set at the initialization, the Batcher actor will print them after a set time.

```elixir
def handle_info({:tweet, {id, tweet, sentiment, engagement}}, {batch_size, time_to_wait, messagesToPrintMap, currentTick}) do
    tick = currentTick
    tickNow = System.system_time(:millisecond)
    tickDiff = tickNow - tick
    messagesToPrint = "Tweet: #{tweet} | Sentiment: #{sentiment} | Engagement: #{engagement} | ID: #{id}"
    newMessagesToPrintMap = messagesToPrintMap ++ [messagesToPrint]
    {currentMap, ticks} = cond do
      length(newMessagesToPrintMap) == batch_size and tickDiff < time_to_wait ->
        IO.puts("Printing because full")
        IO.puts("")
        Enum.reduce(newMessagesToPrintMap, fn tweet, _ ->
          IO.inspect tweet
        end)
        ticksCalc = System.system_time(:millisecond)
        {[], ticksCalc}
      tickDiff >= time_to_wait ->
        IO.puts("Printing because timer")
        IO.puts("")
        Enum.reduce(newMessagesToPrintMap, fn tweet, _ ->
          IO.inspect tweet
        end)
        ticksCalc = System.system_time(:millisecond)
        {[], ticksCalc}
      true ->
        {newMessagesToPrintMap, tick}
    end
    {:noreply, {batch_size, time_to_wait, currentMap, ticks}}
end
```

**Main Task** -- Create an actor that would collect the redacted tweets, their Sentiment Scores and their Engagement Ratios and would aggregate them together. Instead of sending the tweets to the Batcher, the Worker should now send them to the Aggregator. It should then send the data to the Batcher if a matching set is found.

The Aggregator actor receives an redacted tweets, sentiment scores, and engagement ratios from the Redacter, Sentiment Calculator, and Engagement Calculator actors respectively. The Aggregator also receives an ID of the tweet which has been set inside the Generic Load Balancer actor. The Aggregator stores the received data in a list and then checks if there is a matching set of data (redacted tweet, sentiment score, and engagement ratio) for the same ID. If there is a matching set, the Aggregator sends the data to the Batcher actor. If there is no matching set, the Aggregator checks for the next ID or waits for the next set of data.

```elixir
def handle_info(:sendToBatcher, {min_time, max_time, aggregatorList}) do
    time = :rand.uniform(max_time - min_time) + min_time
    Process.sleep(time)
    aggregatorList = Enum.reject(aggregatorList, fn(x) ->
      if Enum.at(x, 1) == "tweet" do
        tweetToSend = Enum.at(x, 2)
        sentimentToSend = Enum.filter(aggregatorList, fn(y) -> Enum.at(y, 0) == Enum.at(x, 0) and Enum.at(y, 1) == "sentiment" end) |> Enum.fetch(0)
        engagementToSend = Enum.filter(aggregatorList, fn(y) -> Enum.at(y, 0) == Enum.at(x, 0) and Enum.at(y, 1) == "engagement" end) |> Enum.fetch(0)
        sentimentToSend = case sentimentToSend do
          {:ok, value} -> value
          _ -> nil
        end
        engagementToSend = case engagementToSend do
          {:ok, value} -> value
          _ -> nil
        end
        if sentimentToSend != nil and engagementToSend != nil do
          send(Batcher, {:tweet, {Enum.at(x, 0), tweetToSend, Enum.at(sentimentToSend, 2), Enum.at(engagementToSend, 2)}})
          true
        else
          false
        end
      else
        false
      end
    end)
    Process.send_after(self(), :sendToBatcher, time)
    {:noreply, {min_time, max_time, aggregatorList}}
end
```

**Main Task** -- Continue your Batcher actor. If, in a given time window, the Batcher does not receive enough data to print a batch, it should still print it. Of course, the actor should retain any existing behaviour. The time window should be parametrizable.

The Batcher checks when to print the tweets based on time by checking the current time and the time when the last batch was printed. If the time difference is greater than the set time, the Batcher prints the tweets. If the time difference is less than the set time, the Batcher waits for the time difference to be greater than the set time. The code can be seen in the Minimal Task section.

**Flow Diagram of Week 5**

![Flow Diagram of Week 5](/laboratory2/diagrams/flowchart/flowchart-week5.png)

**Sequence Diagram of Week 5**
![Sequence Diagram of Week 5](/laboratory2/diagrams/sequence/sequence-week5.png)

# Conclusion

The laboratory work was focused on creating an application that would receive tweet data from a stream and would process it. Every week the application had to be updated with additional functionalities and in some cases parts of code had to be refactored. In some parts the laboratory work was challenging and errors would appear unexpectedly and were hard to fix. Some bugs were so hard to get rid of that a week was lost even though week 6 looked like the easiest week to do.

In the end, I am proud of what the application ended up working like.

# Bibliography

1. [Elixir](https://elixir-lang.org/) -- Elixir official website.
2. [Elixir Documentation](https://hexdocs.pm/elixir/1.14.3/writing-documentation.html) -- Elixir documentation.
3. [HTTPoison](https://hexdocs.pm/httpoison/HTTPoison.html) -- HTTPoison documentation.
4. [Jason](https://hexdocs.pm/jason/Jason.html) -- Jason documentation.
5. [Supervisor](https://hexdocs.pm/elixir/1.14.3/Supervisor.html) -- Supervisor documentation.
6. [GenServer](https://hexdocs.pm/elixir/1.14.3/GenServer.html) -- GenServer documentation.
7. [Bad Word List](https://www.cs.cmu.edu/~biglou/resources/) -- Carnegie Mellon University Bad Word List of Luis von Ahn's Research Group.