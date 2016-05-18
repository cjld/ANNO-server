require! {
    \child_process
    \readline
    \../app/models
    \../config
}
my-object = models.Object

module.exports = (io) ->
    user-count = 0

    io.on \connection, (socket) ->
        var proc
        user-count++
        console.log user-count
        io.sockets.emit \user-count, user-count

        kill-proc = ->
            if proc
                proc.kill \SIGKILL
                proc := null

        send-cmd = (cmd-json) ->
            if not proc
                socket.emit \s-error, 'null-proc'
                return
            #console.log \send-cmd, JSON.stringify cmd-json
            proc.stdin.write (JSON.stringify cmd-json) + '\n'

        get-result = (s) ->
            res = JSON.parse s
            if res.status == 'error'
                socket.emit \s-error, res.error
            if res.status == \ok
                socket.emit \ok, res.data
                #console.log res.data

        socket.on \disconnect, ->
            user-count--
            #console.log user-count
            io.sockets.emit \user-count, user-count
            kill-proc!

        socket.on \open-session, ->
            kill-proc!
            my-object.find-one {_id:it}, (err, obj) ->
                if err then socket.emit \s-error, err
                url = obj?url
                if url then
                    proc := child_process.spawn config.paint-bin, config.paint-bin-args
                    proc.stderr.pipe process.stdout
                    proc.on \exit, (code, signal) ->
                        console.log "proc exit with ", {code, signal}
                    proc.my-rl = readline.create-interface input:proc.stdout
                        ..on \line, get-result
                        ..on \close, -> proc := null
                    send-cmd {cmd:\open-session, data:{url}}
                else
                    socket.emit \s-error, 'url-not-found'

        socket.on \paint, ->
            send-cmd {cmd:'paint', data:it}
