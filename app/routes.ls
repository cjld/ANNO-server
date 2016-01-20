require! {
    \react : React
    \react-router : {Route}
    \./compoments/Haha
}

console.log \hello-from-routes

module.exports = ``<Route path='/' component={Haha}>
<Route path='/haha' component={Haha}></Route>
</Route>``
