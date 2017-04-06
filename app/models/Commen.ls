require! \mongoose

commen = new mongoose.Schema do
    owner: {type: mongoose.Schema.Types.ObjectId, ref:\User}
    object: {type: mongoose.Schema.Types.ObjectId, ref:\Object}
    content: String

module.exports = commen
