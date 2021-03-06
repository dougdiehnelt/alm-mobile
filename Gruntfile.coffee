module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-clean'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-requirejs'
  grunt.loadNpmTasks 'grunt-simple-mocha'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-compile-handlebars'
  grunt.loadNpmTasks 'grunt-react'
  grunt.loadNpmTasks 'grunt-recess'
  grunt.loadNpmTasks 'grunt-replace'
  grunt.loadNpmTasks 'grunt-s3'

  grunt.registerTask 'default', ['clean','coffee','react','recess','compile-handlebars', 'copy:js','requirejs','replace','copy','concat']

  grunt.registerTask 'test', ['clean', 'coffee', 'simplemocha']

  grunt.registerTask 'heroku', ['clean','coffee','recess','compile-handlebars', 'copy:js','requirejs','replace','copy','concat']

  grunt.initConfig

    clean: ['client/gen/*', 'client/dist/*', 'sever/gen/*']

    #watch and compile all folders separately for the quickest compile time
    watch:
      clientSrc:
        files: 'client/src/**/*.coffee'
        tasks: ['coffee:clientSrc', 'requirejs:compile', 'replace:js', 'copy:js']

      reactSrc:
        files: 'client/src/views/**/*.jsx'
        tasks: ['react:clientSrc', 'requirejs:compile', 'replace:js', 'copy:js']

      clientStyles:
        files: 'client/styles/**/*.less'
        tasks: ['recess:client', 'concat:css']

      clientIndexHtml:
        files: ['config.json', 'client/src/*.hbs']
        tasks: ['compile-handlebars']

      clientTest:
        files: 'client/test/**/*.coffee'
        tasks: ['coffee:clientTest']

      serverSrc:
        files: 'server/src/**/*.coffee'
        tasks: ['coffee:serverSrc']

    replace:
      js:
        options:
          variables:
            'WSAPI_VERSION': 'v2.0'
          prefix: '@@'
          force: true
        files: [
         expand: true, flatten: true, src: ['client/gen/js/app.js'], dest: 'client/dist/js'
        ]

    coffee:
      clientSrc:
        expand: true
        cwd: 'client/src/'
        src: ['**/*.coffee']
        dest: 'client/gen/js/src'
        ext: '.js'

      clientTest:
        expand: true
        cwd: 'client/test/'
        src: ['**/*.coffee']
        dest: 'client/gen/js/test'
        ext: '.js'

      serverSrc:
        expand: true
        cwd: 'server/src/'
        src: ['**/*.coffee']
        dest: 'server/gen/js/src'
        ext: '.js'

    react:
      clientSrc:
        files: [
          expand: true
          ext: '.js'
          cwd: 'client/src/views'
          src: ['**/*.jsx']
          dest: 'client/gen/js/src/views'
        ]

    requirejs:
      compile:
        options:
          name: 'initialize'
          paths:
            jquery: "empty:"
            bootstrap: "empty:"
            spin: "empty:"
            jqueryBase64: "empty:"
            underscore: "../../../../node_modules/lodash/dist/lodash"
            backbone: "empty:"
            chaplin: "../../../../vendor/scripts/chaplin-0.9.0"
            handlebars: "empty:"
            moment: "empty:"
            appConfig: "empty:"
            md: "../../../../node_modules/html-md/dist/md.min"
            pagedown: "empty:"
            react: "empty:"
          shim:
            appConfig:
              exports: "AppConfig"
          out: 'client/gen/js/app.js'
          baseUrl: 'client/gen/js/src'
          optimize: "none"
          preserveLicenseComments: false
          findNestedDependencies: true
          useStrict: true
          wrap: true

    'compile-handlebars':
      allStatic:
        template: 'client/src/index.hbs'
        templateData: 'config.json'
        output: 'client/dist/index.html'

    recess:
      client:
        options:
          compile: true
        files:
          "client/gen/styles/app.css": ["client/styles/main.less"]

    concat:

      css:
        src: ['client/gen/styles/*.css']
        dest: 'client/dist/css/app.css'

    copy:
      js:
        files:
          'client/dist/js/jquery.base64.min.js': 'vendor/scripts/jquery.base64.min.js'
      assets:
        files: [
          {expand: true, dest: 'client/dist/', cwd: 'client/assets/', src: '**', filter: 'isFile'}
        ]
    uglify:
      js:
        files:
          'client/dist/js/app.min.js' : 'client/dist/js/app.js'

    simplemocha:
      options:
        globals: ['expect']
        ignoreLeaks: true
        timeout: 3000
        ui: 'bdd'
        reporter: 'tap'
      all:
        src: [
          'node_modules/chai/chai.js'
          'client/gen/js/test/**/*.js'
        ]

    aws: grunt.file.readJSON('grunt-aws.json')
    s3:
      options:
        key: '<%= aws.key %>'
        secret: '<%= aws.secret %>'
        bucket: '<%= aws.bucket %>'
        access: 'public-read'
      dev:
        upload: [
          {src: 'client/dist/*', dest: '/'}
          {src: 'client/dist/css/*', dest: 'css/'}
          {src: 'client/dist/font/*', dest: 'font/'}
          {src: 'client/dist/img/*', dest: 'img/'}
          {src: 'client/dist/img/status/*', dest: 'img/status/'}
          {src: 'client/dist/js/*', dest: 'js/'}
        ]
