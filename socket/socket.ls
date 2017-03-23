require! {
    \../app/models
    \../config
    \./../app/worker
}
my-object = models.Object

module.exports = (io) ->
    user-count = 0

    io.on \connection, (socket) ->
        wk = new worker
        wk.spawn!
        user-count++
        console.log user-count
        io.sockets.emit \user-count, user-count

        wk.on-data = (msg, data) ~>
            socket.emit msg, data

        socket.on \disconnect, ->
            user-count--
            #console.log user-count
            io.sockets.emit \user-count, user-count
            wk.kill-proc!

        socket.on \open-session, ->
            console.log \open-session, it
            #wk.kill-proc!
            my-object.find-one {_id:it.id}, (err, obj) ->
                if err then socket.emit \s-error, err
                url = obj?url
                if url then
                    wk.open-url url
                else
                    socket.emit \s-error, 'url-not-found'

        socket.on \paint, wk.on-paint
        socket.on \load-region, wk.on-load-region
        socket.on \config, wk.on-config

process.on 'uncaughtException', (err) ->
    console.error err.stack
    console.error err
    console.log "Node NOT Exiting..."
