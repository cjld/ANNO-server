global.inElectron = false

require! {
    \./config
    \express
    \./api : api-app
    \./middlewares
    \http
    \socket.io : socket-io
    \./socket/socket
}

app = express!
    ..use middlewares
    ..use express.static \public

require! {
    \react : React
    \react-dom/server : ReactDOM
    \react-router
    \./app-dest/routes
    \swig
}

app.use \/api, api-app

# server rendering
app.use (req, res) ->
    react-router.match {routes:routes, location:req.url},
        (err, redir-loc, render-props) ->
            if err then
                res.status 500 .send err.message
            else if redir-loc then
                res.status 302 .redirect redir-loc.pathname+redir-loc.search
            else if render-props then
                #console.log 'args: ', &
                html = ReactDOM.render-to-string React.create-element react-router.Router-context, render-props
                page = swig.renderFile \views/index.html, html:html
                res.status 200 .send page
            else
                res.status 404 .send 'Page not found.'

server = http.Server(app)
io = socket-io(server)

server-opt = port:config.port
if not config.listen-all
    server-opt.host = \localhost
server.listen server-opt, ->
    console.log "Listen on #{config.port}..."

# set up socket io
socket io
