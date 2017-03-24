require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

module.exports = class Navbar extends React.Component

    componentDidMount: ->
        actions.connect-socket!
        @state = onlineUserCount:0
        socket.on \user-count, ~> @set-state onlineUserCount:it

    render: ->
        onlineUserCount = this.state?onlineUserCount
        #navList = [ \Explore \Datasets \Stats \Category \Help ]
        navList = [ \Help ]
        navs = navList.map (it) ->
            ``<Link to={"/"+it.toLowerCase()} className="item" key={it}>
                {it}
            </Link>
            ``
        ``<div className="ui menu">
                    <a className="header item" href="/i">ANNOTATE
                        <div className="floating ui red circular mini label" style={{top:'20%'}}>
                            {onlineUserCount}
                        </div>
                    </a>
                    <div className="item">
                        <div className="ui small left labeled right icon input">
                            <div className="ui label">Whole datasets</div>
                            <input type="text" placeholder="Search"/>
                            <i className="search icon"></i>
                        </div>
                    </div>
                    {navs}
                    <div className="ui right floated text menu">
                        <div className="item">
                            <div className="ui buttons">
                                <div className="ui green button">
                                    Sign up
                                </div>
                                <div className="or"></div>
                                <div className="ui button">
                                    Sign in
                                </div>

                            </div>
                        </div>
                    </div>
                </div>
        ``
