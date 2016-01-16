require! {
    \./config
    \express
    \morgan
    \body-parser
}

app = express!
    ..use morgan \dev
    ..use body-parser.json!
    ..use body-parser.urlencoded extended:false

app.all \/, (req, res) ->
    a = req.{query, body}
    res.send a
    console.log req.headers

app.listen config.port, ->
    console.log "Listen on #{config.port}..."
