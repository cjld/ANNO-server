require! {
    \mongoose
    \bcrypt-nodejs : \bcrypt
}
schema = new mongoose.Schema do
    profile:
        name: String
    local:
        email: String
        password: String
    google:
        id: String
        token: String
        email: String
        name: String


schema.methods.generate-hash = ->
    bcrypt.hash-sync it, bcrypt.gen-salt-sync!

schema.methods.valid-password = ->
    bcrypt.compare-sync it, @local.password

module.exports = schema
# move schema instantiation to other module
#mongoose.model \Object, schema
