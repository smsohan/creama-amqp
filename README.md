This is an exmaple of how to use Cloud Run Worker Pools to autoscale RabbitMQ consumers.

The directory stucture is as follows:

- Terraform:
  - Has the Terraform code to deploy a GCE VM with RabbitMQ running inside it. It exposes ports that are required to connect to RabbitMQ.
  - Has the code to bootstrap a queue and topic so that the producers and consumers can write to / read from it.
  - Has the Terraform code to deplot the Producer app as a Cloud Run Service
  - Has the Terraform code to deplot the Consumer app as a Cloud Run Worker Pool, starting with manual scaling of 1 instance
  - Configures the appropriate RabbitMQ hostname, port, user name, passowrd, and queue / topic names for everything. Password is stored in Google Cloud Secret Manager.
  - Uses Direct VPC to connect the Producer and Consumer app with the RabbitMQ VM. Deploys everything in a single region in a single GCP project.


- Producer: A Go web app. `POST /?qps=:qps&time=:time` produces `:qps` number of messages to RabbitMQ for `:time`. By default qps=10, and time=1m. Users can specify qps upto 1000, and time upto 1 day using units such as (xs, xm, 1h)
- Consumer: A Go console app that consumes messages from a RabbitMQ topic. The ENV var `QPS` controls how many messages are consumed per second by the consumer. By default it consumes 10qps if no env var is specified. The consumer keeps running indefinitely. Multiple consumers can be configured to read from the same RabbitMQ topic to load balance.