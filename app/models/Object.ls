require! \mongoose

schema = new mongoose.Schema {
    # database, folder, item
    type: String
    name: String
    description: String
    category: String
    url: String
    tags: [String]
    # annotated, un-annotated, issued
    state: String
    parent: mongoose.Schema.Types.ObjectId
}

module.exports = schema
# move schema instantiation to other module
#mongoose.model \Object, schema
