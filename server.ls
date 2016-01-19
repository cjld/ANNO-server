require! {
    \./config
    \express
    \./middlewares
}

app = express!
    ..use middlewares
    ..use express.static \public

app.get \/, (req, res) ->
    a = req.{query, body}
    res.send a
    console.log req.headers

app.listen config.port, ->
    console.log "Listen on #{config.port}..."
