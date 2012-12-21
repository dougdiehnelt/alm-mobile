View = require 'views/view'
FieldView = require 'views/field/field_view'

DynamicFieldViews =
  'field_toggle_view': require 'views/field/field_toggle_view'

ENTER_KEY = 13

module.exports = class DetailView extends View
  initialize: (options) ->
    super options
    @_defineFieldEditFns field for field in @_getFieldNames()
    @fieldViews = {}
    @model = new @modelType(ObjectID: options.oid)
    @model.fetch({
      data:
        fetch: ['ObjectID'].concat(@_getFieldNames()).join ','
      success: (model, response, opts) =>
        @delegateEvents()
        @render() if options.autoRender
    })

  events: ->
    listeners = 
      'blur input': 'onBlur'
      'blur textarea': 'onBlur'
      'keydown input': 'onKeyDown'
      'click .clear-pill': 'onClearClick'
    listeners["click ##{key}View.display"] = "startEdit#{key}" for key of @model.attributes when @fieldIsEditable(key)
    listeners

  getRenderData: ->
    model: @model.toJSON()

  afterRender: ->
    @renderField field for field in @fields

  remove: ->
    super
    fieldView.remove() for key, fieldView of @fieldViews

  onBlur: (event) ->
    @endEdit event

  onKeyDown: (event) ->
    @endEdit(event) if event.which is ENTER_KEY

  onClearClick: (event) ->
    modelUpdates = null
    if @model.get('Blocked')
      modelUpdates =
        Blocked: false
    if @model.get('Ready')
      modelUpdates ?=
        Ready: false
    @_saveModel modelUpdates if modelUpdates?

  endEdit: (event) ->
    value = event.target.value
    field = event.target.id
    event.preventDefault()
    if @model.get(field) isnt value
      modelUpdates = {}
      modelUpdates[field] = value
      @_saveModel modelUpdates
    else
      @_switchToViewMode()

  fieldIsEditable: (field) ->
    return false unless field in @_getFieldNames()
    if field in ['FormattedID'] then false else true

  renderField: (field) ->
    [fieldName, viewType, label, value] = @_getFieldInfo(field)
    FieldViewClass = DynamicFieldViews["field_#{viewType}_view"] || FieldView
    @fieldViews[fieldName] = fieldView = new FieldViewClass(
      model: @model
      field: fieldName
      viewType: viewType
      label: label
      value: value
      el: this.$("##{fieldName}View")
      detailView: @
    ).render()

    fieldView.on('save', @_onFieldSave, @)

  _defineFieldEditFns: (field) ->
    unless @["startEdit#{field}"]?
      @["startEdit#{field}"] = ->
        @_startEdit(field)

  _startEdit: (field) ->
    fieldName = @_getFieldInfo(field)[0]
    @fieldViews[fieldName].startEdit()

  _onFieldSave: (field, model) ->
    @trigger 'fieldSave', field, model

  _getFieldInfo: (field) ->
    if typeof field is 'object'
      [fieldName, viewType] = ([key, value] for key, value of field)[0]
      if typeof viewType is 'object'
        label = viewType.label
        fieldValue = viewType.value
        viewType = viewType.view
      else
        label = fieldName
    else
      fieldName = field
      viewType = null
      label = field
    [fieldName, viewType, label, fieldValue]

  _getFieldNames: ->
    (@_getFieldInfo(field)[0] for field in @fields)
    