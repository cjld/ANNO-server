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
        './bower_components/toastr/toastr.js'
        './bower_components/semantic/dist/semantic.js'
    ]   .pipe gulp-concat \vendor.js
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp.dest \public/js

gulp.task \vendor-css, ->
    gulp.src [
        './public/css/main.css'
        './bower_components/semantic/dist/semantic.css'
    ]   .pipe gulp-concat \vendor.css
        .pipe gulp.dest \public/css

gulp.task \vendor, [\vendor-js \vendor-css]

require! {
    \gulp-changed
    \gulp-livescript
    \gulp-babel
    \gulp-browserify
    \gulp-rename
}

dependencies = []

gulp.task \compile, ->
    gulp.src \./app/**/*.ls
        .pipe gulp-changed \./app-dest, extension:\.js
        .pipe gulp-livescript bare:true
        .pipe gulp-babel presets:[\es2015, \react]
        .pipe gulp.dest \./app-dest

gulp.task \browserify, [\compile], ->
    gulp.src \./app-dest/main.js
        .pipe do
            gulp-browserify debug:!production .on \prebundle, -> it.external dependencies
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp-rename \bundle.js
        .pipe gulp.dest \./public/js

gulp.task \browserify-vendor, ->
    gulp.src \./app/empty.js
        .pipe do
            gulp-browserify! .on \prebundle, -> it.require dependencies
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp-rename \vendor.bundle.js
        .pipe gulp.dest \./public/js

gulp.task \default, [\vendor \browserify \browserify-vendor]
gulp.task \watch, [\default], ->
    gulp.watch \./**/*.ls, [\browserify]
