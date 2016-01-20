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
