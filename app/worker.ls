if not inElectron
    localRequire = require
else
    localRequire = window.localRequire


config =
    time-evaluate: false
    paint-bin: "./../build-worker/anno_worker"
    paint-bin-args: ['server', '-platform', 'offscreen']

class worker

    ->
        @proc = null
        @is-ready = false
        @cmd-buffer = []

    send-buffer: ->
        buffer = @cmd-buffer
        @cmd-buffer = []
        for data in buffer
            @send-cmd data

    spawn: ->
        @kill-proc!
        child_process = localRequire \child_process
        readline = localRequire \readline
        @proc = child_process.spawn config.paint-bin, config.paint-bin-args
        if process.stdout
            @proc.stderr.pipe process.stdout
        else
            @proc.stderr.on \data, -> console.log it.to-string!
        @proc.on \exit, (code, signal) ~>
            console.log "proc exit with ", {code, signal}
            if signal != \SIGKILL
                @on-data? \s-error, error:"Program exit with #{signal}, please reload."
            @proc = undefined
        @proc.my-rl = readline.create-interface input:@proc.stdout
            ..on \line, @get-result


    open-url: (url) ~>
        # TODO not spawn here
        if not @proc
            console.log "respawn."
            @spawn!
        @is-ready = true
        @send-cmd {cmd:\open-session, data:{url}}
        @send-buffer!

    open-base64: (data) ->
        if not @proc
            console.log "respawn."
            @spawn!
        @is-ready = true
        @send-cmd {cmd:\open-base64, data:data}
        @send-buffer!


    on-paint: (data) ~>
        if config.time-evaluate
            console.time data.ts
        @send-cmd {cmd:'paint', data:data}


    on-load-region: (data) ~>
        console.log \load-region
        @send-cmd {cmd:'load-region', data:data}

    on-config: (data) ~>
        console.log \config-worker
        @send-cmd {cmd:'config', data:data}


    kill-proc: ~>
        @is-ready = false
        if @proc
            @proc.my-rl.close!
            @proc.stdin.pause!
            @proc.kill \SIGKILL
            @proc := null

    send-cmd: (cmd-json) ~>
        if not @is-ready
            @cmd-buffer.push cmd-json
            return
        if not @proc
            @on-data? \s-error, 'null-proc'
            return
        #console.log \send-cmd, JSON.stringify cmd-json
        @proc.stdin.write (JSON.stringify cmd-json) + '\n'

    get-result: (s) ~>
        res = JSON.parse s
        if res.status == 'error'
            @on-data? \s-error, res.error
        if res.status == \ok
            @on-data? \ok, res.data
            if config.time-evaluate
                if res.data.pcmd == \paint
                    console.timeEnd res.data.ts

    get-cmd: (cmd, data) ~>
        if cmd==\load-region
            @on-load-region data
        else if cmd==\paint
            @on-paint data
        else if cmd==\config
            @on-config data

module.exports = worker
