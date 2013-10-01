define ->
  SiteController = require 'controllers/base/site_controller'
  ShowView = require 'views/detail/user_story_show_view'
  CreateView = require 'views/detail/user_story_create_view'

  class UserStoryDetailController extends SiteController
    show: (params) ->
      @whenLoggedIn ->
        @view = new ShowView oid: params.id

    create: (params) ->
      @whenLoggedIn ->
        @view = new CreateView autoRender: true