package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/rabbitmq/amqp091-go"
)

func main() {
	http.HandleFunc("/", handler)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Producer listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST method is accepted", http.StatusMethodNotAllowed)
		return
	}

	qps, err := getIntQueryParam(r, "qps", 10)
	if err != nil || qps > 1000 {
		http.Error(w, "Invalid 'qps' parameter. Must be an integer up to 1000.", http.StatusBadRequest)
		return
	}

	duration, err := getDurationQueryParam(r, "time", "1m")
	if err != nil || duration.Hours() > 24 {
		http.Error(w, "Invalid 'time' parameter. Max duration is 24h.", http.StatusBadRequest)
		return
	}

	go produceMessages(qps, duration)

	fmt.Fprintf(w, "Started producing %d messages per second for %v", qps, duration)
}

func produceMessages(qps int, duration time.Duration) {
	host := os.Getenv("RABBITMQ_HOST")
	port := os.Getenv("RABBITMQ_PORT")
	user := os.Getenv("RABBITMQ_USER")
	password := os.Getenv("RABBITMQ_PASSWORD")
	queueName := os.Getenv("RABBITMQ_QUEUE")

	connStr := fmt.Sprintf("amqp://%s:%s@%s:%s/", user, password, host, port)
	conn, err := amqp091.Dial(connStr)
	if err != nil {
		log.Printf("Failed to connect to RabbitMQ: %s", err)
		return
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		log.Printf("Failed to open a channel: %s", err)
		return
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
		log.Printf("Failed to declare a queue: %s", err)
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), duration)
	defer cancel()

	ticker := time.NewTicker(time.Second / time.Duration(qps))
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			log.Println("Finished producing messages.")
			return
		case <-ticker.C:
			body := fmt.Sprintf("Message sent at %s", time.Now().Format(time.RFC3339Nano))
			err := ch.PublishWithContext(ctx,
				"",     // exchange
				q.Name, // routing key
				false,  // mandatory
				false,  // immediate
				amqp091.Publishing{
					ContentType: "text/plain",
					Body:        []byte(body),
				})
			if err != nil {
				log.Printf("Failed to publish a message: %s", err)
			} else {
				log.Printf("Sent: %s", body)
			}
		}
	}
}

func getIntQueryParam(r *http.Request, key string, defaultValue int) (int, error) {
	valStr := r.URL.Query().Get(key)
	if valStr == "" {
		return defaultValue, nil
	}
	return strconv.Atoi(valStr)
}

func getDurationQueryParam(r *http.Request, key string, defaultValue string) (time.Duration, error) {
	valStr := r.URL.Query().Get(key)
	if valStr == "" {
		valStr = defaultValue
	}
	return time.ParseDuration(valStr)
}
