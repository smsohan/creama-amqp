# Consumer Service

This service is a Go console application that consumes messages from a RabbitMQ queue. It is deployed as a Cloud Run Worker Pool.

## Environment Variables

The following environment variables are used by the Consumer service to configure its behavior and connection settings.

| Variable          | Description                                                      | Default |
| :---------------- | :--------------------------------------------------------------- | :------ |
| `QPS`             | The number of messages to consume per second.                    | `10`    |
| `RABBITMQ_HOST`   | The hostname or IP address of the RabbitMQ server.               | (none)  |
| `RABBITMQ_PORT`   | The port of the RabbitMQ server.                                 | (none)  |
| `RABBITMQU_USER`  | The username for connecting to RabbitMQ.                         | (none)  |
| `RABBITMQ_PASSWORD` | The password for connecting to RabbitMQ.                         | (none)  |
| `RABBITMQ_QUEUE`  | The name of the RabbitMQ queue from which messages will be consumed. | (none)  |
