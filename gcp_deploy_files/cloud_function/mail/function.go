package p

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
)

func init() {
	functions.CloudEvent("ProcessMail", ProcessMail)
}

// MailPayload matches the structure sent by broker-service
type MailPayload struct {
	From    string `json:"from"`
	To      string `json:"to"`
	Subject string `json:"subject"`
	Message string `json:"message"`
}

type MessagePublishedData struct {
	Message PubSubMessage
}

type PubSubMessage struct {
	Data []byte `json:"data"`
}

func ProcessMail(ctx context.Context, e event.Event) error {
	var msg MessagePublishedData
	if err := e.DataAs(&msg); err != nil {
		return fmt.Errorf("event.DataAs: %v", err)
	}

	log.Printf("Cloud Function received mail request")

	var mailReq MailPayload
	err := json.Unmarshal(msg.Message.Data, &mailReq)
	if err != nil {
		return fmt.Errorf("json.Unmarshal: %v", err)
	}

	// Helper to get env vars with fallback
	getEnv := func(key, fallback string) string {
		if value, ok := os.LookupEnv(key); ok {
			return value
		}
		return fallback
	}

	port, _ := strconv.Atoi(getEnv("MAIL_PORT", "1025")) // Default to MailHog port if not set

	mailer := Mail{
		Domain:      getEnv("MAIL_DOMAIN", "localhost"),
		Host:        getEnv("MAIL_HOST", "mailhog"), // This likely needs to be an external IP or SMTP service in GCP
		Port:        port,
		Username:    getEnv("MAIL_USERNAME", ""),
		Password:    getEnv("MAIL_PASSWORD", ""),
		Encryption:  getEnv("MAIL_ENCRYPTION", "none"),
		FromAddress: getEnv("FROM_ADDRESS", "john.smith@example.com"),
		FromName:    getEnv("FROM_NAME", "John Smith"),
	}

	emailMsg := Message{
		From:    mailReq.From,
		To:      mailReq.To,
		Subject: mailReq.Subject,
		Data:    mailReq.Message,
	}

	err = mailer.SendSMTPMessage(emailMsg)
	if err != nil {
		log.Printf("Failed to send email: %v", err)
		return err
	}

	log.Printf("Email sent successfully to %s", mailReq.To)
	return nil
}
