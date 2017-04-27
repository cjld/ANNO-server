config =
    time-evaluate: false
    port: 9200
    secret: \my-secret
    database: \mongodb://localhost:27017/pro5
    paint-bin: "./../build-worker/anno_worker" # to the worker position
    paint-bin-args: ['server', '-platform', 'offscreen']
    page-size: 20
    prefetch-size: 20
    listen-all: true
    upload-limit: 100000
    server-ip: "localhost"
    image-server-port: 9201
    image-server-dir: "./../data/pyload/"
    upload-path: "uploads/"
    auth:
        google:
            clientID: "your clientID"
            clientSecret: "your clientSecret"
            callbackURL: "/api/auth/google/callback"
    email:
        config:
            user:    "your email"
            password:"your password"
            host:    "email host"
            port:    465
            ssl:     true
        template:
           text:    "",
           from:    "Your name<yourEmail@email.com>",
           to:      "",
           subject: "Password reset"

config.image-server-url = "http://#{config.server-ip}:#{config.image-server-port}/"

module.exports = config
