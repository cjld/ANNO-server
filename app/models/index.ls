require! \mongoose
require! \mongoose-random

model-names = [ \User, \Commen ]
models = {}
model-names.map ->
    schema = require './'+it
    models[it] = mongoose.model it, schema
obj-schema = require \./Object .object
obj-schema.plugin mongoose-random, path: \r
models[\Object] = mongoose.model \Object, obj-schema
module.exports = models
