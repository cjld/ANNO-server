require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

module.exports = class Breadcrumb extends React.Component
    ->
        super ...
        store.connect-to-component this, [
            \ancestors
        ]

    render: ->
        lists = []
        p = [] <<< @state.ancestors
        for a in p.reverse!
            lists.push ``<div key={a._id} className="divider">/</div>``
            lists.push ``<Link key={a._id+"-link"} to={"/i/"+a._id}>{a.name?a.name:"noname"}</Link>``

        ``<div>
            <Link to="/i/"><i className="big database icon" /></Link>
            <div className="ui huge breadcrumb">
                {lists}
            </div>
        </div>``
