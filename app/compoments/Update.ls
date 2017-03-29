require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common

module.exports = class Update extends React.Component
    ->
        super ...
        @state.text = "Updating..."

    download: (name) ->
        if not inElectron then return
        fs = localRequire \fs
        os = localRequire \os
        bname = name.split('/').slice(-1)[0]
        p1 = new promise (resolve, reject) ->
            $.ajax do
                method: \GET
                url: name
                error: -> reject it
                success: -> resolve it
        #p1.then ->
        #    fs.writeFile "./resources/app/libs/#{bname}", it, 

    componentDidMount: ->
        if not inElectron then return


    render: ->
        ``<div className="ui container">
            <h3 className="ui header">this.state.text</h3>
        </div>``
