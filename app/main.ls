require! \./compoments/common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

require! {
    \react : React
    \react-router : {Router, browserHistory}
    \react-dom : ReactDOM
    \./history

    \./routes
}

console.log \hello-from-livescript
if window? then window.myhistory = history

$ document .ready ->
    $ 'body' .on 'contextmenu', 'img', -> false
    $ 'body' .on 'contextmenu', 'canvas', -> false
    window.currentMousePos = { x: -1, y: -1 };
    $ document .mousemove (event) ->
        window.currentMousePos.x = event.pageX;
        window.currentMousePos.y = event.pageY;
        #console.log window.currentMousePos
    toastr.options.timeOut = 3
    toastr.options.extendedTimeOut = 10
    root = $ \#app
    ReactDOM.render ``<Router history={browserHistory}>{routes}</Router>``, root.get![0]
