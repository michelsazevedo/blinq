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
    `docker-compose run --rm test bundle exec rake db:migrate`

3. Setup github webhook secret by updating the `.env` file with the proper secret.

4. Finally, start your local server with `docker compose up web` and blinq should be up and running on your localhost!

5. Aaaaand, you can run the automated tests suite running a `docker compose run --rm test` with no other parameters!

## License
Copyright © 2025

