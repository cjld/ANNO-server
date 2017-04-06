require! {
    \mongoose
}


mongoose.connect  \mongodb://localhost:27017/pro6
mongoose.connection.on \error ->
    console.log 'Error: Could not connect to MongoDB. Did you forget to run `mongod`?'


#point = new mongoose.Schema {x:Number, y:Number}
points = new mongoose.Schema do
    points:{type:[{x:Number, y:Number}], default: []}

mark = new mongoose.Schema do
    type: String
    state: String
    spots: points
    segments: {type: [points], default: []}
    active-segment: {type: {i:Number, j:Number}}
    contours: {type: [points], default: []}

object = new mongoose.Schema do
    # database, directory, item, config
    type: {type: String, enum: [\item, \directory], default: \item}
    name: {type: String, default: \unname}
    description: String
    category: String
    url: String
    tags: [String]
    # annotated, un-annotated, issued
    state: {type: String, enum: [\annotated, \un-annotated, \issued], default: \un-annotated}
    marks: {type: [mark], default: []}
    # config file for directory
    config: String
    parent: mongoose.Schema.Types.ObjectId


object-model = mongoose.model \object, object
mark-model = mongoose.model \mark, mark

a = new object-model
b = new object-model
console.log \step1
console.log a.to-object!
console.log b.to-object!
a.marks.push {}
b.marks.push a.marks[0]
console.log \step2
console.log a.to-object!
console.log b.to-object!
b.marks[0].type = \asd
console.log \step3
console.log a.to-object!
console.log b.to-object!
c = new mark-model
b.marks.push c
a.marks.push c
console.log \step4
console.log a.to-object!
console.log b.to-object!
c.type = \asdasd
console.log \step5
console.log c
console.log a.to-object!
console.log b.to-object!
a.marks[1].type = \here
console.log \step6
console.log c
console.log a.to-object!
console.log b.to-object!

(err) <- a.save
if err then console.error err
(err) <- b.save
if err then console.error err

(err, a2) <- object-model.findOne {_id:a._id}
if err then console.error err
console.log \find-a2
console.log a2
a2.marks[0].type = \t1
a2.marks[1].type = \t2
(err) <- a2.save
if err then console.log err

(err, b2) <- object-model.findOne {_id:b._id}
console.log \find-b2
console.log b2


process.exit 0

module.exports = {points, mark, object}
# move schema instantiation to o
