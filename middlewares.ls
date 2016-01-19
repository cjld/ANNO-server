require! {
    \express
    \morgan
    \body-parser
}

app = express!
    ..use morgan \dev
    # parse json in body
    ..use body-parser.json!
    # parse urlencoded in body
    ..use body-parser.urlencoded extended:false

module.exports = app
