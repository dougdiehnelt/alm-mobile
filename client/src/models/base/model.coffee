define [
  'chaplin'
], (Chaplin) ->

  # Base class for all models.
  class Model extends Chaplin.Model
    idAttribute: 'ObjectID'

    _.extend @prototype, Chaplin.SyncMachine

    parse: (resp) ->
      return resp if resp._ref?
      return resp.OperationResult.Object if resp.OperationResult?
      return resp.CreateResult.Object if resp.CreateResult?
      return (value for key, value of resp)[0] # Get value for only key

    isNew: ->
      !@id? && !@_ref

    fetch: (options) ->
      @beginSync()

      $.when(
        super
      ).done (c) =>
        @finishSync()