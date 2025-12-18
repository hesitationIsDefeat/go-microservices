package main

import (
	"fmt"
	"log"
	"net/http"

	amqp "github.com/rabbitmq/amqp091-go"
	clientv3 "go.etcd.io/etcd/client/v3"
)

// webPort the port that we listen on for api calls
const webPort = "80"

// Config is the type we'll use as a receiver to share application
// configuration around our app.
type Config struct {
	Rabbit         *amqp.Connection
	Etcd           *clientv3.Client
	LogServiceURLs map[string]string
	//MailServiceURLs map[string]string
	//AuthServiceURLs map[string]string
}

func main() {
	// don't continue until etcd is ready
	//etcConn, err := connectToEtcd()
	//if err != nil {
	//	fmt.Println(err)
	//	os.Exit(1)
	//}
	//defer etcConn.Close()

	app := Config{}

	// get service urls
	//app.getServiceURLs()

	// watch service urls
	//go app.watchEtcd()

	log.Println("Starting broker service on port", webPort)

	// define the http server
	srv := &http.Server{
		Addr:    fmt.Sprintf(":%s", webPort),
		Handler: app.routes(),
	}

	// start the server
	var err = srv.ListenAndServe()
	if err != nil {
		log.Panic(err)
	}
}
