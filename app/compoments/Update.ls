require! \./common
{React, Link, ReactDOM, TimerMixin, actions, store} = common
require! promise

module.exports = class Update extends React.Component
    ->
        super ...
        @state = text:"Updating..."

    download: (name) ->
        if not inElectron then return
        fs = localRequire \fs
        bname = name.split('/').slice(-1)[0]
        p1 = new promise (resolve, reject) ->
            $.ajax do
                method: \GET
                url: name
                error: -> reject it
                success: -> resolve it
        p2 = new promise (resolve, reject) ->
            p1.then ->
                fs.writeFile "./resources/app/libs/#{bname}", it, ->
                    if it then return reject it
                    resolve!
            .catch -> reject it

    componentDidMount: ->
        if not inElectron then
            @set-state text: "Web version does not have to update."
            return
        os = localRequire \os
        binname = "anno_worker.exe"
        binpath = "ANNOTATE-win32-x64"
        if os.platform! == \linux
            binname = "anno_worker"
            binpath = "ANNOTATE-linux-x64"
        p1 = @download "/release/#{binpath}/resources/app/libs/#{binname}"
        p2 = @download "/release/#{binpath}/resources/app/libs/md5.txt"
        promise.all [p1,p2] .done ~>
            @set-state text:"Already up-to-date."
            actions.checkUpdate!

    render: ->
        ``<div className="ui container">
            <h3 className="ui header">{this.state.text}</h3>
        </div>``
