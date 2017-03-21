require! {
    fs
    process
    request
}

file-list = []
api-url = 'http://localhost:9200'
#img-url = 'http://123.57.147.168:8080'
img-url = 'http://166.111.71.64:9201'

new-object = (url, name, fatherid) ->
    console.log "post #{url} #{name} #{fatherid}"
    request.post '/api/find-one', {form:{name:name, parent:fatherid,  type:'item'}}, (err, http-response, body) ->
        if body == "undefined" or body == "" or not body?
            request.post api-url++'/api/new-object', {form:{url:url, name:name, parent:fatherid, type:'item'}}
        else
            console.log "'"+body+"'", body==\undefined, body==undefined

get-dir-id = (name, fatherid, cb) ->
    console.log "parent #{fatherid}"
    check-body = (body) ->
        try
            body = JSON.parse body
        catch
            body = {}
        if body._id?
            cb body._id
            return true
        return false
    request.post api-url+'/api/find-one', {form:{name:name, parent:fatherid,  type:'directory'}}, (err, http-response, body) ->
        if not check-body body
            request.post api-url+'/api/new-object', {form:{name:name, parent:fatherid, type:'directory'}}, (err, http-response, body) ->
                console.log "new #{body}"
                request.post api-url+'/api/find-one', {form:{name:name, parent:fatherid, type:'directory'}}, (err, http-response, body) ->
                    check-body body


walk = (path, father, len) ->
    basename = path.split '/' .reverse![0]
    console.log "bname #{basename}"
    dir-list = fs.readdir-sync path
    get-dir-id basename, father, (myid) ->
        dir-list.for-each (item) ->
            npath = path+'/'+item
            console.log npath
            if fs.stat-sync(npath).is-file!
                if npath.ends-with \config.json
                    console.log \find-config
                    config = fs.readFileSync npath .to-string!
                    request.post api-url+'/api/new-object', {form:{_id:myid, parent:father, type:'directory', config:config}}
                else
                    path2 = npath.to-lower-case!
                    if path2.ends-with \.jpg
                        or path2.ends-with \.jpeg
                        or path2.ends-with \.bmp
                        or path2.ends-with \.png
                    then
                        file-list.push npath
                        new-object img-url + (npath.slice len), item, myid
            if fs.stat-sync(npath).is-directory!
                walk npath, myid, len

for dir in process.argv.splice 2
    walk dir, undefined, dir.length

console.log file-list
