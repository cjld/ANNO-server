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

storage = multer.disk-storage do
    destination: (req, file, callback) ->
        callback null, config.image-server-dir + config.upload-path
    filename: (req, file, callback) ->
        callback null Date.now!+'-'+file.originalname

upload = multer {storage} .array \userPhoto, config.upload-limit
app.post \/upload, (req, res) ->
    #console.log req.body
    upload req, res, (err) ->
        #console.log req.body
        #console.log req.files
        if err
            #console.log err
            res.status 500 .end "Error uploading files."
        else
            files = for file in req.files then do
                name: file.originalname
                state: \un-annotated
                type: \item
                url: config.image-server-url + config.upload-path + file.filename
                parent: req.body.parent

            #console.log files
            my-object.create files, (err) ->
                if err
                    res.status 500 .end "Items creation failure."
                else
                    res.end "Files is uploaded."

app.use \/signup (req, res, next) ->
    if typeof req.body.email != \string or not validator.is-email req.body.email
        res.status 400 .end "Email not valid."
        return
    next!

is-logged-in = (req, res, next) ->
    if req.is-authenticated! then return next!
    res.status 401 .end "Please login first."

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

app.use \/signup, my-passport \local-signup

app.use \/signin, my-passport \local-login

app.get \/auth/google, passport.authenticate 'google', scope : ['profile', 'email']
app.get \/auth/google/callback, passport.authenticate 'google',
    *   successRedirect : '/profile'
        failureRedirect : '/signin'

app.use \/logout, (req, res) ->
    req.logout!
    res.send \ok

app.use \/profile, is-logged-in, (req, res) ->
    data = {} <<< req.user.to-object!.profile
    data.email = req.user.local.email
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
        res.send obj

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
    #console.log qobj, req.body, size, is-next
    my-object.find qobj, func
        .sort [['_id', if is-next==\1 then -1 else 1]]
        .limit size

app.use \/find-neighbour, (req, res, next) ->
    find-neighbour 1, req.body.is-next, req, res, next

app.use \/prefetch-objects, (req, res, next) ->
    find-neighbour config.prefetch-size, \1, req, res, next

get-descendants = (ids, cb) ->
    ps = for i in ids
        if not i then continue
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

app.post \/new-object, (req, res, next) ->

    remove-origin = (obj) ->
        if not obj.originImage
            return
        (err, doc) <- my-object.find-by-id obj.originImage
        if err
            console.error err
            return
        if not doc.annotations
            return
        i = doc.annotations.index-of obj._id
        if i>=0
            doc.annotations.splice i, 1
            doc.save!

    add-origin = (id, obj) ->
        if not obj.originImage
            return
        (err, doc) <- my-object.find-by-id obj.originImage
        if err
            console.error err
            return
        if not doc.annotations
            doc.annotations = [obj._id]
        else
            i = doc.annotations.index-of obj._id
            if i==-1
                doc.annotations.push obj._id
        doc.save!

    on-update = (obj, newobj) ->
        if obj.originImage == newobj.originImage
            return
        remove-origin obj
        add-origin obj._id, newobj

    on-create = (obj) ->
        add-origin obj._id, obj

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
            on-update doc, edit-obj
            doc <<< edit-obj
            (err) <- doc.save
            if err then return next err
            if req.body.taskImages
                build-task req.body
            else
                res.send "Edit id:#{id} successfully!"
    else
        object = new my-object req.body
        on-create object
        object.save ->
            if it then return next it
            if req.body.taskImages
                build-task object
            else
                res.send "#{req.body.name} saved successfully."

object-on-remove = (doc) ->
    #console.log "remove #{doc._id}"
    if doc.originImage
        my-object.find-one _id:doc.originImage,  (err, doc2) ->
            if err then return console.error err
            if not doc2.annotation
                return
            i = doc2.annotation.index-of doc._id
            if i>=0
                doc2.annotation.splice i, 1
                doc2.save!


app.post \/delete-items, (req, res, next) ->
    #console.log req.body['items[]']
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
                object-on-remove doc
            ids = for i in docs then i._id
            remove-descendants ids

    my-object.find {_id:{$in:items}}, (err, docs)->
        if err then return next err
        for doc in docs
            object-on-remove doc
        total-remove += items.length
        remove-descendants items

app.post \/save-mark, (req, res, next) ->
    #console.log req.body
    res.send \ok.

app.post \/counter, (req, res, next) ->
    my-counter = (cond, cb) ->
        cond <<< req.body.{parent}
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
        if err then return next err
        results.page-size = config.page-size
        res.send results
app.use (req, res) ->
    res.status 404 .send "api #{req.url} not found."

console.log "hello from api."

module.exports = app
