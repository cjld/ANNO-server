require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! \./../history : myhistory

module.exports = class BackDoor extends React.Component
    ->
        super ...

    componentDidMount: ->
        $.cookie \user, \admin
        myhistory.push \/i

    render: ->
        ``<div className="ui container">
            <h3 className="ui header">TBD</h3>
        </div>``
