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
        else if $.cookie \last-id
            myhistory.push \/i/ + that

    componentDidMount: ->
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
