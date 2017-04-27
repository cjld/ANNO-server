require! {
    \prelude : _

    \express
    \mongoose
    \async
    \../config
    \../app/models

    \multer
    \validator
    \passport
    \emailjs : email
    \crypto

    \promise
    \./session : {store}
}

server = email.server.connect config.email.config

send-forget-code = (addr, code, cb) ->
    data = {} <<< config.email.template
    data.text = "Your password reset code: #{code}"
    data.to = "<#{addr}>"
    server.send data, cb

app = express!

my-object = models.Object

mongoose.connect config.database
mongoose.connection.on \error ->
    console.log 'Error: Could not connect to MongoDB. Did you forget to run `mongod`?'

app.get \/test, (req, res) ->
    res.send \ok!


is-logged-in = (req, res, next) ->
    if req.is-authenticated! then return next!
    res.status 401 .end "Please login first."

is-admin = (req, res, next) ->
    if req.user.local.is-admin then return next!
    res.status 401 .end "Permission denied."

storage = multer.disk-storage do
    destination: (req, file, callback) ->
        callback null, config.image-server-dir + config.upload-path
    filename: (req, file, callback) ->
        callback null Date.now!+'-'+file.originalname

upload = multer {storage} .fields [
    *   name: \userUpload, max-count: config.upload-limit
    *   name: \userUpload2, max-count: config.upload-limit
]

app.post \/upload, is-logged-in, (req, res) ->
    upload req, res, (err) ->
        if err
            res.status 500 .end "Error uploading files."
        else
            if req.files["userUpload"]
                files = for file in req.files["userUpload"]
                    if not file.mimetype.starts-with \image
                        continue
                    new my-object do
                        name: file.originalname
                        state: \un-annotated
                        type: \item
                        url: config.image-server-url + config.upload-path + file.filename
                        owner: req.user._id
                        parent: req.body.parent
            else
                files = []

            if req.files["userUpload2"] and req.body.relativePath
                dirmap = {'':req.body.parent}
                rpath = JSON.parse req.body.relativePath
                files2 = []
                for path,j in rpath
                    ps = path.split \/
                    cname = ""
                    file = req.files["userUpload2"][j]
                    if not file.mimetype.starts-with \image
                        continue
                    for s,i in ps
                        pr = dirmap[cname]
                        cname = cname + \/ + s
                        if dirmap[cname]
                            continue
                        newobj = new my-object do
                            name: s
                            state: \un-annotated
                            type: if i==ps.length-1 then \item else \directory
                            owner: req.user._id
                            parent: pr
                            url: if i==ps.length-1 then config.image-server-url + config.upload-path + file.filename else undefined
                        dirmap[cname] = newobj._id
                        files2.push newobj
            else
                files2 = []

            my-object.create files.concat files2, (err) ->
                if err
                    res.status 500 .end "Items creation failure."
                else
                    res.end "Files is uploaded."

app.use \/signup (req, res, next) ->
    if typeof req.body.email != \string or not validator.is-email req.body.email
        res.status 400 .end "Email not valid."
        return
    next!

my-passport = (strategy) ->
    return (req, res, next) ->
        _ = passport.authenticate strategy, (err, user, info) ->
            if err then return next err
            if not user then return res.status 401 .end info.message
            data = {} <<< user.to-object!.profile
            req.login user, ->
                if it then return next it
                res.send data
        _(req, res, next)

app.use \/sessions, is-logged-in, is-admin, (req, res, next) ->
    console.log store
    console.log store.collection.find
    (err, sessions) <- store.collection.find!.to-array
    if err then return next err
    console.log sessions
    res.json sessions

app.use \/signup, my-passport \local-signup

app.use \/signin, my-passport \local-login

app.get \/auth/google, passport.authenticate 'google', scope : ['profile', 'email']
app.get \/auth/google/callback, passport.authenticate 'google',
    *   successRedirect : '/profile'
        failureRedirect : '/signin'

app.use \/logout, (req, res) ->
    req.logout!
    res.send \ok

app.use \/profile, is-logged-in, (req, res, next) ->
    if req.body.uid
        (err,user) <- models.User.find-one _id:that
        if err then return next err
        if not user
            return res.status 404 .end "user not found."
        data = {} <<< user.to-object!.profile
        if user.local.email
            data.email = that
        if user.local.is-admin
            data.is-admin = true
        data.id = user._id.to-string!
        res.send data
    else
        data = {} <<< req.user.to-object!.profile
        if req.user.local.email
            data.email = req.user.local.email
        if req.user.local.is-admin
            data.is-admin = true
        data.id = req.user._id.to-string!
        res.send data

app.use \/edit-profile, is-logged-in, (req, res, next) ->
    if req.body.email
        delete req.body.email
    req.user.profile <<< req.body
    if req.body.password
        if req.user.local.password
            if not req.user.valid-password req.body.oldpassword
                return res.status 401 .end "Wrong password."
        if not req.user.local.email
            req.user.local.email = req.user.profile.email
        req.user.local.password = req.user.generate-hash req.body.password
    req.user.save (err) ->
        if err then return next err
        req.login req.user, ->
            if it then return next it
            res.send req.user.profile

app.use \/sendcode, (req, res, next) ->
    if typeof req.body.email == \string and validator.is-email req.body.email
        (err, user) <- models.User.find-one {"local.email":req.body.email}
        if err then return next err
        if not user then return res.status 400 .end "Invalid Email."
        (err,buffer) <- crypto.randomBytes 4
        if err then return next err
        code = buffer.toString('hex')
        user.local.code = code
        (err) <- user.save
        if err then return next err
        (err) <- send-forget-code req.body.email, code
        if err then return next err
        res.send "ok"
    else
        res.status 400 .end "Invalid Email."

app.use \/reset-password, (req, res, next) ->
    if typeof req.body.email == \string and validator.is-email req.body.email
        (err, user) <- models.User.find-one {"local.email":req.body.email}
        if err then return next err
        if user.local.code and user.local.code == req.body.resetcode
            user.local.code = undefined
            user.local.password = user.generate-hash req.body.password
            (err) <- user.save
            if err then return next err
            res.send "ok"
        else
            return res.send 401 .end "Wrong reset code."
    else
        res.status 400 .end "Invalid Email."

app.use \/apply, is-logged-in, (req, res, next) ->
    (err, des) <- get-descendants [req.body.id]
    if err then return next err
    ps = des.map (d) ->
        new promise (resolve, reject) ->
            if d.type == \annotation
                (err, ori) <- my-object.find-one _id:d.originImage
                if err then return reject err
                if not ori then return reject "Origin not found."
                if not ori.check-permission req.user
                    return reject "Permission denied."
                ori.state = d.state
                ori.marks = d.marks
                ori.save ->
                    if it then return reject it
                    resolve ori
            else
                resolve!
    promise.all ps
    .then -> res.send "Apply successful."
    .catch -> next it

get-task = (req, res, next) ->
    (err, task) <- my-object.find-one _id:req.body.taskid
    if err then return next err
    if not task
        return res.status 404 .end "TaskID not found."
    (err, imgdir) <- my-object.find-one parent:task._id, name: \all_images, type: \directory
    if err then return next err
    if not imgdir
        return res.status 404 .end "Img dir not found."
    req.imgdir = imgdir
    req.task = task
    next!

send-taskInfo = (req, res, next) ->
    cmap =
        "total": {}
        "un-assign": {\annotations.0 : {\$exists : false}}
        "assigned(1)" : {\annotations.1 : {\$exists : false}, \annotations.0 : {\$exists : true}}
        "annotated" : {state: \annotated}
        "un-annotated" : {state: \un-annotated}
        "issued" : {state: \issued}
    ps = Object.keys cmap .map (k) ->
        v = cmap[k]
        return new promise (resolve, reject) ->
            my-object.count {parent:req.imgdir._id} <<< v, (err, count) ->
                if err then return reject err
                resolve {"#{k}":count}
    ps.push new promise (resolve, reject) ->
        my-object.find parent:req.task._id, type:\directory .populate \worker .exec (err, docs) ->
            if err then return next err
            ps2 = docs.map (doc) ->
                new promise (resolve2, reject2) ->
                    (err, results) <- count-state doc._id
                    if err then return reject2 err
                    resolve2 results
            promise.all ps2
                .then (data) ->
                    for a,i in data
                        a <<< {
                            "mission name":docs[i].name
                            "mid":docs[i]._id.to-string!
                            "user":docs[i].worker?profile.name
                            "uid":docs[i].worker?_id.to-string!
                            "start time": docs[i]._id.getTimestamp!.to-string!
                        }
                    console.log data
                    resolve data
                .catch (err) ->
                    reject err
    promise.all ps
        .then (data) ->
            dataall = {}
            missionInfo = data.splice -1
            for a in data then dataall <<< a
            res.json {missionInfo:missionInfo[0], statsInfo:dataall}
        .catch (errs) ->
            console.log errs
            next errs

get-proper-name = (id, name, i, cb) ->
    if i==0
        newname = name
    else
        newname = name+"(#{i})"
    my-object.find-one parent:id, name:newname, (err, doc) ->
        if err then return console.error err
        if not doc
            cb newname
        else
            get-proper-name id, name, i+1, cb

app.use \/taskInfo, get-task, send-taskInfo
# taskid, uid, random, amount
app.use \/taskAssign, is-logged-in, get-task, (req, res, next) ->
    (err, worker) <- models.User.find-one _id:req.body.uid
    if err then return next err
    if not worker
        return res.status 404 .end "user not found."
    ckey = "annotations." + (req.task.crossValidate-1)
    filter = {parent:req.imgdir._id, "#{ckey}": {\$exists : false}}
    query = if req.body.random
        my-object.find-random filter
    else
        my-object.find filter
    query.limit req.body.amount
    query.exec (err, docs) ->
        if err then return next err
        console.log "find docs #{docs.length}"
        (name) <- get-proper-name req.task._id, worker.profile.name + "'s task", 0
        workerdir = new my-object do
            type:\directory
            parent: req.task._id
            name: name
            worker: worker._id
            owner: req.user._id
        workerdir.save (err) ->
            if err then return next err
            ps = for doc in docs
                new promise (resolve, reject) ->
                    newdoc =
                        parent: workerdir._id
                        type: \annotation
                        originImage: doc._id
                        name: doc.name
                        url: doc.url
                        worker: worker._id
                        owner: req.user._id
                    newdoc = new my-object newdoc
                    on-create newdoc
                    newdoc.save (err) ->
                        if err then return reject err
                        resolve newdoc
            promise.all ps
            .then -> next!
            .catch -> next it

app.use \/taskAssign, send-taskInfo

app.use \/list-objects, (req, res, next) ->
    page = parseInt req.body.page
    if page == NaN then page = 1
    qobj = {parent:req.body.parent}
    if req.body.state != 'total'
        if req.body.state == 'un-annotated'
            qobj.state = {'$in': ['un-annotated', '', null]}
        else
            qobj.state = req.body.state
    my-object.find qobj, (err, objs) ->
        if err then return next err
        res.send objs
    .sort [['_id', -1]]
    .skip (page - 1) * config.page-size
    .limit config.page-size
    .populate \originImage

app.use \/find-objects, (req, res, next) ->
    my-object.find req.body .populate \originImage .exec (err, objs) ->
        if err then return next err
        res.send objs

app.use \/find-one-name, (req, res, next) ->
    req.body <<< req.query
    my-object.find-one req.body, {name:true}, (err, obj) ->
        if err then return next err
        if not obj
            res.status 404 .end "Object not found."
        else
            res.send obj

app.use \/find-user, (req, res, next) ->
    ss = req.body._id
    filter = if validator.is-email ss
        "profile.email" : ss
    else if mongoose.Types.ObjectId.isValid ss
        _id: ss
    else
        "profile.name": ss
    (err,user) <- models.User.find-one filter
    if err then return next err
    if not user
        return res.status 404 .end "User not found."
    res.send {_id:user._id} <<< user.profile.to-object!

app.use \/find-one, (req, res, next) ->
    if req.body.parent == ''
        req.body.parent = undefined
    req.body <<< req.query
    my-object.find-one req.body, (err, obj) ->
        if err then return next err
        res.send obj

find-neighbour = (size, is-next, req, res, next) ->
    data = {}
    data <<< req.body
    data <<< req.query
    func = (err, docs) ->
        if err then return next err
        if size!=1
            res.send docs
        else if docs[0]?
            res.send docs[0]{_id}
        else
            res.send {}
    if is-next == \1
        qobj = {'_id':{'$lt':data._id}}
    else
        qobj = {'_id':{'$gt':data._id}}
    if data.parent?
        qobj.parent = data.parent
    if data.state?
        if req.body.state in ['un-annotated', '', null]
            qobj.state = {'$in': ['un-annotated', '', null]}
        else
            qobj.state = req.body.state
    my-object.find qobj, func
        .sort [['_id', if is-next==\1 then -1 else 1]]
        .limit size

app.use \/find-neighbour, (req, res, next) ->
    find-neighbour 1, req.body.is-next, req, res, next

app.use \/prefetch-objects, (req, res, next) ->
    find-neighbour config.prefetch-size, \1, req, res, next

get-descendants = (ids, cb) ->
    ps = ids.filter(-> it).map (i) ->
        new promise (resolve, reject) ->
            if i.type then resolve i
            else
                (err, doc) <- my-object.find-by-id i
                if err then return reject err
                if doc.type == \directory
                    (err, docs) <- my-object.find parent:doc._id
                    if err then return reject err
                    get-descendants docs, (err, dds) ->
                        if err then return reject err
                        resolve [doc].concat dds
                else
                    resolve doc
    promise.all ps
        .then -> cb null, [].concat.apply [], it
        .catch -> cb it


remove-origin = (obj) ->
    object-on-remove obj

add-origin = (id, obj) ->
    if not obj.originImage
        return
    (err, doc) <- my-object.find-by-id obj.originImage
    if err
        console.error err
        return
    if not doc.annotations
        doc.annotations = [id]
    else
        i = doc.annotations.index-of id
        if i==-1
            doc.annotations.push id
    doc.save!

on-update = (obj, newobj) ->
    idstr = obj.originImage?to-string!
    newidstr = if newobj.originImage?_id
        newobj.originImage._id
    else
        newobj.originImage
    if idstr == newidstr
        return
    remove-origin obj
    add-origin obj._id, newobj

on-create = (obj) ->
    add-origin obj._id, obj

app.post \/new-object, is-logged-in, (req, res, next) ->
    build-task = (obj) ->
        (err, task) <- my-object.find-by-id obj._id
        if err then return next err
        doc = {parent: obj._id, name: \all_images, type: \directory}
        (err, imgdir) <- my-object.find-one-and-update doc, doc, {upsert:true, new: true}
        if err then return next err
        (err, descendants) <- get-descendants obj.taskImages
        if err then return next err
        newdocs = for x in descendants
            if x.type not in [\item, \annotation]
                continue
            new promise (resolve, reject) ->
                doc = parent: imgdir._id, type: \annotation, originImage: x._id
                doc-update = {name: x.name, url:x.url} <<< doc
                (err, fdoc) <- my-object.find-one doc
                if err then return reject err
                if fdoc
                    on-update fdoc, doc-update
                    fdoc <<< doc-update
                else
                    fdoc = new my-object doc-update
                    fdoc.owner = req.user._id
                    on-create fdoc
                fdoc.save ->
                    if it then return reject it
                    resolve fdoc
        promise.all newdocs
            .then (anno-docs) ->
                res.send "#{anno-docs.length} annotations created."
            .catch (reason) ->
                next reason

    if req.body._id?
        edit-obj = {} <<< req.body
        id = delete edit-obj._id
        delete edit-obj.__v
        my-object.find-one {_id:id}, (err, doc) ->
            if err then return next err
            if not doc
                return res.status 404 .end "Object not found."
            if not doc.check-permission req.user
                if not doc.check-worker req.user
                    return res.status 401 .send "Permission denied."
                else
                    edit-obj := edit-obj{state, marks, shape}
            on-update doc, edit-obj
            doc <<< edit-obj
            (err) <- doc.save
            if err then return next err
            if req.body.taskImages and doc.type == \task
                build-task req.body
            else
                res.send "Edit id:#{id} successfully!"
    else
        object = new my-object req.body
        object.owner = req.user._id
        on-create object
        object.save ->
            if it then return next it
            if req.body.taskImages and object.type == \task
                build-task object
            else
                res.send "#{req.body.name} saved successfully."

object-on-remove = (doc) ->
    if doc.originImage
        my-object.find-one _id:doc.originImage, (err, doc2) ->
            if err then return console.error err
            if not doc2.annotations
                return
            i = doc2.annotations.index-of doc._id
            if i>=0
                doc2.annotations.splice i, 1
                doc2.save!


app.post \/delete-items, is-logged-in, (req, res, next) ->
    items = req.body['items[]']
    if items
        items = [items] if not Array.isArray items
    else
        return res.send "No item was deleted."

    total-remove = 0
    remove-descendants = (ids) ->
        my-object.remove {_id:{$in:ids}} .exec!
        if ids.length == 0
            res.send "Delete #{total-remove} items successfully!"
            return
        my-object.find {parent:{$in:ids}}, (err, docs) ->
            if err then return next err
            total-remove += docs.length
            for doc in docs
                if not doc.check-permission req.user
                    return res.status 401 .end "Permission denied."
            for doc in docs
                object-on-remove doc
            ids = for i in docs then i._id
            remove-descendants ids

    my-object.find {_id:{$in:items}}, (err, docs)->
        if err then return next err
        for doc in docs
            if not doc.check-permission req.user
                return res.status 401 .end "Permission denied."
        for doc in docs
            object-on-remove doc
        total-remove += items.length
        remove-descendants items

app.post \/save-mark, (req, res, next) ->
    res.send \ok.

count-state = (parent, cb) ->
    my-counter = (cond, cb) ->
        cond <<< {parent}
        my-object.count cond, cb

    async.parallel {
        \total : (callback) ->
            my-counter {}, callback
        \annotated : (callback) ->
            my-counter {state:'annotated'}, callback
        \un-annotated : (callback) ->
            my-counter {state:{'$in':['un-annotated', null, '']}}, callback
        \issued : (callback) ->
            my-counter {state:'issued'}, callback
    }, (err, results) ->
        if err then return cb err
        cb null, results

app.post \/counter, (req, res, next) ->
    (err, results) <- count-state req.body.parent
    if err then return next err
    results.page-size = config.page-size
    res.send results

app.use (req, res) ->
    res.status 404 .send "api #{req.url} not found."

console.log "hello from api."

module.exports = app
