package main

import (
	"broker/event"
	"broker/logs"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/rpc"
	"os"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

var loggerGRPCAddress = os.Getenv("LOGGER_GRPC_URL")

// Payload is the type for data we push into RabbitMQ
type Payload struct {
	Name string `json:"name"`
	Data any    `json:"data"`
}

// RequestPayload is the type describing the data that we received
// from the user's browser. We embed a custom type for each of the
// possible payloads (mail, auth, and log).
type RequestPayload struct {
	Action string      `json:"action"`
	Mail   MailPayload `json:"mail,omitempty"`
	Auth   AuthPayload `json:"auth,omitempty"`
	Log    LogPayload  `json:"log,omitempty"`
}

// AuthPayload is the type embedded in RequestPayload for auth
type AuthPayload struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// LogPayload is the type embedded in RequestPayload for logging
type LogPayload struct {
	Name string `json:"name"`
	Data string `json:"data"`
}

// MailPayload is the type embedded in RequestPayload for sending email
type MailPayload struct {
	From    string `json:"from"`
	To      string `json:"to"`
	Subject string `json:"subject"`
	Message string `json:"message"`
}

// ONAT: Health check hanlder
func (app *Config) HealthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/plain")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Alive"))
}

type TestPayload struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// ONAT: Test handler for service cycle
func (app *Config) TestServiceCycle(w http.ResponseWriter, r *http.Request) {
	totalStart := time.Now()

	timings := make(map[string]string)

	var payload struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := app.readJSON(w, r, &payload); err != nil {
		app.errorJSON(w, err)
		return
	}

	start := time.Now()

	authServiceURL := os.Getenv("AUTH_SERVICE_URL")
	if authServiceURL == "" {
		authServiceURL = "http://authentication-service"
	}

	authPayload := struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}{
		Email:    payload.Email,
		Password: payload.Password,
	}
	jsonData, _ := json.Marshal(authPayload)

	request, err := http.NewRequest("POST", authServiceURL+"/authenticate", bytes.NewBuffer(jsonData))
	request.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		app.errorJSON(w, err)
		return
	}
	response.Body.Close()

	if response.StatusCode != http.StatusAccepted {
		app.errorJSON(w, errors.New("auth failed"))
		return
	}

	timings["1_Auth_Service"] = time.Since(start).String()

	start = time.Now()

	rpcClient, err := rpc.Dial("tcp", "logger-service:5001")
	if err != nil {
		app.errorJSON(w, err)
		return
	}

	rpcPayload := RPCPayload{
		Name: "chain_test",
		Data: fmt.Sprintf("User %s authenticated", payload.Email),
	}

	var rpcResult string
	err = rpcClient.Call("RPCServer.LogInfo", rpcPayload, &rpcResult)
	if err != nil {
		app.errorJSON(w, err)
		return
	}

	timings["2_Logger_Service_RPC"] = time.Since(start).String()

	start = time.Now()

	mailURL := os.Getenv("MAIL_FUNCTION_URL")

	mailPayload := MailPayload{
		To:      payload.Email,
		Subject: "Load Test",
		Message: "Testing Latency",
	}
	mailJson, _ := json.Marshal(mailPayload)

	mailRequest, _ := http.NewRequest("POST", mailURL, bytes.NewBuffer(mailJson))
	mailRequest.Header.Set("Content-Type", "application/json")

	mailClient := &http.Client{}
	mailResp, err := mailClient.Do(mailRequest)
	if err != nil {
		app.errorJSON(w, err)
		return
	}
	mailResp.Body.Close()

	timings["3_Mail_Function_HTTP"] = time.Since(start).String()

	totalDuration := time.Since(totalStart)
	timings["4_Total_Round_Trip"] = totalDuration.String()

	responsePayload := jsonResponse{
		Error:   false,
		Message: "Sequential Test Complete",
		Data:    timings,
	}

	app.writeJSON(w, http.StatusAccepted, responsePayload)
}

// Broker is a simple test handler for the broker
func (app *Config) Broker(w http.ResponseWriter, r *http.Request) {
	logRequestPayload := LogPayload{
		Name: "broker_hit",
		Data: r.RemoteAddr,
	}

	err := event.PushToPubSub(os.Getenv("GOOGLE_CLOUD_PROJECT"), "log-topic", logRequestPayload)
	if err != nil {
		log.Printf("Failed to push to Pub/Sub: %v", err)
	}

	var logResponsePayload jsonResponse
	logResponsePayload.Message = "Received request"

	out, _ := json.MarshalIndent(logResponsePayload, "", "\t")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusAccepted)
	_, _ = w.Write(out)
}

// HandleSubmission handles a JSON payload that describes an action to take,
// processes it, and sends it where it needs to go
func (app *Config) HandleSubmission(w http.ResponseWriter, r *http.Request) {
	var requestPayload RequestPayload

	err := app.readJSON(w, r, &requestPayload)
	if err != nil {
		_ = app.errorJSON(w, err)
		return
	}

	switch requestPayload.Action {
	case "mail":
		app.sendMail(w, requestPayload.Mail)
	case "auth":
		app.authenticate(w, requestPayload.Auth)
	case "log":
		app.logItemViaRPC(w, requestPayload.Log)
	default:
		_ = app.errorJSON(w, errors.New("unknown action"))
	}
}

// sendMail sends an email through the mail-service. It receives a json payload
// of type requestPayload, with MailPayload embedded.
func (app *Config) sendMail(w http.ResponseWriter, msg MailPayload) {
	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	topicID := "mail-topic"

	// 2. Push to Pub/Sub (This triggers the Cloud Function)
	err := event.PushToPubSub(projectID, topicID, msg)
	if err != nil {
		_ = app.errorJSON(w, err, http.StatusBadRequest)
		return
	}

	// 3. Respond to user
	var payload jsonResponse
	payload.Error = false
	payload.Message = "Mail request sent to Pub/Sub for " + msg.To

	out, _ := json.MarshalIndent(payload, "", "\t")
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusAccepted)
	_, _ = w.Write(out)
}

// authenticate tries to log a user in through the authentication-service. It receives a json payload
// of type requestPayload, with AuthPayload embedded.
func (app *Config) authenticate(w http.ResponseWriter, a AuthPayload) {
	// ONAT: The url for the authentication service
	authServiceURL := os.Getenv("AUTH_SERVICE_URL")
	if authServiceURL == "" {
		authServiceURL = "http://authentication-service"
	}

	// create json we'll send to the authentication-service
	jsonData, _ := json.MarshalIndent(a, "", "\t")

	// call the authentication-service; we need a request, so let's build one, and populate
	// its body with the jsonData we just created. First we get the correct url for our
	// auth service from our service map.
	//authServiceURL := fmt.Sprintf("http://%s/authenticate", app.GetServiceURL("auth"))
	// authServiceURL := fmt.Sprintf("http://%s/authenticate", "authentication-service")

	// now build the request and set header
	// ONAT: Add hard coded authenticate endpoint to the url
	request, err := http.NewRequest("POST", authServiceURL+"/authenticate", bytes.NewBuffer(jsonData))
	request.Header.Set("Content-Type", "application/json")

	// call the service
	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		_ = app.errorJSON(w, err, http.StatusBadRequest)
		return
	}
	defer response.Body.Close()

	// make sure we get back the right status code
	if response.StatusCode == http.StatusUnauthorized {
		_ = app.errorJSON(w, errors.New("invalid credentials"), http.StatusUnauthorized)
		return
	} else if response.StatusCode != http.StatusAccepted {
		_ = app.errorJSON(w, errors.New("error calling auth service"), http.StatusBadRequest)
		return
	}

	// create variable we'll read the response.Body from the authentication-service into
	var jsonFromService jsonResponse

	// decode the json we get from the authentication-service into our variable
	err = json.NewDecoder(response.Body).Decode(&jsonFromService)
	if err != nil {
		_ = app.errorJSON(w, err, http.StatusBadRequest)
		return
	}

	// did not authenticate successfully
	if jsonFromService.Error {
		// log it
		_ = app.pushToQueue("authentication", fmt.Sprintf("invalid login for %s", a.Email))
		// send error JSON back
		_ = app.errorJSON(w, err, http.StatusUnauthorized)
		return
	}

	// valid login, so send it to the logger service via RabbitMQ
	_ = app.pushToQueue("authentication", fmt.Sprintf("valid login for %s", a.Email))

	// send json back to our end user, with user info embedded
	var payload jsonResponse
	payload.Error = false
	payload.Message = "Authenticated!"
	payload.Data = jsonFromService.Data

	_ = app.writeJSON(w, http.StatusAccepted, payload)
}

type RPCPayload struct {
	Name string
	Data string
}

func (app *Config) logItemViaRPC(w http.ResponseWriter, l LogPayload) {
	client, err := rpc.Dial("tcp", "logger-service:5001")
	if err != nil {
		app.errorJSON(w, err)
		return
	}

	rpcPayload := RPCPayload{
		Name: l.Name,
		Data: l.Data,
	}

	var result string
	err = client.Call("RPCServer.LogInfo", rpcPayload, &result)
	if err != nil {
		app.errorJSON(w, err)
		return
	}

	payload := jsonResponse{
		Error:   false,
		Message: result,
	}

	app.writeJSON(w, http.StatusAccepted, payload)
}

// pushToQueue pushes a message into RabbitMQ
func (app *Config) pushToQueue(name, msg string) error {
	emitter, err := event.NewEventEmitter(app.Rabbit)
	if err != nil {
		log.Println(err)
		return err
	}

	payload := Payload{
		Name: name,
		Data: msg,
	}

	j, _ := json.MarshalIndent(&payload, "", "    ")
	err = emitter.Push(string(j), "log.INFO")
	if err != nil {
		return err
	}
	return nil
}

// LogViaGRPC takes a JSON payload and logs it using gRPC as the transport
func (app *Config) LogViaGRPC(w http.ResponseWriter, r *http.Request) {
	var requestPayload RequestPayload

	err := app.readJSON(w, r, &requestPayload)
	if err != nil {
		_ = app.errorJSON(w, err)
		return
	}

	conn, err := grpc.Dial(loggerGRPCAddress, grpc.WithTransportCredentials(insecure.NewCredentials()), grpc.WithBlock())
	if err != nil {
		_ = app.errorJSON(w, err)
		return
	}
	defer conn.Close()

	c := logs.NewLogServiceClient(conn)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, err = c.WriteLog(ctx, &logs.LogRequest{
		LogEntry: &logs.Log{
			Name: requestPayload.Log.Name,
			Data: requestPayload.Log.Data,
		},
	})
	if err != nil {
		_ = app.errorJSON(w, err)
		return
	}

	var payload jsonResponse
	payload.Error = false
	payload.Message = "logged"

	_ = app.writeJSON(w, http.StatusAccepted, payload)
}
