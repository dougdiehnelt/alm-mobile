View = require('./view')
template = require('./templates/login')

module.exports = View.extend
  id: 'login-view'
  template: template
  events:
    'click .sign-in': 'signIn'

  signIn: (event) ->
    username = this.$('#username')[0]
    password = this.$('#password')[0]
    $.ajax(
      url: '/login'
      type: 'POST'
      dataType: 'json'
      data:
        username: username.value
        password: password.value
      success: (data, status, xhr) ->
        debugger
      error: (xhr, errorType, error) ->
        debugger
    )

    event.preventDefault()
