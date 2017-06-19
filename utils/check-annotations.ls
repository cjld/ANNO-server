require! {
    \../config
    \mongoose
    \../app/models : {User, Object: my-object}
}

mongoose.connect config.database
mongoose.connection.on \error ->
    console.log 'Error: Could not connect to MongoDB. Did you forget to run `mongod`?'


add-origin = (id, obj) ->
    if not obj.originImage
        return
    (err, doc) <- my-object.find-by-id obj.originImage
    if err
        console.error err
        return
    if not doc.annotations
        doc.annotations = [id]
    else
        i = doc.annotations.index-of id
        if i==-1
            doc.annotations.push id
    doc.save!

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
    if doc.originImage
        (err, doc2) <- my-object.find-one _id:doc.originImage
        if err
            console.error err
            return
        if doc2
            if not doc2.annotations
                console.log \fix, doc._id
                doc2.annotations = [doc._id]
            else
                ii = doc2.annotations.index-of doc._id
                if ii==-1
                    console.log \fix, doc._id
                    doc2.annotations.push doc._id
            doc2.save!
        else
            doc.originImage = undefined
            console.log doc
            console.log "originImage not found"
            doc.save!
        handle i+1
    else
        handle i+1
handle 0
