require! {
    \mongoose
    \bcrypt-nodejs : \bcrypt
}
schema = new mongoose.Schema do
    profile:
        name: String
        email: String
        googleId: String
    local:
        email: String
        password: String
        code: String
        is-admin: Boolean
    google:
        id: String
        token: String
        email: String
        name: String
        profile: mongoose.Schema.Types.Mixed


schema.methods.generate-hash = ->
    bcrypt.hash-sync it, bcrypt.gen-salt-sync!

schema.methods.valid-password = ->
    bcrypt.compare-sync it, @local.password

module.exports = schema
# move schema instantiation to other module
#mongoose.model \Object, schema
