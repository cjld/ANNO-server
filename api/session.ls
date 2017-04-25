require! {
    \express-session : \session
    \connect-mongo
    \mongoose
}

MongoStore = connect-mongo session
mongo-store = new MongoStore mongooseConnection: mongoose.connection
module.exports = {store:mongo-store}
