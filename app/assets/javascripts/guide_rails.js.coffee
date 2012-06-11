$.fn.guideRail = (number, left, top, message, alignment, editing) ->
  div = $("<div class='guide-rail'></div>")
  num = $("<div class='guide-rail-number'></div>")
  num.append number
  div.append num
  alignment = alignment or "top"
  text = $("<div></div>").addClass("guide-rail-text").addClass(alignment)
  content = $("<div></div>").addClass("guide-rail-content")
  content.append message
  text.append content
  triangle = $("<div class='guide-rail-triangle'></div>")
  text.append triangle
  div.append text
  div.css
    left: left
    top: top

  $(this).css position: "relative"  if $(this).css("position") is "static"
  $(this).append div

  if alignment is "left" or alignment is "right"
    text.css marginTop: text.height() / -2
  else
    text.css marginTop: "auto"

  if editing
    div.addClass "editing"
    offsetbox = $("<div class='guide-rail-offset-box'><div>&middot;</div></div>")
    offsetbox.css
      width: Math.abs(left + 20)
      height: Math.abs(top + 20)

    $(this).append offsetbox
    num.click -> false
    num.mousedown (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()

      offsetbox.show()
      originalX = parseInt(div.css("left"))
      originalY = parseInt(div.css("top"))
      x = e.clientX
      y = e.clientY

      disableSelect = (e) ->
        e.preventDefault()
        e.stopPropagation()
        false

      dragging = (e) ->
        deltaX = originalX + e.clientX - x
        deltaY = originalY + e.clientY - y
        div.css
          left: deltaX
          top: deltaY

        offsetbox.css
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

        offsetbox.find("div").css
          top: (if (deltaY + 20 > 0) then 0 else "auto")
          bottom: (if (deltaY + 20 < 0) then 0 else "auto")
          left: (if (deltaX + 20 > 0) then 0 else "auto")
          right: (if (deltaX + 20 < 0) then 0 else "auto")
          marginTop: (if (deltaY + 20 > 0) then -2 else 0)
          marginBottom: (if (deltaY + 20 < 0) then 2 else 0)
          marginLeft: (if (deltaX + 20 > 0) then -6 else 0)
          marginRight: (if (deltaX + 20 < 0) then -6 else 0)

      $(document).mousemove dragging
      $(document).bind 'selectstart', disableSelect
      $(document).mouseup (e) ->
        e.preventDefault()
        e.stopPropagation()

        offsetbox.hide()
        $(document).unbind 'selectstart', disableSelect
        $(this).unbind "mousemove", dragging

    changeAlignment = (pos) ->
      alignment = pos
      text.removeClass("top").removeClass("left").removeClass("bottom").removeClass "right"
      text.addClass pos
      if alignment is "left" or alignment is "right"
        text.css marginTop: Math.floor(text.height() / -2)
      else
        text.css marginTop: "auto"

    content.on 'keyup', (e) ->
      div.trigger 'update', content.text()

    triangle.mousedown (e) ->
      return  unless $(e.target).hasClass("guide-rail-triangle")
      e.preventDefault()
      e.stopPropagation()

      $(e.target).find(".guide-rail-content").blur()

      x = e.clientX
      y = e.clientY
      disableSelect = () -> false
      dragging = (e) ->
        deltaX = e.clientX - x
        deltaY = e.clientY - y
        if deltaX < -10
          changeAlignment "left"
          x = e.clientX
          y = e.clientY
        else if deltaX > 10
          changeAlignment "right"
          x = e.clientX
          y = e.clientY
        else if deltaY < -10
          changeAlignment "top"
          x = e.clientX
          y = e.clientY
        else if deltaY > 10
          changeAlignment "bottom"
          x = e.clientX
          y = e.clientY

      $(document).bind 'selectstart', disableSelect
      $(document).mousemove dragging
      $(document).mouseup (e) ->
        e.preventDefault()
        e.stopPropagation()
        $(document).unbind 'selectstart', disableSelect
        $(this).unbind "mousemove", dragging

    content.prop "contenteditable", "true"
    content.keydown (e) ->
      if alignment is "left" or alignment is "right"
        text.css marginTop: Math.floor(text.height() / -2)
      else
        text.css marginTop: "auto"

  div

window.GuideRail = class GuideRail
  constructor: (@num) ->
    unless @num
      @num = GuideRail.tips.length + 1

    @selectParent =>
      @addToList()

  addToList: ->
    @listElement = $("<li class='guide-rail-tip'>" + @num + ". Type description here</li>")
    $(".guide-rail-tip-list").append @listElement

  selectParent: (cb) ->
    all = $("*")
    pointer = $("<div class='guide-rail-pointer'></div>").appendTo("body")
    pointer.css(top: window.mousePositionY - 25, left: window.mousePositionX + 20)
    pointer.show('scale')

    mouseover = (event) ->
      $(event.target).addClass "guide-outline-element"

    mouseout = (event) ->
      $(event.target).removeClass "guide-outline-element"

    mousemove = (event) ->
      pointer.filter(":not(:animated)").css(top: event.clientY - 25, left: event.clientX + 20)

    click = (event) =>
      event.preventDefault()
      event.stopPropagation()

      @parent = $(event.target)
      @selector = @uniqueSelector(@parent)
      @el = @parent.guideRail @num, 0, 0, "Type description here", "right", true
      @el.on 'update', @updateDescription

      clearSelectBox()
      cb() if cb

    clearSelectBox = ->
      pointer.remove()
      all.removeClass "guide-outline-element"
      all.unbind("mouseover", mouseover).unbind("mouseout", mouseout).unbind "click", click
      $(document).unbind 'mousemove', mousemove

    setTimeout ->
      all.mouseover(mouseover).mouseout(mouseout).click click
      $(document).mousemove mousemove
      $(document).keydown (e) ->
        clearSelectBox() if e.which == 27
    , 1

  updateDescription: (e, description) =>
    @description = description
    @el.find('.guide-rail-content:not(:focus)').text(description)
    @listElement.filter(":not(:focus)").text "#{@num}. #{description}"

  uniqueSelector: (target) ->
    uniqueFor = (el) ->
      return "#" + el.attr("id")  if el.attr("id")
      result = el.get(0).tagName.toLowerCase()
      if el.attr("class")
        for klass in el.attr("class").split(" ")
          continue  if klass is "guide-outline-element"
          continue  if klass is "clear"
          continue  if klass is "clearfix"
          result += ".#{klass}"

      result += "[name=" + el.attr("name") + "]"  if el.attr("name")
      result = uniqueFor(el.parent()) + " > " + result  if $(result).length > 1 and el.parent().length
      result += ":nth(" + $(result).index(el) + ")"  if $(result).length > 1
      result

    target = $(target)
    uniqueFor target

  offset: ->
    left: parseInt(@el.css 'left')
    top: parseInt(@el.css 'top')

  direction: ->
    @el.find('.guide-rail-text').attr('class')

  serialize: ->
    {
      num: @num
      offset: @offset()
      direction: @direction()
      description: @description || ""
    }

  @tips: []

  @serialize: ->
    tip.serialize() for tip in @tips

$(document).ready ->
  return

  addTip = (e) ->
    window.mousePositionX = e.clientX
    window.mousePositionY = e.clientY

    e.preventDefault()
    guide = new GuideRail()
    GuideRail.tips.push(guide)

  tipList = $("<div class='guide-rail-tips'><div class='guide-rail-logo'>App Tour Guide</div><ul class='guide-rail-tip-list'></ul></div>")
  addTipButton = $("<a href='#' class='guide-rail-add-tip'>+ Add tip</a>")
  addTipButton.click addTip
  tipList.append addTipButton
  $("body").append tipList
