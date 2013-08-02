define ->
  jqueryCookie = require 'jqueryCookie'
  jqueryBase64 = require 'jqueryBase64'
  appConfig = require 'appConfig'
  utils = require 'lib/utils'
  Model = require 'models/base/model'
  User = require 'models/user'
  Defect = require 'models/defect'
  Task = require 'models/task'
  UserStory = require 'models/user_story'
  UserProfile = require 'models/user_profile'
  Schema = require 'collections/schema'
  Iterations = require 'collections/iterations'
  Projects = require 'collections/projects'

  class Session extends Model
    initialize: ->
      super
      @pagesize = 200
      @set
        user: new User()
        mode: $.cookie('mode') || 'team'
        boardField: $.cookie('boardField') || 'ScheduleState'
        securityToken: window.sessionStorage.getItem 'token'
      @listenTo this, 'change:user', @_onUserChange
      @listenTo this, 'change:mode', @_onModeChange
      @listenTo this, 'change:boardField', @_onBoardFieldChange
      @listenTo this, 'change:project', @_onProjectChange
      @listenTo this, 'change:iteration', @_onIterationChange

    authenticated: (cb) ->
      if !@get('securityToken')
        return cb? false

      @fetchUserInfo (err, model) =>
        cb? !err?

    authenticate: (username, password, cb) ->
      $.ajax(
        url: "#{appConfig.almWebServiceBaseUrl}/webservice/@@WSAPI_VERSION/security/authorize"
        type: 'GET'
        dataType: 'json'
        xhrFields:
          withCredentials: true
        beforeSend: (xhr) ->
          xhr.setRequestHeader("Authorization", """Basic #{$.base64.encode(username + ':' + password)}""")
          xhr.setRequestHeader("X-Requested-By", "Rally")
          xhr.setRequestHeader("X-RallyIntegrationName", appConfig.appName)
        success: (data, status, xhr) =>
          if data.OperationResult.Errors.length > 0
            return cb? false

          @setSecurityToken data.OperationResult.SecurityToken

          @fetchUserInfo (err, model) =>
            cb? !err?
        error: (xhr, errorType, error) =>
          cb? false
      )

    hasProjectCookie: ->
      !!$.cookie('project')

    getIterationCookie: ->
      projectOid = utils.getOidFromRef @get('project').get('_ref')
      iterationProp = "iteration-#{projectOid}"
      $.cookie(iterationProp)

    setIterationCookie: (value) ->
      projectOid = utils.getOidFromRef @get('project').get('_ref')
      iterationProp = "iteration-#{projectOid}"
      if value
        $.cookie(iterationProp, value, path: '/')
      else
        $.removeCookie(iterationProp, path: '/')

    getProjectName: ->
      try
        @get('project').get('_refObjectName')
      catch e
        ""

    isSelfMode: -> @get('mode') == 'self'
    isTeamMode: -> @get('mode') == 'team'

    setSecurityToken: (securityToken) ->
      @set 'securityToken', securityToken
      window.sessionStorage.setItem 'token', if securityToken then securityToken else ''

    getSecurityToken: ->
      @get 'securityToken'

    logout: (options = {}) ->
      @setSecurityToken null

      $.ajax(
        url: "#{appConfig.almWebServiceBaseUrl}/resources/jsp/security/clear.jsp"
        type: 'GET'
        dataType: 'html'
        beforeSend: (xhr) ->
          xhr.setRequestHeader("X-Requested-By", "Rally")
          xhr.setRequestHeader("X-RallyIntegrationName", appConfig.appName)
      )
          
    fetchUserInfo: (cb) ->
      u = new User()
      u.fetch
        url: "#{u.urlRoot}:current"
        headers:
          "X-Requested-By": "Rally"
          "X-RallyIntegrationName": appConfig.appName
        params:
          fetch: 'ObjectID,DisplayName,UserProfile'
        success: (model, resp, opts) =>
          @set 'user', model
          cb?(null, model)
        error: (model, resp, options) =>
          cb?('auth', model)

    initColumnsFor: (boardField) ->
      projectOid = utils.getOidFromRef @get('project').get('_ref')
      columnProp = "#{boardField}-columns-#{projectOid}"
      columns = $.cookie(columnProp)

      @setBoardColumns boardField, if columns then columns.split ',' else []
      columns

    getBoardColumns: (boardField = @get('boardField')) ->
      projectOid = utils.getOidFromRef @get('project').get('_ref')
      columns = @get "#{boardField}-columns-#{projectOid}"
      unless columns
        columns = @initColumnsFor boardField

      columns

    toggleBoardColumn: (column, boardField = @get('boardField')) ->
      columnProp = "#{boardField}-columns"
      shownColumns = @getBoardColumns boardField

      newColumns = if _.contains(shownColumns, column)
        _.without(shownColumns, column)
      else
        allowedValues = UserStory.getAllowedValues boardField
        columns = _.pluck(allowedValues, 'StringValue')

        _.intersection(columns, shownColumns.concat([column]))

      @setBoardColumns boardField, newColumns

    setBoardColumns: (boardField, columns) ->
      projectOid = utils.getOidFromRef @get('project').get('_ref')
      columnProp = "#{boardField}-columns-#{projectOid}"
      $.cookie(columnProp, columns.join(','), path: '/')
      @set columnProp, columns

    _onUserChange: (model, value, options) ->
      projects = new Projects()
      @set 'projects', projects

      userProfile = new UserProfile
        ObjectID: utils.getOidFromRef(@get('user').get('UserProfile')._ref)

      $.when(
        projects.fetch(
          data:
            fetch: 'Name,SchemaVersion'
            pagesize: @pagesize
            order: 'Name'
        ),
        userProfile.fetch()
      ).then (p, u, i) =>
        totalProjectResults = p[0].QueryResult.TotalResultCount
        @_fetchRestOfProjects(projects, totalProjectResults).then =>
          @_setDefaultProject projects, userProfile

    _fetchRestOfProjects: (projects, totalCount) ->
      start = @pagesize + 1
      projectFetches = while totalCount >= start
        fetch = projects.fetch(
          remove: false
          data:
            fetch: 'Name,SchemaVersion'
            start: start
            pagesize: @pagesize
            order: 'Name'
        )
        start += @pagesize
        fetch

      $.when.apply($, projectFetches)

    _setDefaultProject: (projects, userProfile) ->
      if @hasProjectCookie()
        savedProjRef = $.cookie('project')
        savedProject = _.find projects.models, _.isAttributeEqual('_ref', savedProjRef)
        @set('project', savedProject) if savedProject

      if !@get 'project'
        defaultProject = userProfile.get('DefaultProject')?._ref
        proj = projects.find (proj) -> proj.get('_ref') == defaultProject
        @set 'project', proj || projects.first()

    _setIteration: ->
      savedIterationRef = @getIterationCookie()
      if savedIterationRef
        savedIteration = _.find @get('iterations').models, _.isAttributeEqual('_ref', savedIterationRef)
        @set('iteration', savedIteration) if savedIteration

    _loadSchema: (project) ->
      projectRef = project.get('_ref')
      projectOid = utils.getOidFromRef projectRef
      projectSchema = project.get('SchemaVersion')

      schema = new Schema()
      schema.url = "#{appConfig.almWebServiceBaseUrl}/schema/@@WSAPI_VERSION/project/#{projectOid}/#{projectSchema}"
      schema.fetch(accepts: json: 'text/plain').then =>
        $.when.apply($, _.map [Defect, Task, UserStory], (model) -> model.updateFromSchema(schema))

    _onModeChange: (model, value, options) ->
      $.cookie('mode', value, path: '/')

    _onBoardFieldChange: (model, value, options) ->
      $.cookie('boardField', value, path: '/')

    _onProjectChange: (model, value, options) ->
      projectRef = value.get('_ref')

      $.cookie('project', projectRef, path: '/')

      iterations = new Iterations()
      @set 'iterations', iterations

      $.when(
        @_loadSchema(value),
        iterations.fetch(
          data:
            fetch: 'Name,StartDate,EndDate'
            pagesize: @pagesize
            order: 'StartDate DESC,EndDate DESC,ObjectID'
            query: "(Project = \"#{projectRef}\")"
        )
      ).then (s, i) =>
        @initColumnsFor @get('boardField')
        @_setIteration()
        @publishEvent "projectready", @getProjectName()

    _onIterationChange: (model, value, options) ->
      iterationRef = value?.get('_ref')
      @setIterationCookie iterationRef
