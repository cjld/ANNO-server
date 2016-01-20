require! {
    \react : React
    \react-router : {Router}
    \react-dom : ReactDOM
    \history/lib/createBrowserHistory

    \./routes
}

console.log \hello-from-livescript
history = createBrowserHistory!

$ document .ready ->
    root = $ \#app
    ReactDOM.render ``<Router history={history}>{routes}</Router>``, root.get![0]
