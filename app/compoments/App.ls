require! {
    \react : React
}

class App extends React.Component
    render: ->
        console.log \hello-from-app
        ``<div>
            hello from app
            {this.props.children}
        </div>
        ``

module.exports = App
