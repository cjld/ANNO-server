require! {
    \express
    \morgan
    \body-parser
    \compression
}

app = express!
    ..use morgan \dev
    ..use compression!
    # parse json in body
    ..use body-parser.json limit:\5mb
    # parse urlencoded in body
    # set limit to fix bug
    # <http://stackoverflow.com/questions/19917401/node-js-express-request-entity-too-large>
    ..use body-parser.urlencoded extended:false, limit:\5mb

module.exports = app
