require! {
    \express
    \morgan
    \body-parser
}

app = express!
    ..use morgan \dev
    # parse json in body
    ..use body-parser.json limit:\5mb
    # parse urlencoded in body
    # set limit to fix bug
    # <http://stackoverflow.com/questions/19917401/node-js-express-request-entity-too-large>
    ..use body-parser.urlencoded extended:false, limit:\5mb

module.exports = app
