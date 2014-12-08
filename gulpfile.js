var gulp = require('gulp');
var usemin = require('gulp-usemin');
var concat = require('gulp-concat');
var minifycss = require('gulp-minify-css');
var uglify = require('gulp-uglify');
var imagemin = require('gulp-imagemin');
var sourcemaps = require('gulp-sourcemaps');
var del = require('del');
var sass = require('gulp-sass');

var paths = {
  scripts: 'app/js/**/*.js',
  images: 'app/images/**/*',
  scss: 'app/scss/**/*.scss'
};

gulp.task('clean', function(cb) {
  del(['dist/images', 'dist/js', 'dist/css'], cb);
});

gulp.task('javascripts', ['clean'], function() {
  return gulp.src(paths.scripts)
  .pipe(gulp.dest('dist/js'));
});

// Copy all static images
gulp.task('images', ['clean'], function() {
  return gulp.src(paths.images)
    // Pass in options to the task
    .pipe(imagemin({optimizationLevel: 5}))
    .pipe(gulp.dest('dist/images'));
});

// Compile Sass
gulp.task('sass',  ['clean'], function () {
    gulp.src(paths.scss)
        .pipe(sass())
        .pipe(gulp.dest('dist/css'));
});

gulp.task('usemin', function () {
  return gulp.src('./dist/*.html')
      .pipe(usemin({
        js: [uglify()],
        css: [minifycss({keepBreaks:true})]
      }))
      .pipe(gulp.dest('dist/'));
});

gulp.task('default', ['javascripts', 'images', 'sass']);