require! {
    \../config
    \mongoose
    \../app/models : {User}
}

mongoose.connect config.database
mongoose.connection.on \error ->
    console.log 'Error: Could not connect to MongoDB. Did you forget to run `mongod`?'

args = process.argv.slice 2

console.log args
if args[0] == \id
    query = _id: args[1]
else if args[0] == \name
    query = 'profile.name': args[1]
else if args[0] == \email
    query = 'profile.email': args[1]

if query
    (err, user) <- User.find-one query
    if not err and user
        console.log user.profile
        console.log "is admin " + user.local.is-admin
        user.local.is-admin = 1
        user.save (err) ->
            if not err
                console.log \saved.
            else
                console.error err
            process.exit 0
    else
        process.exit 1
else
    console.log "{id|name|email} {value}"
    process.exit 1
