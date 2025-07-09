## Blinq

![Performance: 1165 RPS @ 200 Concurrency](https://img.shields.io/badge/performance-1165%20RPS%20%40%20200c-brightgreen?style=for-the-badge&logo=ruby)

A lightweight and scalable backend service built with **Sinatra** and **RabbitMQ** for creating posts and handling votes (upvotes/downvotes) efficiently.

### Built With
- [Sinatra](http://sinatrarb.com/)
- [RabbitMQ](http://www.rabbitmq.com/)

Plus *some* of packages, a complete list of which is at [/master/Gemfile](https://github.com/michelsazevedo/blinq/blob/master/Gemfile).

### Instructions

#### Install with Docker
[Docker](www.docker.com) is an open platform for developers and sysadmins to build, ship, and run distributed applications, whether on laptops, data center VMs, or the cloud.

If you haven't used Docker before, it would be good idea to read this article first: Install [Docker Engine](https://docs.docker.com/engine/installation/)

Install [Docker](https://www.docker.com/what-docker) and then [Docker Compose](https://docs.docker.com/compose/), and then follow the steps below:

1. Run `docker compose build --no-cache` to build the image for the project.

2. Setup database:
    `docker-compose run --rm test rake db:setup`

3. Setup github webhook secret by updating the `.env` file with the proper secret.

4. Finally, start your local server with `docker compose up web` and blinq should be up and running on your localhost!

5. Aaaaand, you can run the automated tests suite running a `docker compose run --rm test` with no other parameters!

### Example Requests

#### Get Recent Posts
```bash
curl -X GET http://localhost:3000/posts -H "Content-Type: application/json" \
```

#### Create Post
```bash
curl -X POST http://localhost:3000/posts \
  -H "Content-Type: application/json" \
  -d '{"title": "Sample Post", "content": "Sample Content", "user_id": 42}'
```
#### Vote on Post
```bash
curl -X POST http://localhost:3000/posts/42/vote \
  -H "Content-Type: application/json" \
  -d '{"post_id": 1, "vote_type": "upvote", "user_id": 42}'
```

### References
- [Caching Strategy: Cache-Aside Pattern](https://www.enjoyalgorithms.com/blog/cache-aside-caching-strategy)
- [Understanding Puma Workers, Threads, and Database Connection Pooling](https://hewi.blog/scaling-rails-understanding-puma-workers-threads-and-database-connection-pooling)
- [Optimizing Configurations](https://developers.chatwoot.com/self-hosted/deployment/performance/optimizing-configurations)
- [RabbitMQ Best Practice for High Performance (High Throughput)](https://www.cloudamqp.com/blog/part2-rabbitmq-best-practice-for-high-performance.html)
- [Designing High-Performance APIs](https://dzone.com/articles/designing-high-performance-apis)
- [Mastering API Throughput: 8 Key Strategies for Optimal Performance](https://zuplo.com/blog/2025/02/21/mastering-api-throughput)
- [Strategies for Scaling Databases: A Comprehensive Guide](https://medium.com/@anil.goyal0057/strategies-for-scaling-databases-a-comprehensive-guide-b69cda7df1d3)
- [Scaling Up Software: Redis Buffering and Batch Processing for High-Throughput Applications](https://medium.com/@oey.joshua/scaling-up-software-redis-buffering-and-batch-processing-for-high-throughput-applications-64bb16a2d832)
- [Redis: Pipelining, Transactions and Lua Scripts](https://rafaeleyng.github.io/redis-pipelining-transactions-and-lua-scripts)
- [Harnessing the Power of Redis Cache Lua Scripting](https://mvineetsharma.medium.com/harnessing-the-power-of-redis-cache-lua-scripting-15ed8dbf87b1)

## License
Copyright © 2025

