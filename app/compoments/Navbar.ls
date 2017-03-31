require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! \../history : myhistory

module.exports = class Navbar extends React.Component
    ->
        super ...
        @state = {}
        store.connect-to-component this, [\userCount, \hasUpdate]

    componentDidMount: ->
        actions.connect-socket!
        actions.checkUpdate!
        @search-input = $ \#search-input
        @search-input.keyup (e) ~>
            if event.keyCode == 13
                @searchClick!

    searchClick: ~>
        id = @search-input.val!
        myhistory.push "/i/#{id}"

    render: ->
        onlineUserCount = this.state.userCount
        #navList = [ \Explore \Datasets \Stats \Category \Help ]
        navList = [ \Help, \Download, \Update ]
        forback = ``<div className="item" key="fbbtn" style={{padding:'0'}}>
            <div className="ui icon buttons">
                <button className="ui icon button" onClick={() => myhistory.goBack() }> <i className="left arrow icon"></i> </button>
                <button className="ui icon button" onClick={() => myhistory.goForward() }> <i className="right arrow icon"></i> </button>
            </div>
        </div>``
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
        navs = [forback].concat navs

        ``<div className="ui menu">
                    <a className="header item" href="/i">ANNOTATE
                        <div className="floating ui red circular mini label" style={{top:'20%'}}>
                            {onlineUserCount}
                        </div>
                    </a>
                    <div className="item">
                        <div className="ui small left labeled right icon input">
                            <div className="ui label">Whole datasets</div>
                            <input id="search-input" type="text" placeholder="Search"/>
                            <i onClick={this.searchClick} className="inverted circular search link icon"></i>
                        </div>
                    </div>
                    {navs}
                    <div className="ui right floated text menu">
                        <div className="item">
                            <div className="ui buttons">
                                <Link to="/signup">
                                    <div className="ui green button">
                                        Sign up
                                    </div>
                                </Link>
                                <div className="or"></div>
                                <Link to="/signin">
                                    <div className="ui button">
                                        Sign in
                                    </div>
                                </Link>
                            </div>
                        </div>
                    </div>
                </div>
        ``
