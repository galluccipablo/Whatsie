beeper = require 'beeper'

gulp = require 'gulp'
plumber = require 'gulp-plumber'
sourcemaps = require 'gulp-sourcemaps'
mustache = require 'gulp-mustache'
filter = require 'gulp-filter'
rename = require 'gulp-rename'
header = require 'gulp-header'

less = require 'gulp-less'
babel = require 'gulp-babel'
gif = require 'gulp-if'

embedlr = require 'gulp-embedlr'
livereload = require 'gulp-livereload'
{platform} = require './utils'
manifest = require '../src/package.json'
args = require './args'

[
  ['darwin64', './build/darwin64/' + manifest.productName + '.app/Contents/Resources/app']
  ['linux32', './build/linux32/opt/' + manifest.name + '/resources/app']
  ['linux64', './build/linux64/opt/' + manifest.name + '/resources/app']
  ['win32', './build/win32/resources/app']
].forEach (item) ->
  [dist, dir] = item

  handleError = (err) ->
    console.error err
    beeper()

  # Compile styles
  gulp.task 'compile:' + dist + ':styles', ['clean:build:' + dist], ->
    gulp.src './src/styles/**/*.less'
      .pipe plumber handleError
      .pipe less()
      .pipe plumber.stop()
      .pipe gulp.dest dir + '/styles'
      .pipe livereload()

  # Compile scripts
  gulp.task 'compile:' + dist + ':scripts', ['clean:build:' + dist], ->
    excludeHeaderFilter = filter ['**/*', '!**/logger.js', '!**/file-logger.js', '!**/init.js'], { restore: true }
    loggerHeader = [
      "var log = require('common/utils/logger').default.debugLogger(__filename);"
      "var logError = require('common/utils/logger').default.errorLogger(__filename, false);"
      "var logFatal = require('common/utils/logger').default.errorLogger(__filename, true);"
    ].join ' '

    gulp.src './src/scripts/**/*.js'
      .pipe plumber handleError
      .pipe gif args.dev, sourcemaps.init()
      .pipe babel
        presets: [
          'es2015'
          'stage-0'
        ]
        plugins: [
          'transform-runtime'
          'default-import-checker'
          'source-map-support-for-6'
        ]
      .pipe gif args.dev, sourcemaps.write {sourceRoot: 'src/scripts'}
      .pipe excludeHeaderFilter
      .pipe header loggerHeader
      .pipe excludeHeaderFilter.restore
      .pipe plumber.stop()
      .pipe gulp.dest dir + '/scripts'

  # Move themes
  gulp.task 'compile:' + dist + ':themes', ['clean:build:' + dist], ->
    gulp.src './src/themes/**/*.css'
      .pipe rename (path) ->
        path.basename = path.basename.toLowerCase()
      .pipe gulp.dest dir + '/themes'
      .pipe livereload()

  # Move images
  gulp.task 'compile:' + dist + ':images', ['clean:build:' + dist], ->
    gulp.src [
      './src/images/**/*.png',
      './src/images/**/*.jpg'
    ]
      .pipe gulp.dest dir + '/images'

  # Move html files
  gulp.task 'compile:' + dist + ':html', ['clean:build:' + dist], ->
    gulp.src './src/html/**/*.html'
      .pipe mustache manifest
      .pipe embedlr
        src: 'http://localhost:35729/livereload.js?snipver=1'
      .pipe gulp.dest dir + '/html'
      .pipe livereload()

  # Move the node modules
  gulp.task 'compile:' + dist + ':deps', ['clean:build:' + dist], ->
    gulp.src './src/node_modules/**/*'
      .pipe gulp.dest dir + '/node_modules'
      .pipe livereload()

  # Move package.json
  gulp.task 'compile:' + dist + ':package', ['clean:build:' + dist], ->
    gulp.src './src/package.json'
      .pipe gulp.dest dir

  # Compile everything
  gulp.task 'compile:' + dist, [
    'compile:' + dist + ':styles'
    'compile:' + dist + ':scripts'
    'compile:' + dist + ':themes'
    'compile:' + dist + ':images'
    'compile:' + dist + ':html'
    'compile:' + dist + ':deps'
    'compile:' + dist + ':package'
  ]

# Compile for the current platform by default
gulp.task 'compile', ['compile:' + platform()]
