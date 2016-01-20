require! {
    \react : React
    \react-router : {Link}
}

class App extends React.Component
    render: ->
        console.log \hello-from-app
        ``<div>
            hello from app
            <Link to="/haha">haha</Link>
            {this.props.children}
        </div>
        ``

module.exports = App
