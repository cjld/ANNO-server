require! {
    \react : React
    \react-router : {Route}
    \./compoments/App
}

console.log \hello-from-routes

module.exports = ``<Route path='/' component={App}>
<Route path='/haha' component={App}></Route>
</Route>``
