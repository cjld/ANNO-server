require! \mongoose
require! \./raw

eval-raw = { [k,eval(v)] for k,v of raw }

schema = new mongoose.Schema eval-raw

module.exports = schema
# move schema instantiation to other module
#mongoose.model \Object, schema
