package main // <--- Keep this as package main

import (
	"context"
	"encoding/json"
	"log"
	"log-service/data"
	"os"

	pubsub "cloud.google.com/go/pubsub/v2"
)

type LogPayload struct {
	Name string `json:"name"`
	Data string `json:"data"`
}

// ONAT: listenToPubSub listens for messages from a Pub/Sub subscription
func (app *Config) listenToPubSub() {
	ctx := context.Background()

	client, err := pubsub.NewClient(ctx, os.Getenv("GOOGLE_CLOUD_PROJECT"))
	if err != nil {
		log.Panicf("Could not create pubsub client: %v", err)
	}
	defer client.Close()

	subscriber := client.Subscriber("logs-subscription")

	log.Println("Listening for Pub/Sub messages...")

	err = subscriber.Receive(ctx, func(ctx context.Context, msg *pubsub.Message) {
		var payload LogPayload

		if err := json.Unmarshal(msg.Data, &payload); err != nil {
			log.Printf("Error unmarshalling log: %v", err)
			msg.Ack() // Ack bad data so it doesn't get stuck
			return
		}

		// ONAT: map LogPayload to data.LogEntry
		entry := data.LogEntry{
			Name: payload.Name,
			Data: payload.Data,
		}

		err := app.Models.LogEntry.Insert(entry)
		if err != nil {
			log.Printf("Error writing to mongo: %v", err)
			msg.Nack()
			return
		}

		msg.Ack()
	})

	if err != nil {
		log.Printf("PubSub Receive error: %v", err)
	}
}
