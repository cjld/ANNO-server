require! {
    \gulp
    \gulp-concat
    \gulp-if
    \gulp-uglify
}

production = process.env.NODE_ENV === 'production'

gulp.task \vendor, ->
    gulp.src [
        './bower_components/jquery/dist/jquery.js'
        './bower_components/toastr/toastr.js'
        './bower_components/semantic/dist/semantic.js'
    ]   .pipe gulp-concat \vendor.js
        .pipe gulp-if production, gulp-uglify mangle:false
        .pipe gulp.dest \public/js
