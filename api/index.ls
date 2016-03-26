require! {
    \express
    \mongoose
    \async
    \../config
    \../app/models
}

app = express!

my-object = models.Object

mongoose.connect config.database
mongoose.connection.on \error ->
    console.log 'Error: Could not connect to MongoDB. Did you forget to run `mongod`?'

app.get \/test, (req, res) ->
    res.send \ok!

app.use \/list-objects, (req, res, next) ->
    my-object.find {}, (err, objs) ->
        if err then return next err
        res.send objs

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
    console.log req.body['items[]']
    items = req.body['items[]']
    if items
        items = [items] if not Array.isArray items
    else
        return res.send "No item was deleted."

    my-object.remove {_id:{$in:items}}, ->
        if it then return next it
        res.send "Delete #{items.length} items successfully!"

app.post \/counter, (req, res, next) ->
    async.parallel {
        \total : (callback) ->
            my-object.count {}, callback
        \annotated : (callback) ->
            my-object.count {state:'annotated'}, callback
        \un-annotated : (callback) ->
            my-object.count {state:'un-annotated'}, callback
        \issued : (callback) ->
            my-object.count {state:'issued'}, callback
    }, (err, results) ->
        if err then return next err
        res.send results
app.use (req, res) ->
    res.status 404 .send "api #{req.url} not found."

console.log "hello from api."

module.exports = app
