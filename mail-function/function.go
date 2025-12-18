package function

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

func init() {
	functions.HTTP("SendMail", sendMailHTTP)
}

type MailPayload struct {
	To      string `json:"to"`
	Subject string `json:"subject"`
	Message string `json:"message"`
}

func sendMailHTTP(w http.ResponseWriter, r *http.Request) {
	var payload MailPayload
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		log.Printf("❌ Failed to decode JSON: %v", err)
		http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
		return
	}

	minDelay := 250
	maxDelay := 1000

	duration := time.Duration(rand.Intn(maxDelay-minDelay)+minDelay) * time.Millisecond

	time.Sleep(duration)

	log.Printf("✅ SIMULATION: Email Sent (Latency: %v)", duration)
	log.Printf("   To: %s | Subject: %s", payload.To, payload.Subject)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	response := fmt.Sprintf(`{"status": "sent", "simulation": true, "latency_ms": %d}`, duration.Milliseconds())
	fmt.Fprint(w, response)
}
