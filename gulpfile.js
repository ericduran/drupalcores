/*jshint strict:false */
var gulp = require('gulp');
var usemin = require('gulp-usemin');
var minifycss = require('gulp-minify-css');
var uglify = require('gulp-uglify');
var imagemin = require('gulp-imagemin');
var del = require('del');
var sass = require('gulp-sass');
var bower = require('gulp-bower');
var runSequence = require('run-sequence');
var shell = require('gulp-shell');
var minifyHTML = require('gulp-minify-html');
var uncss = require('gulp-uncss');
var jshint = require('gulp-jshint');
var stylish = require('jshint-stylish');
var gulpif = require('gulp-if');

var paths = {
  scripts: 'app/js/**/*.js',
  images: 'app/images/**/*',
  scss: 'app/scss/**/*.scss',
  drupal: 'app/drupalcore'
};

// Run bower install
gulp.task('bower', function() {
  return bower();
});

gulp.task('lint', function() {
  return gulp.src([paths.scripts, 'gulpfile.js'])
    .pipe(jshint())
    .pipe(jshint.reporter(stylish));
});

// Clone or update drupalcore repo
gulp.task('drupalcore', function () {
  var fs = require('fs');

  return gulp.src('')
    .pipe(gulpif(!fs.existsSync(paths.drupal), shell(['git clone --branch 8.0.x http://git.drupal.org/project/drupal.git ' + paths.drupal])))
    .pipe(shell(['git pull'],{ 'ignoreErrors': true, 'cwd': './app/drupalcore'}));
});

// Build contributors page
gulp.task('buildcontributors', ['buildjson'], function () {
  return gulp.src('')
    .pipe(shell(['./cores.rb > ../../dist/index.html'], { 'cwd': './app/bin'}));
});

// Build companies page
gulp.task('buildcompanies', ['buildjson'], function () {
  return gulp.src('')
    .pipe(shell(['./companies.rb > ../../dist/companies.html'], { 'cwd': './app/bin'}));
});

// Build companies page
gulp.task('companyinfo', function () {
  return gulp.src('')
    .pipe(shell(['./companies.rb --update-all'], { 'cwd': './app/bin'}));
});

// Build json data
gulp.task('buildjson', function () {
  return gulp.src('')
    .pipe(shell(['./json.rb > ../../dist/data.json'], { 'cwd': './app/bin'}));
});

// Clean all assets
gulp.task('clean', function(cb) {
  return del(['dist/images', 'dist/js', 'dist/css'], cb);
});

// Copy all javascripts
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
  return gulp.src(paths.scss)
    .pipe(sass())
    .pipe(gulp.dest('dist/css'));
});

// Parse the html for groups of assets and compress
gulp.task('usemin', function () {
  return gulp.src('./dist/*.html')
    .pipe(usemin({
      js: [uglify()],
      css: [minifycss({keepBreaks:true})]
    }))
    .pipe(gulp.dest('dist/'));
});


// UNCSS
gulp.task('uncss', function() {
  return gulp.src('./css/style.css')
    .pipe(uncss({
      html: ['./dist/*.html']
    }))
    .pipe(gulp.dest('./css'));
});

// Minify HTML
gulp.task('minifyhtml', function() {
  var opts = {comments:true,spare:true};

  gulp.src('./dist/*.html')
    .pipe(minifyHTML(opts))
    .pipe(gulp.dest('./dist/'));
});

// The whole shebang
gulp.task('default', function(callback) {
  runSequence(['clean', 'bower', 'drupalcore'],
              ['buildcontributors', 'buildcompanies', 'buildjson', 'javascripts', 'images', 'sass'],
              'usemin',
              'minifyhtml',
              callback);
});

// Run contributors only, because companies can take ages the first time
gulp.task('contributors', function(callback) {
  runSequence(['clean', 'bower', 'drupalcore'],
              ['buildcontributors', 'buildjson', 'javascripts', 'images', 'sass'],
              'usemin',
              'minifyhtml',
              callback);
});
