application = require('application')

module.exports = Backbone.Router.extend
  routes:
    '': 'login'
  home: ->
    $('#content').html(application.homeView.render().el)
  login: ->
    $('#content').html(application.loginView.render().el)
