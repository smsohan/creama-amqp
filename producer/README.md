# Producer Service

This service is a Go web application that produces messages to a RabbitMQ queue. It is deployed as a Cloud Run Service.

## Endpoints

### `POST /`

Produces messages to the configured RabbitMQ queue.

**Query Parameters:**

| Parameter | Description                                                                                             | Default | Max Value |
| :-------- | :------------------------------------------------------------------------------------------------------ | :------ | :-------- |
| `qps`     | The number of messages to produce per second.                                                           | `10`    | `1000`    |
| `time`    | The duration for which messages should be produced. Supported units include `s`, `m`, `h`, `d`. | `1m`    | `24h`     |

**Example cURL Command:**

```bash
curl -X POST "http://[PRODUCER_SERVICE_URL]/?qps=100&time=5m"
```

Replace `[PRODUCER_SERVICE_URL]` with the actual URL of your deployed Producer service.

## Environment Variables

The following environment variables are used by the Producer service:

| Variable          | Description                                                               | Default  |
| :---------------- | :------------------------------------------------------------------------ | :------- |
| `PORT`            | The port on which the service listens for incoming requests.              | `8080`   |
| `RABBITMQ_HOST`   | The hostname or IP address of the RabbitMQ server.                        | (none)   |
| `RABBITMQ_PORT`   | The port of the RabbitMQ server.                                          | (none)   |
| `RABBITMQ_USER`   | The username for connecting to RabbitMQ.                                  | (none)   |
| `RABBITMQ_PASSWORD` | The password for connecting to RabbitMQ.                                  | (none)   |
| `RABBITMQ_QUEUE`  | The name of the RabbitMQ queue to which messages will be published.       | (none)   |