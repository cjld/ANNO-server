module.exports = {
    # database, directory, item, config
    type: "String"
    name: "String"
    description: "String"
    category: "String"
    url: "String"
    tags: "[String]"
    # annotated, un-annotated, issued
    state: "String"
    marks: "String"
    # config file for directory
    config: "String"
    parent: "mongoose.Schema.Types.ObjectId"
}
