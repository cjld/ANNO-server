require! \mongoose

model-names = [ \User, \Commen ]
models = {}
model-names.map ->
    schema = require './'+it
    models[it] = mongoose.model it, schema
obj-schema = require \./Object .object
models[\Object] = mongoose.model \Object, obj-schema
module.exports = models
