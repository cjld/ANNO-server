require! {
    \react : React
    \react-router : {Router}
    \react-dom : ReactDOM
    \./history

    \./routes
}

console.log \hello-from-livescript
if window? then window.myhistory = history

$ document .ready ->
    root = $ \#app
    ReactDOM.render ``<Router history={history}>{routes}</Router>``, root.get![0]
