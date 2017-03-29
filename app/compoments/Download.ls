require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

module.exports = class Download extends React.Component
    ->
        super ...
        @state =
            release: [ \ANNOTATE-win32-x64.zip, \ANNOTATE-linux-x64.zip ]
    render: ->
        content = for a in @state.release
            ``<li key={a}><a href={"/release/"+a} target="_blank">{a}</a></li>``
        ``<div className="ui container">
            <h3 className="ui header"> Available downloads </h3>
            <div className="ui divider"></div>
            <ul>
            {content}
            </ul>
        </div>``
