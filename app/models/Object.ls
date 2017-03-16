require! \mongoose

schema = new mongoose.Schema {
    # database, directory, item, config
    type: String
    name: String
    description: String
    category: String
    url: String
    tags: [String]
    # annotated, un-annotated, issued
    state: String
    marks: String
    # config file for directory
    config: String
    parent: mongoose.Schema.Types.ObjectId
}

module.exports = schema
# move schema instantiation to other module
#mongoose.model \Object, schema
