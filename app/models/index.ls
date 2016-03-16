require! \mongoose

model-names = [ \Object ]
models = {}
model-names.map ->
    schema = require './'+it
    models[it] = mongoose.model it, schema

module.exports = models
