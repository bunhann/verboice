onWorkflow ->
  class window.CommandSelector
    constructor: ->
      handlers = (new ClassBindingHandler(klass) for klass in step_types)
      @commands = ko.observableArray(handlers)

    display_template_id: () ->
      'command_selector_template'