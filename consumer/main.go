package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/streadway/amqp"
)

func main() {
	host := os.Getenv("RABBITMQ_HOST")
	port := os.Getenv("RABBITMQ_PORT")
	user := os.Getenv("RABBITMQ_USER")
	password := os.Getenv("RABBITMQ_PASSWORD")
	queueName := os.Getenv("RABBITMQ_QUEUE")

	qps, err := getIntEnvParam("QPS", 10)
	if err != nil {
		log.Fatalf("Invalid 'QPS' parameter. Must be an integer.")
	}

	connStr := fmt.Sprintf("amqp://%s:%s@%s:%s/", user, password, host, port)

	var conn *amqp.Connection
	for i := 0; i < 15; i++ { // 15 retries * 2 seconds/retry = 30 seconds
		log.Printf("Attempting to connect to RabbitMQ... (Attempt %d/15)", i+1)
		conn, err = amqp.Dial(connStr)
		if err == nil {
			log.Println("Successfully connected to RabbitMQ.")
			break
		}
		log.Printf("Failed to connect to RabbitMQ: %v. Retrying in 2 seconds...", err)
		time.Sleep(2 * time.Second)
	}

	if conn == nil {
		log.Fatalf("Failed to connect to RabbitMQ after multiple retries.")
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		log.Fatalf("Failed to open a channel: %v", err)
	}
	defer ch.Close()

	q, err := ch.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		log.Fatalf("Failed to declare a queue: %v", err)
	}

	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		true,   // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	if err != nil {
		log.Fatalf("Failed to register a consumer: %v", err)
	}

	forever := make(chan bool)

	go func() {
		ticker := time.NewTicker(time.Second / time.Duration(qps))
		defer ticker.Stop()

		for d := range msgs {
			<-ticker.C
			log.Printf("Received a message: %s", d.Body)
		}
	}()

	log.Printf(" [*] Waiting for messages at %d QPS. To exit press CTRL+C", qps)
	<-forever
}

func getIntEnvParam(key string, defaultValue int) (int, error) {
	valStr := os.Getenv(key)
	if valStr == "" {
		return defaultValue, nil
	}
	return strconv.Atoi(valStr)
}
