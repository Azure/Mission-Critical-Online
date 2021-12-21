# Scaling and Load Testing

*Identify scale points – what is going to scale, what doesn't make sense to scale?*

## Scale Points

Based on the application architecture, these are the identified scaling points (i.e. components where changing of capacity will be relevant to the overall system performance):

- AKS nodes
  - Number of nodes
  - Size of nodes
- GameService Pod
  - CPU
  - RAM
  - Number of pods
- ResultWorker Pod
  - CPU
  - RAM
  - Number of pods (maximum 32, number of EH partitions)
- IngressController Pod
  - CPU
  - RAM
  - Number of pods
- Event Hub Throughput Units
- Cosmos DB Request Units
  - Autoscaling (min/max)

## Capacity Model Creation and Testing Approach

To create the capacity model, we need to calculate the relationships between the different components. For example:

*X number of user requests to GetGames() require Y number of GameService pods and Z Cosmos DB RUs.*

To derive those findings, we can follow this approach:

- Pick one component to test e.g. the GameService pod.
- Scale out all other components to high levels to eliminate their effect on capacity e.g. provision Cosmos DB Request Units (RU) much higher than it will reasonably hit during testing.

### GameService Pod

- Scale the GameService pod to only 1 instance and turn off auto scaling.
- Select reasonable CPU and RAM resource allocations for the pod.
- Start the load test and observe the requests per second that this one instance can achieve.
- Gradually start adding more instances in a linear fashion.

This will enable you to confidently demonstrate how much user load a single instance can serve.

Repeat this experiment for CPU and RAM resources, but do not scale out beyond one instance of the pod for this test.

### Ingress Controller pod

Follow the same steps as used above for the GameService.

### ResultWorker Pod

For the ResultWorker, the maximum number of instances is limited by the number of Event Hub partitions (i.e. 32). At that scale each instance will process exactly one partition and therefore for this component the CPU and RAM allocations are more useful to optimize.

Another factor for the ResultWorker is to decide whether to scale it to the maximum achievable performance to speed up queue processing or whether to accept a delayed processing to reduce the number of Cosmos DB RUs.

### Cosmos DB RUs

Although this is a straight forward scale point in that you can always get more RU, however, it is also the easiest way to overspend. To determine optimum level, we first need to list all the operations against Cosmos DB:

- Get a single game by ID.
- List all games (with limit=N, default 100).
- List all games for a user.
- Add new game result (which includes to update the profiles of the participating players).
- Generate new leaderboard.
- Get latest leaderboard.
- Get leaderboard by ID.
- Delete game.
- Delete user.

Each of these queries has a RU cost associated with it which should be constant given that input, output and database size doesn't change. The RU cost depends on the size of the returned/created documents and indexes that might exist. It was also observed that the cost increased when more documents were added to the database.

For AlwaysOn the cost for GetGames operations is not expected to vary much between 1 and 100 documents returned (which is the maximum). Also, the cost to create a game result should be almost static.

By default Cosmos DB indexes all document properties. It’s possible to set `indexing_policy.excluded_path` and `indexing_policy. Within Terraform use included_path` to define which properties should/ shouldnt be indexed.

## Load Tests

> Load tests were not run with the rebranded version yet.

### Load Pattern

As the AlwaysOn game example is an artificial scenario, there is not a realistic usage pattern based on a real user load. As such a simple weight-based pattern is used where each test user executes the operations listed below (the higher the weight, the more often an operation is executed during a load test):

1. Play a game against the AI (WRITE) - weight 10
1. Post a game result for two players (WRITE) - weight 10
1. Get Player Profile (READ) - weight 2
1. List Game Results for Player (READ) - weight 1

### Test 1

Scenario Settings:

- Single AKS Cluster
- Cosmos DB maximum auto-scale: 4k-40K RU
- Event Hub 10 Throughput Units
- Single GameService pod

Pod configuration:

- CPU 1 core
- 1 GB RAM
- Request limits: 1000, 1 GB

Scale results:

- 1 pod = 270 RPS
- 10 pods = 2300 RPS
- 20 pods = 3800 RPS

With 3 GameService pods ingress scale 6-20

Resource: Cosmos DB SDK High CPU troubleshooting: https://docs.microsoft.com/azure/cosmos-db/troubleshoot-dot-net-sdk-request-timeout#troubleshooting-steps

### Test 2

**1. Scale out/ Scale in test**

Start with:

- GameService – 2 pods
- ResultWorker – 2 pods
- 500 users, 100 ramp up

Result:  **300 RPS**

Scale to 4 pods

- no client failures
- 2 dependency errors
- load is distributed evenly
- CPU around 20 %

Scale to 3 pods

- no errors, CPU around 35 %

Scale to 2 pods

- no errors, CPU around 50 %

**2. Test with auth**

Start with:

- GameService – 1 pod
- ResultWorker – 2 pods
- 400 users, 100 ramp up =

Result: **230 RPS**, 90% CPU

- 300 users = **180 RPS**, 60% CPU (spikes ~80%)

Scale:

- GameService – 2 pods
- ResultWorker – 2 pods
- 500 users, 100 ramp up

Result: **290-295 RPS**, CPU 52%/70%

- 600 users, 100 ramp up

Result: **350 RPS**, CPU 74%/80%

AAD keys are clearly cached on the instance – not reaching to B2C every time.

**3. Maximum scale**

Cosmos DB is the limiting factor hitting RUs limits before any other scale point becomes a bottleneck.

CosmosDB RU scale: 40 000 RUs

- GameService – HPA, up to 20
- ResultWorker – HPA, up to 8

**Outstanding questions:**

- [ ] Under load, why are some pods maxed on CPU while others run on comfortable 50%?
- [ ] How much is 100 RPS? etc.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)