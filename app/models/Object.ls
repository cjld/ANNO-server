require! \mongoose

validate_1d =
    validator: (v) ->
        if not v instanceof Array
            return false
        for a in v
            if not a instanceof Object
                return false
            if not a.x instanceof Number
                return false
            if not a.y instanceof Number
                return false
        return true
    message: "Not a valid 1d Array."

validate_2d =
    validator: (v) ->
        if not v instanceof Array
            return false
        for a in v
            if not validate_1d.validator a
                return false
        return true
    message: "Not a valid 2d Array."

mark = new mongoose.Schema do
    *   type: {type:String, default:""}
        state: {type:String, default:""}
        bbox: {p1:{x:Number, y:Number}, p2:{x:Number, y:Number}}
        spots: {type:mongoose.Schema.Types.Mixed, default: [], validate: validate_1d}
        segments: {type: mongoose.Schema.Types.Mixed, default: [], validate: validate_2d}
        active-segment: {type: {i:Number, j:Number}, default:{i:0,j:0}}
        contours: {type: mongoose.Schema.Types.Mixed, default: [], validate: validate_2d}
        strokes: {type: mongoose.Schema.Types.Mixed, default: []}
        paints: {type: mongoose.Schema.Types.Mixed}
    *   _id: false

object = new mongoose.Schema do
    # database, directory, item, config
    type: {type: String, enum: [\item, \directory, \annotation, \task], default: \item}
    name: {type: String, default: \unname}
    # available when item
    description: String
    category: String
    url: String
    tags: [String]
    # annotated, un-annotated, issued
    state: {type: String, enum: [\annotated, \un-annotated, \issued], default: \un-annotated}
    marks: {type: [mark], default: []}
    shape: [Number]
    annotations: {type: [{type: mongoose.Schema.Types.ObjectId, ref:\Object}], default: []}
    # json string {ne:{lat:Number, lng:Number}, sw:{lat:Number, lng:Number}}
    latlngBounds: String
    # worker has permission to change marks
    # worker == undefined in view all
    worker:  {type: mongoose.Schema.Types.ObjectId, ref:\User}
    # owner has permission to edit
    owner: {type: mongoose.Schema.Types.ObjectId, ref:\User}
    crossValidate: {type:Number, default: 1}

    originImage: {type: mongoose.Schema.Types.ObjectId, ref:\Object}
    taskImages: {type: [{type: mongoose.Schema.Types.ObjectId, ref:\Object}], default: []}

    # config file for directory
    config: String
    parent: mongoose.Schema.Types.ObjectId

object.methods.check-permission = (user) ->
    if user.local.is-admin
        return true
    if not @owner
        return true
    if not user.id
        return false
    if user.id.to-string! == @owner.to-string!
        return true
    return false

object.methods.check-worker = (user) ->
    if user.local.is-admin
        return true
    if not @worker
        return true
    if not user.id
        return false
    return user.id.to-string! == @worker.to-string!

seeker = do
    item: <[type name description category url tags state annotations owner worker latlngBounds]>
    directory: <[type name description state worker owner config]>
    annotation: <[type name description state originImage worker owner]>
    task: <[type name description taskImages owner worker crossValidate config]>

module.exports = {object, mark, seeker}
# move schema instantiation to other module
#mongoose.model \Object, schema
