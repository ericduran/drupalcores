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
gulp.task('buildcontributors',  function () {
  return gulp.src('')
    .pipe(shell(['./cores.rb > ../../tmp/index.html'], { 'cwd': './app/bin'}));
});

// Build companies page
gulp.task('buildcompanies', function () {
  return gulp.src('')
    .pipe(shell(['./companies.rb > ../../tmp/companies.html'], { 'cwd': './app/bin'}));
});

// Build companies page
gulp.task('companyinfo', function () {
  return gulp.src('')
    .pipe(shell(['./companies.rb --update-all'], { 'cwd': './app/bin'}));
});

// Build countries page
gulp.task('buildcountries', ['buildjson'], function () {
  return gulp.src('')
    .pipe(shell(['./countries.rb > ../../dist/countries.html'], { 'cwd': './app/bin'}));
});

// Build json data
gulp.task('buildjson', function () {
  return gulp.src('')
    .pipe(shell(['mkdir ../../tmp', './json.rb > ../../tmp/data.json'], { 'cwd': './app/bin'}));
});

// Clean dist assets
gulp.task('cleandist', function(cb) {
  return del(['dist'], cb);
});

// Clean tmp assets
gulp.task('cleantmp', function(cb) {
  return del(['tmp'], cb);
});

// Copy tmp to dist
gulp.task('copytmpdist', function(cb) {
  return gulp.src(['./tmp/**/*'])
    .pipe(gulp.dest('./dist'));
});

// Copy all javascripts
gulp.task('javascripts', function() {
  return gulp.src(paths.scripts)
    .pipe(gulp.dest('tmp/js'));
});

// Copy all static images
gulp.task('images', function() {
  return gulp.src(paths.images)
    // Pass in options to the task
    .pipe(imagemin({optimizationLevel: 5}))
    .pipe(gulp.dest('tmp/images'));
});

// Compile Sass
gulp.task('sass', function() {
  return gulp.src(paths.scss)
    .pipe(sass())
    .pipe(gulp.dest('./tmp/css'));
});

// Parse the html for groups of assets and compress
gulp.task('usemin', ['sass', 'javascripts'], function () {
  return gulp.src('./tmp/*.html')
    .pipe(usemin({
      js: [uglify()],
      css: [minifycss({keepBreaks:true})]
    }))
    .pipe(gulp.dest('tmp/'));
});

// UNCSS
gulp.task('uncss', function() {
  return gulp.src('./css/style.css')
    .pipe(uncss({
      html: ['./tmp/*.html']
    }))
    .pipe(gulp.dest('./css'));
});

// Minify HTML
gulp.task('minifyhtml', function() {
  var opts = {comments:true,spare:true};

  gulp.src('./tmp/*.html')
    .pipe(minifyHTML(opts))
    .pipe(gulp.dest('./tmp'));
});

// The whole shebang
gulp.task('default', function(callback) {
  runSequence(['cleantmp', 'bower', 'drupalcore'],
              'buildjson',
              ['buildcontributors', 'buildcompanies', 'buildcountries', 'javascripts', 'images', 'sass'],
              'usemin',
              'minifyhtml',
              'cleandist',
              'copytmpdist',
              callback);
});

// Run contributors only, because companies can take ages the first time
gulp.task('contributors', function(callback) {
  runSequence(['cleantmp', 'bower', 'drupalcore'],
              'buildjson',
              ['buildcontributors', 'javascripts', 'images', 'sass'],
              'usemin',
              'minifyhtml',
              'cleandist',
              'copytmpdist',
              callback);
});
