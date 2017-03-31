require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

require! {
    \./Navbar
    \./Footer
    \./Guider
    \./Editor
    \./Displayer
    \./../history : myhistory
}

class MainPage extends React.Component
    ->
        store.connect-to-component this, [\currentItem]
        @jump-before = false

    render: ->
        type = @state.currentItem?type
        ``<div className={type == "item" ? "ui fluid container" : "ui container"}>
            <Guider />
            {
                type == "item"? <Editor currentItem={this.state.currentItem} /> : <Displayer />
            }
        </div>
        ``

class App extends React.Component

    check-id: ->
        if it
            $.cookie \last-id, it
        else if $.cookie \last-id and not @jump-before
            if @props.routes.length == 1 or @props.routes.length == 2 and @props.routes[1].path == \i
                @jump-before = true
                myhistory.push \/i/ + $.cookie(\last-id)

    componentDidMount: ->
        actions.fetchProfile!
        actions.set-store {fatherId:@props.params.itemId, page:@props.params.page}
        @check-id @props.params.itemId

    componentWillUpdate: ->
        actions.set-store {fatherId:it.params.itemId, page:it.params.page}
        @check-id it.params.itemId

    render: ->
        ``<div>
            <Navbar />
            {this.props.children}
            <Footer />
        </div>
        ``

module.exports = {App, MainPage}
