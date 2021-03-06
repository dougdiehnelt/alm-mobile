define ->
  app = require 'application'
  SiteController = require 'controllers/base/site_controller'
  DetailControllerMixin = require 'controllers/detail_controller_mixin'
  Defect = require 'models/defect'
  UserStory = require 'models/user_story'
  View = require 'views/detail/defect'

  class DefectDetailController extends SiteController

    _.extend @prototype, DetailControllerMixin

    show: (params) ->
      @whenLoggedIn ->
        @fetchModelAndShowView Defect, View, params.id

    create: (params) ->
      @whenLoggedIn ->
        @showCreateView Defect, View

    defectForStory: (params) ->
      @whenLoggedIn ->
        model = new UserStory(ObjectID: params.id)
        model.fetch
          data:
            fetch: 'FormattedID'
          success: (model, response, opts) =>
            @updateTitle "New Defect for #{model.get('FormattedID')}: #{model.get('_refObjectName')}"
            @showCreateView Defect, View, Requirement: model.attributes

    getFieldNames: ->
      [
        'FormattedID',
        'Name',
        'Owner',
        'Priority',
        'Severity',
        'State',
        'Discussion',
        'Description',
        'Blocked',
        'PlanEstimate',
        'Ready',
        'Requirement',
        'Tasks',
        app.session.get('boardField')
      ]