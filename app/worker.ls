if not inElectron
    localRequire = require
else
    localRequire = window.localRequire


config =
    time-evaluate: false

class worker

    (paint-bin, paint-bin-args)->
        @proc = null
        @is-ready = false
        @cmd-buffer = []
        @paint-bin = paint-bin
        @paint-bin-args = paint-bin-args

    alloc-tmpdir: (cb) ->
        if @tmpdir
            cb!
            return
        tmp = localRequire \tmp
        tmp.dir unsafe-cleanup:true, (err, path, cleanupCallback) ~>
            if err then throw err;
            console.log("tmpDir: ", path);
            @tmpdir = path
            @release-tmpdir-callback = cleanupCallback
            cb!
    release-tmpdir: ->
        @release-tmpdir-callback?!
        @tmpdir = undefined

    send-buffer: ->
        buffer = @cmd-buffer
        @cmd-buffer = []
        for data in buffer
            @send-cmd data

    spawn: ->
        @kill-proc!
        child_process = localRequire \child_process
        readline = localRequire \readline
        if inElectron
            @paint-bin = "./resources/app/libs/anno_worker"
            @paint-bin-args = ['server', '-platform', 'offscreen']
        @proc = child_process.exec-file @paint-bin, @paint-bin-args, maxBuffer: 30*1024*1024
        if process.stdout
            @proc.stderr.pipe process.stdout
        else
            @proc.stderr.on \data, -> console.log it.to-string!
        @proc.on \exit, (code, signal) ~>
            console.log "proc exit with ", {code, signal}
            if signal != \SIGKILL
                @on-data? \s-error, error:"Program exit with #{signal}, please reload."
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

    on-propagate: (data) ~>
        <~ @alloc-tmpdir
        data.tmpdir = @tmpdir
        @propagate-data = data
        @send-cmd {cmd:"drawmask", data:data}
        promise = localRequire \promise
        child_process = localRequire \child_process
        @ps = for url,i in [data.from.url, data.to.url]
            new promise (resolve, reject) ~>
                proc = child_process.exec-file "wget", [url, '-O', @tmpdir+"/#{i}.png"]
                proc.on \exit, (code, signal) ~>
                    if code==0
                        return resolve!
                    console.log "download error(#{code}, #{signal}): "+ url
                    reject!

    on-propagate-step2: ~>
        child_process = localRequire \child_process
        promise = localRequire \promise
        promise.all @ps .then ~>
            proc = child_process.exec-file "cp", [@tmpdir+"/2.png", @tmpdir+"/3.png"]
            proc.on \exit, (code, signal) ~>
                @send-cmd {cmd:"loadmask", data:@propagate-data}

    on-propagate-step3: (data) ~>
        data.pcmd = \propagate
        @on-data? \ok, data

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
            if res.data.pcmd == "drawmask"
                @on-propagate-step2!
                return
            if res.data.pcmd == "loadmask"
                @on-propagate-step3 res.data
                return
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
        else if cmd==\propagate
            @on-propagate data

module.exports = worker
