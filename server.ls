require! {
    \./config
    \express
    \./middlewares
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

app.use (req, res) ->
    react-router.match {routes:routes, location:req.url},
        (err, redir-loc, render-props) ->
            if err then
                res.status 500 .send err.message
            else if redir-loc then
                res.status 302 .redirect redir-loc.pathname+redir-loc.search
            else if render-props then
                #console.log 'args: ', &
                html = ReactDOM.render-to-string React.create-element react-router.Routing-context, render-props
                console.log html
                page = swig.renderFile \views/index.html, html:html
                res.status 200 .send page
            else
                res.status 404 .send 'Page not found.'

app.listen config.port, ->
    console.log "Listen on #{config.port}..."
