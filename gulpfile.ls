require! {
    \gulp
    \gulp-concat
    \gulp-if
    \gulp-uglify
}

production = process.env.NODE_ENV === 'production'

gulp.task \vendor-js, ->
    gulp.src [
        './bower_components/jquery/dist/jquery.js'
        './bower_components/jquery.cookie/jquery.cookie.js'
        './bower_components/jquery-form/dist/jquery.form.min.js'
        './bower_components/toastr/toastr.js'
        './bower_components/semantic/dist/semantic.js'
        './bower_components/jquery-ui/jquery-ui.js'
        './bower_components/js-md5/build/md5.min.js'
        './node_modules/socket.io-client/dist/socket.io.js'
        './public/js/paper-full.js'
        './node_modules/simplify-js/simplify.js'
    ]   .pipe gulp-concat \vendor.js
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp.dest \public/js

gulp.task \vendor-css, ->
    gulp.src [
        './public/css/main.css'
        './bower_components/semantic/dist/semantic.css'
        './bower_components/jquery-ui/themes/base/jquery-ui.css'
        './bower_components/toastr/toastr.css'
    ]   .pipe gulp-concat \vendor.css
        .pipe gulp.dest \public/css

gulp.task \vendor, [\vendor-js \vendor-css]

require! {
    \gulp-changed
    \gulp-livescript
    \gulp-babel
    \gulp-rename
    \browserify
    \through2
}

browserified = ->
    through2.obj (file, enc, next) ->
        b = browserify do
            entries: file.path
            debug: !production
        #b = browserify file.path
        b.bundle (err, res) ->
            if err then return next err
            file.contents = res
            next null, file

gulp.task \compile, ->
    gulp.src \./app/**/*.ls
        .pipe gulp-changed \./app-dest, extension:\.js
        .pipe gulp-livescript bare:false
        .pipe gulp-babel presets:[\es2015, \react]
        .pipe gulp.dest \./app-dest

gulp.task \browserify, [\compile], ->
    gulp.src \./app-dest/main.js
        #.pipe do
        #    gulp-browserify debug:!production .on \prebundle, -> it.external dependencies
        .pipe browserified!
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp-rename \bundle.js
        .pipe gulp.dest \./public/js

gulp.task \browserify-vendor, ->
    gulp.src \./app/empty.js
        #.pipe do
        #    gulp-browserify! .on \prebundle, -> it.require dependencies
        .pipe browserified!
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp-rename \vendor.bundle.js
        .pipe gulp.dest \./public/js

gulp.task \default, [\vendor \browserify \browserify-vendor]
gulp.task \watch, [\default], ->
    gulp.watch \./**/*.ls, [\browserify]
