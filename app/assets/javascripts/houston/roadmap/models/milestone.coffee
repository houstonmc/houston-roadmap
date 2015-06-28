class Roadmap.Milestone extends Backbone.Model
  urlRoot: '/roadmap/milestones'
  
  initialize: ->
    super
    _.bindAll(@, 'clearChangesSinceSave', 'revert')
    @clearChangesSinceSave()
  
  save: (attrs, options)->
    success = options?.success
    options.success = (response)=>
      @trigger('save:success', @)
      success(@, response) if success
      @clearChangesSinceSave()
    @trigger('save', @)
    super
  
  duration: ->
    Math.floor((@get('endDate') - @get('startDate')) / Duration.DAY).days()
  
  clearChangesSinceSave: ->
    @_originalAttributes = _.clone @attributes
  
  revert: ->
    @set(@_originalAttributes) if @_originalAttributes
  
  changesSinceSave: ->
    changes = {}
    for attribute, value of @attributes
      originalValue = @_originalAttributes[attribute]
      changes[attribute] = [originalValue, value] unless _.isEqual(originalValue, value)
    changes
  
  
  
  parse: (milestone)->
    milestone.startDate = App.serverDateFormat.parse(milestone.startDate) if milestone.startDate and !_.isDate(milestone.startDate)
    milestone.endDate = App.serverDateFormat.parse(milestone.endDate) if milestone.endDate and !_.isDate(milestone.endDate)
    milestone
  
  toJSON: (options)->
    json = super(options)
    json.cid = @cid
    if 'emulateHTTP' of (options || {})
      json.start_date = App.serverDateFormat(json.startDate) if json.startDate
      delete json.startDate
      json.end_date = App.serverDateFormat(json.endDate) if json.endDate
      delete json.endDate
    json

class Roadmap.Milestones extends Backbone.Collection
  model: Roadmap.Milestone
  
  start: -> _.min @pluck('startDate')
  end: -> _.max @pluck('endDate')
  
  revert: ->
    i = 0
    while i < @length
      milestone = @models[i]
      if milestone.get('id')
        milestone.revert()
        i++
      else
        @remove(milestone)
  
  changes: ->
    for milestone in @models when !milestone.id or _.keys(changes = milestone.changesSinceSave()).length > 0
      if milestone.id
        change = id: milestone.id
        for attribute, [originalView, newValue] of changes
          [attribute, newValue] = ['start_date', App.serverDateFormat(newValue)] if attribute is 'startDate'
          [attribute, newValue] = ['end_date', App.serverDateFormat(newValue)] if attribute is 'endDate'
          change[attribute] = newValue 
        change
      else
        milestone.toJSON(emulateHTTP: true)
