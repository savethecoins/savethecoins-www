module.exports = (grunt) ->

  require("load-grunt-tasks") grunt
  require("time-grunt") grunt

  # CONFIGS
  config = require('./config/config')()

  # Grunt set up
  grunt.initConfig

    # Clean directories
    clean:
      dev: [".tmp", ".sass-cache"]

    # Compile Coffee
    coffee:
      dev:
        files:
          ".tmp/scripts/app.js": "#{config.client}/scripts/app/{,*/}*.coffee"
      prod:
        files: [
          src: "#{config.client}/scripts/app/{,*/}*.coffee"
          dest: "#{config.build}/scripts/app.js"
        ]

    # Compile Jade
    jade:
      dev:
        options:
          pretty: true
          data: config
        files: [
          expand: true
          cwd: "#{config.client}"
          src: "{,*/}*.jade"
          dest: ".tmp"
          ext: ".html"
        ]
      stage:
        options:
          pretty: true
          data: () -> require('./config/config')('staging')
        files: [
          expand: true
          cwd: "#{config.client}"
          src: "{,*/}*.jade"
          dest: "#{config.build}"
          ext: ".html"
        ]
      prod:
        options:
          pretty: true
          data: () -> require('./config/config')('production')
        files: [
          expand: true
          cwd: "#{config.client}"
          src: "{,*/}*.jade"
          dest: "#{config.build}"
          ext: ".html"
        ]

    # Compiles Styles
    compass:
      options:
        sassDir: "#{config.client}/styles"
        imagesDir: "#{config.client}/img"
        javascriptsDir: "#{config.client}/scripts"
        fontsDir: "#{config.client}/fonts"
        importPath: "#{config.client}/bower_components"
        httpImagesPath: "/img"
        httpGeneratedImagesPath: "/img/generated"
        httpFontsPath: "/fonts"
        relativeAssets: true
      dev:
        options:
          cssDir: ".tmp/styles"
          generatedImagesDir: ".tmp/img/generated"
          debugInfo: true
      prod:
        options:
          cssDir: "#{config.build}/styles"
          generatedImagesDir: "#{config.build}/img/generated"
          # javascriptsDir: "#{config.build}/scripts"
          # fontsDir: "#{config.build}/fonts"
          # importPath: "#{config.build}/bower_components"
          outputStyle: "compressed"
    less:
      dev:
        files:
          ".tmp/styles/bootstrap.css": "#{config.client}/styles/bootstrap/bootstrap.less"
      prod:
        options:
          compress: true
          # cleancss: true
        files: [
          src: "#{config.client}/styles/bootstrap/bootstrap.less"
          dest: "#{config.build}/styles/bootstrap.css"
        ]

    # Copy everthing else
    copy:
      dev:
        files: [
          expand: true
          cwd: "#{config.client}/scripts/vendor"
          src: "{,*/}*.js"
          dest: ".tmp/scripts/vendor"
        ,
          expand: true
          cwd: "#{config.client}/fonts"
          src: "*"
          dest: ".tmp/fonts"
        ]
      prod:
        files: [
          expand: true
          dot: true
          cwd: "#{config.client}"
          dest: "#{config.build}"
          src: [
            "*.{ico,png,txt}"
            ".htaccess"
            "bower_components/**/*"
            "img/{,*/}*"
            "fonts/*"
          ]
        ,
          expand: true
          cwd: "#{config.client}/scripts/vendor"
          src: "{,*/}*.js"
          dest: "#{config.build}/scripts/vendor"
        ]



    # Run parallel tasks
    concurrent:
      dev: [
        "coffee:dev"
        "jade:dev"
        "compass:dev"
        "less:dev"
        "copy:dev"
      ]
      stage: [
        "coffee:prod"
        "jade:stage"
        "compass:prod"
        "less:prod"
        "copy:prod"
      ]
      prod: [
        "coffee:prod"
        "jade:prod"
        "compass:prod"
        "less:prod"
        "copy:prod"
      ]


    ngmin:
      prod: # "#{config.build}/scripts/app.js"
        files: [
          # expand: true
          # cwd: "#{config.build}/scripts"
          src: "#{config.build}/scripts/app.js"
          dest: "#{config.build}/scripts/app.js"
        ]

    uglify:
      prod:
        files: [
          src: "#{config.build}/scripts/app.js"
          dest: "#{config.build}/scripts/app.js"
        ]

    cdnify:
      prod:
        html: ["#{config.build}/*.html"]


    # Run Express App
    express:
      options:
        cmd: "node_modules/coffee-script/bin/coffee"
        port: config.port
      dev:
        options:
          script: "server.coffee"
      stage:
        options:
          script: "server.coffee"
          node_env: "staging"
      prod:
        options:
          script: "server.coffee"
          node_env: "production"


    # Open browser
    open:
      dev:
        url: "http://localhost:#{config.port}"

    # Watch for changes during dev
    watch:
      express:
        files: [
          "server.coffee"
          "server/{,*//*}*.{js,json,coffee}"
          "config/{,*//*}*.{js,json,coffee}"
        ]
        tasks: ["express:dev"]
        options:
          livereload: config.livereload
          nospawn: true
      jade:
        files: ["#{config.client}/{,*/}*.jade", "config/config.coffee"]
        tasks: ["jade:dev"]
      compass:
        files: ["#{config.client}/styles/{,*/}*.{scss,sass}"]
        tasks: ["compass:dev"]
      less:
        files: ["#{config.client}/styles/{,*/}*.less"]
        tasks: ["less:dev"]
      coffee:
        files: ["#{config.client}/scripts/app/{,*/}*.coffee"]
        tasks: ["coffee:dev"]
      others:
        files: ["#{config.client}/scripts/vendor/{,*/}*.js"]
        tasks: ["copy:dev"]
      livereloadStyles:
          options:
            livereload: config.livereload
          files: [".tmp/**/*"]
      # livereloadStyles:
      #     options:
      #       livereload: config.livereload
      #     files: [".tmp/styles/*"]



  grunt.registerTask "express-keepalive", "Keep grunt running", ->
    @async()


  # Launch Dev Server
  grunt.registerTask "dev", (target) ->
    tasks = [
      "clean"
      "concurrent:dev"
      "express:dev"]
    tasks.push "open" if target is 'open'
    tasks.push "watch"
    grunt.task.run tasks


  # Run server and open browser by default
  grunt.registerTask "default", [
    "dev:open"
  ]


  # Build app
  grunt.registerTask "build", (target) ->
    tasks = [
      "clean"
      "concurrent:#{target}"
      "ngmin"
      "uglify"
      "cdnify"
    ]
    grunt.task.run tasks


  # Staging
  grunt.registerTask "stage", [
    "build:stage"
    "express:stage"
    "open"
    "express-keepalive"
  ]

  # Production
  grunt.registerTask "prod", [
    "build:prod"
    "express:prod"
    "open"
    "express-keepalive"
  ]
