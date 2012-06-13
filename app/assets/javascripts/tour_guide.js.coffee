jQuery ->
  BASE_URL = "http://localhost:3004"

  class Tip extends Backbone.Model
    defaults:
      x_offset: 0
      y_offset: 0
      parent: ""
      description: "Type description here"
      direction: "right"

    toJSON: ->
      return {
        x_offset:    @get 'x_offset'
        y_offset:    @get 'y_offset'
        parent:      @get 'parent'
        description: @get 'description'
        direction:   @get 'direction'
        num:         @get 'num'
      }

  class TipView extends Backbone.View

  class TipItemView extends Backbone.View
    tagName: 'li'
    className: 'tour-guide-tip'

    events:
      'click .delete': 'remove'

    initialize: ->
      _.bindAll @

      @model.bind 'change', @render
      @model.bind 'remove', @unrender

    render: ->
      $(@el).html """
        <span>#{@model.get 'num'}. #{@model.get 'description'}</span>
        <a href='#' class='delete'>x</a>
      """

      @

    unrender: ->
      $(@el).remove()

    remove: ->
      @model.destroy()

  class TipList extends Backbone.Collection
    localStorage: new Backbone.LocalStorage("TourGuide.TipList")
    model: Tip

    renumber: ->
      num = 1
      @each (model) ->
        model.set 'num', num
        num += 1

  class TipView extends Backbone.View
    tagName: 'div'
    className: 'tour-guide'

    initialize: ->
      _.bindAll @

    render: ->
      $(@el).html """
        <div class='tour-guide-number'>#{@model.get 'num'}</div>
        <div class='tour-guide-text #{@model.get 'direction'}'>
          <div class='tour-guide-content' contenteditable='true'>#{@model.get 'description'}</div>
          <div class='tour-guide-triangle'></div>
        </div>
      """

      $(@el).css(left: @model.get('x_offset'), top: @model.get('y_offset'))

      parent = @parent()
      parent.css position: "relative" if parent.css("position") is "static"
      parent.append @el

      @adjustTextAlignment()

      @

    parent: ->
      $(@model.get 'parent')

    adjustTextAlignment: ->
      textEl = $(@el).find('div.tour-guide-text')
      if @model.get('direction') is "left" or @model.get('direction') is "right"
        textEl.css marginTop: textEl.height() / -2
      else
        textEl.css marginTop: "auto"

  class EditableTipView extends TipView
    initialize: ->
      super

      @model.bind 'change:direction', @render
      @model.bind 'change:num', @render
      @model.bind 'remove', @unrender

    render: ->
      super
      $(@el).addClass 'editing'

      @offsetBox = $("<div class='tour-guide-offset-box'><div>&middot;</div></div>")
      @parent().append @offsetBox

      if @model.get('parent') is ''
        @chooseElement()

      @

    events:
      'click     .tour-guide-number':   "nothing"
      'mousedown .tour-guide-number':   "move"
      'mousedown .tour-guide-triangle': "changeDirection"
      'click     .tour-guide-content':  "nothing"
      'keyup     .tour-guide-content':  "setDescription"

    unrender: ->
      $(@el).remove()
      @offsetBox.remove()

    setDescription: ->
      @model.set 'description', $(@el).find('.tour-guide-content').text()
      @adjustTextAlignment()

    changeDirection: (e) ->
      return  unless $(e.target).hasClass("tour-guide-triangle")
      e.preventDefault()
      e.stopPropagation()

      $(@el).find(".tour-guide-content").blur()

      x = e.clientX
      y = e.clientY

      dragging = (e) =>
        deltaX = e.clientX - x
        deltaY = e.clientY - y

        if deltaX < -10
          @model.set 'direction', 'left'
        else if deltaX > 10
          @model.set 'direction', 'right'
        else if deltaY < -10
          @model.set 'direction', 'top'
        else if deltaY > 10
          @model.set 'direction', 'bottom'

        [x, y] = [e.clientX, e.clientY] if Math.abs(deltaX) > 10 or Math.abs(deltaY) > 10

      mouseup = (e) =>
        e.preventDefault()
        e.stopPropagation()
        $(document).unbind 'selectstart', @nothing
        $(document).unbind "mousemove", dragging

      $(document).bind 'selectstart', @nothing
      $(document).mousemove dragging
      $(document).mouseup mouseup

    chooseElement: ->
      $(@el).detach()
      @offsetBox.detach()

      allQuery = "div, span, h1, h2, h3, h4, h5, h6, body, p, a, article, b, blockquote, button, caption, cite, code, dd, dl, dt, em, fieldset, footer, form, header, i, label, legend, li, menu, nav, ol, pre, q, s, section, small, sub, sup, table, tbody, td, tfoot, th, thead, u, ul"
      all = $(allQuery)

      pointer = $("<div class='tour-guide-pointer'></div>").appendTo("body")
      pointer.css(top: window.mousePositionY - 25, left: window.mousePositionX + 20)
      pointer.show('scale')

      mouseover = (event) ->
        $(event.target).addClass "guide-outline-element"

      mouseout = (event) ->
        $(event.target).removeClass "guide-outline-element"

      mousemove = (event) ->
        pointer.css(top: event.clientY - 25, left: event.clientX + 20)

      placeTip = (event) =>
        event.preventDefault()
        event.stopPropagation()

        # If the hovered element doesn't support sub-elements, check its parent
        unless $(event.target).filter(allQuery).length
          event.target = $(event.target).parent().get(0)
          return placeTip(event)

        @model.set 'parent', @uniqueSelector($(event.target))

        clearPlacementBox()

        @render()

      clearPlacementBox = ->
        pointer.remove()
        all.removeClass "guide-outline-element"
        all.unbind("mouseover", mouseover).unbind("mouseout", mouseout).unbind "click", placeTip
        $(document).unbind 'mousemove', mousemove

      setTimeout ->
        all.mouseover(mouseover).mouseout(mouseout).click placeTip
        $(document).mousemove mousemove
        $(document).keydown (e) ->
          clearPlacementBox() if e.which == 27
      , 1

    uniqueSelector: (target) ->
      uniqueFor = (el) ->
        return "#" + el.attr("id")  if el.attr("id")
        query = el.get(0).tagName.toLowerCase()
        if el.attr("class")
          for klass in el.attr("class").split(" ")
            continue  if klass is "guide-outline-element"
            continue  if klass is "clear"
            continue  if klass is "clearfix"
            query += ".#{klass}"

        query += "[name=#{el.attr('name')}]" if el.attr("name")
        query = "#{uniqueFor(el.parent())} > #{query}"  if $(query).length > 1 and el.parent().length
        query += ":nth(#{$(query).index(el)})" if $(query).length > 1
        query

      target = $(target)
      uniqueFor target


    movements: {}

    move: (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()

      @offsetBox.show()
      @movements.originalX = parseInt($(@el).css("left"))
      @movements.originalY = parseInt($(@el).css("top"))
      @movements.x = e.clientX
      @movements.y = e.clientY

      $(document).mousemove @dragging
      $(document).bind 'selectstart', @disableEvent
      $(document).mouseup @finishMove

    finishMove: (e) ->
      e.preventDefault()
      e.stopPropagation()

      @offsetBox.hide()
      @model.set 'x_offset', parseInt $(@el).css('left')
      @model.set 'y_offset', parseInt $(@el).css('top')

      $(document).unbind 'selectstart', @disableEvent
      $(document).unbind 'mousemove',   @dragging


    nothing: (e) ->
      e.preventDefault()
      e.stopPropagation()
      false

    dragging: (e) ->
      deltaX = @movements.originalX + e.clientX - @movements.x
      deltaY = @movements.originalY + e.clientY - @movements.y
      $(@el).css
        left: deltaX
        top: deltaY

      @offsetBox.css
        width: Math.abs(deltaX + 20)
        height: Math.abs(deltaY + 20)
        borderTop: (if (deltaX + 20 < 0) then "1px dashed #999" else 0)
        borderBottom: (if (deltaX + 20 > 0) then "1px dashed #999" else 0)
        borderRight: (if (deltaY + 20 < 0) then "1px dashed #999" else 0)
        borderLeft: (if (deltaY + 20 > 0) then "1px dashed #999" else 0)
        left: (if (deltaX + 20 < 0) then "auto" else 0)
        right: (if (deltaX + 20 > 0) then "auto" else "100%")
        top: (if (deltaY + 20 < 0) then "auto" else 0)
        bottom: (if (deltaY + 20 > 0) then "auto" else "100%")

      @offsetBox.find("div").css
        top: (if (deltaY + 20 > 0) then 0 else "auto")
        bottom: (if (deltaY + 20 < 0) then 0 else "auto")
        left: (if (deltaX + 20 > 0) then 0 else "auto")
        right: (if (deltaX + 20 < 0) then 0 else "auto")
        marginTop: (if (deltaY + 20 > 0) then -2 else 0)
        marginBottom: (if (deltaY + 20 < 0) then 2 else 0)
        marginLeft: (if (deltaX + 20 > 0) then -6 else 0)
        marginRight: (if (deltaX + 20 < 0) then -6 else 0)


  class TipItemListView extends Backbone.View
    tagName: 'div'
    className: 'tour-guide-tips'

    events:
      'click .tour-guide-add-tip': 'addTip'
      'click .tour-guide-save'   : 'save'

    initialize: (@collection) ->
      _.bindAll @
      @collection.bind 'add', @appendTipItem
      @collection.bind 'add', @appendTip
      @collection.bind 'reset', @render

      @render()

    save: (e) ->
      e.preventDefault()

      tipData = tip_list: JSON.stringify @collection.toJSON()

      $.post "#{BASE_URL}/tip_lists/#{tourGuideTipListId}", tip_list: tipData, _method: 'put', (data) ->
        console.log data

    addTip: (e) ->
      $("a.tour-guide-save").show()

      # Hack, for remembering the cursor position
      window.mousePositionX = e.clientX
      window.mousePositionY = e.clientY

      tip = new Tip
      tip.bind 'remove', @renumber
      tip.set(num: @collection.length + 1)
      @collection.add tip

    addAll: ->
      @collection.each @appendTipItem
      @collection.each @appendTip

    appendTip: (tip) ->
      tipView = new EditableTipView(model: tip)
      tipView.render()

    appendTipItem: (tip) ->
      tipView = new TipItemView(model: tip)
      $(@el).find('ul').append tipView.render().el

    renumber: ->
      @collection.renumber()
      @render()

    render: ->
      $(@el).html """
        <div class='tour-guide-logo'>App Tour Guide</div>
          <ul class='tour-guide-tip-list'></ul>
          </ul>
          <div class='tour-guide-menu-options'>
            <a href='#' class='tour-guide-save' style='display: none;'>Save &rarr;</a>
            <a href='#' class='tour-guide-add-tip'>+ Add tip</a>
          </div>
        </div>
      """
      $("body").append @el
      @addAll()
      $("a.tour-guide-save").show() if @collection.length

      @

  tourGuideTipListId=1

  $("head").append("<link rel='stylesheet' href='#{BASE_URL}/assets/tour_guide.css'/>");

  $.getJSON "#{BASE_URL}/tip_lists/#{tourGuideTipListId}", (tipData) ->
    window.tips = new TipList
    tipItemListView = new TipItemListView(tips)
    tips.reset tipData.tips
