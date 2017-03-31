require! {
    \react : React
    \react-router : {Route}
    \./compoments/App : {App, MainPage}
    \./compoments/Help
    \./compoments/Download
    \./compoments/Update
    \./compoments/BackDoor
    \./compoments/Signin
    \./compoments/Signup
    \./compoments/Profile
}

console.log \hello-from-routes

module.exports = ``<Route path='/' component={App}>
    <Route path='i' component={MainPage} />
    <Route path='i/page/:page' component={MainPage} />
    <Route path='i/:itemId/page/:page' component={MainPage} />
    <Route path='i/:itemId' component={MainPage} />
    <Route path='help(/:helpUrl)' component={Help} />
    <Route path='download' component={Download} />
    <Route path='update' component={Update} />
    <Route path='backdoor' component={BackDoor} />
    <Route path='signin' component={Signin} />
    <Route path='signup' component={Signup} />
    <Route path='profile' component={Profile} />
</Route>``
