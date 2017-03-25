config =
    time-evaluate: false
    port: 9200
    secret: \my-secret
    database: \mongodb://localhost:27017/pro5
    paint-bin: "./../build-worker/anno_worker"
    paint-bin-args: ['server', '-platform', 'offscreen']
    page-size: 20
    prefetch-size: 20
    listen-all: true
    upload-limit: 100000
    server-ip: "114.215.47.86"
    image-server-port: 9201
    image-server-dir: "./../data/pyload/"
    upload-path: "uploads/"

config.image-server-url = "http://#{config.server-ip}:#{config.image-server-port}/"

module.exports = config
