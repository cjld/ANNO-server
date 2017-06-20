require! {
    \../config
    \mongoose
    \../app/models : {User, Object: my-object}
}

mongoose.connect config.database
mongoose.connection.on \error ->
    console.log 'Error: Could not connect to MongoDB. Did you forget to run `mongod`?'


(err, number) <- my-object.count
console.log \total, number
handle = (i) ->
    if i%100 == 0
        console.log i
    (err, doc)<- my-object.find-one!.skip(i).exec
    if not doc
        console.log \done
        process.next-tick -> process.exit 0
        return

    if doc.marks
        doc.marks_size = that.length
    else
        doc.marks_size = 0
    doc.save!
    handle i+1
handle 0
