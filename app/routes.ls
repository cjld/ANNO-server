require! {
    \react : React
    \react-router : {Route}
    \./compoments/App
}

console.log \hello-from-routes

module.exports = ``<Route path='/'>
    <Route path='i' component={App} />
    <Route path='i/page/:page' component={App} />
    <Route path='i/:itemId/page/:page' component={App} />
    <Route path='i/:itemId' component={App} />
</Route>``
