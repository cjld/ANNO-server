require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

module.exports = class Navbar extends React.Component
    ->
        super ...
        @state = {}
        store.connect-to-component this, [\userCount, \hasUpdate]

    componentDidMount: ->
        actions.connect-socket!
        actions.checkUpdate!

    render: ->
        onlineUserCount = this.state.userCount
        #navList = [ \Explore \Datasets \Stats \Category \Help ]
        navList = [ \Help, \Download, \Update ]
        navs = navList.map (it) ~>
            dom = it
            if it==\Update and @state.hasUpdate
                dom=``<div>
                    <span>Update</span>
                    <div className="floating ui red circular mini label" style={{top:'20%'}}>
                        New
                    </div>
                </div>``
            ``<Link to={"/"+it.toLowerCase()} className="item" key={it}>
                {dom}
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
