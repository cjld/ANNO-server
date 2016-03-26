require! {
    \react : React
    \react-router : {Route}
    \./compoments/App
}

console.log \hello-from-routes

module.exports = ``<Route path='/'>
    <Route path='i(/:itemId)' component={App} />
</Route>``
