require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

require! {
    \./Navbar
    \./Footer
    \./Guider
    \./Editor
    \./Displayer
}


class MainPage extends React.Component
    ->
        store.connect-to-component this, [\currentItem]

    render: ->
        type = @state.currentItem?type
        ``<div className="ui container">
            <Guider />
            {
                type == "item"? <Editor currentItem={this.state.currentItem} /> : <Displayer />
            }
        </div>
        ``

class App extends React.Component

    componentDidMount: ->
        actions.set-store {fatherId:@props.params.itemId, page:@props.params.page}

    componentWillUpdate: ->
        actions.set-store {fatherId:it.params.itemId, page:it.params.page}

    render: ->
        ``<div>
            <Navbar />
            {this.props.children}
            <Footer />
        </div>
        ``

module.exports = {App, MainPage}
