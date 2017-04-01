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

app.use \/find-objects, (req, res, next) ->
    my-object.find req.body, (err, objs) ->
        if err then return next err
        res.send objs

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

app.post \/new-object, (req, res, next) ->
    # just test
    if req.body.url == '404'
        res.status 404 .send "failed."
        return
    if req.body.url == 'wait'
        do
            <- set-timeout _, 5000
            res.send "timeout ok!"
        return

    if req.body._id?
        edit-obj = {} <<< req.body
        id = delete edit-obj._id
        my-object.update {_id:id}, {$set:edit-obj}, ->
            if it then return next it
            res.send "Edit id:#{id} successfully!"
    else
        object = new my-object req.body
        object.save ->
            if it then return next it
            res.send "#{req.body.name} saved successfully."

app.post \/delete-items, (req, res, next) ->
    #console.log req.body['items[]']
    items = req.body['items[]']
    if items
        items = [items] if not Array.isArray items
    else
        return res.send "No item was deleted."

    my-object.remove {_id:{$in:items}}, ->
        if it then return next it
        res.send "Delete #{items.length} items successfully!"

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
