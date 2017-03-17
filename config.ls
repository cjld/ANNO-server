export
    port: 9200
    secret: \my-secret
    database: \mongodb://localhost:27017/pro5
    paint-bin: "./../build-sumsang-Desktop-Release/sumsang"
    paint-bin-args: ['server', '-platform', 'offscreen']
    page-size: 20
    listen-all: true
    upload-limit: 100000
    image-server-url: "http://166.111.71.64:9201/"
    image-server-dir: "./../data/pyload/"
    upload-path: "uploads/"
