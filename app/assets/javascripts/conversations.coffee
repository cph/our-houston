$.fn.extend

  autocompleteEntities: (entities) ->
    $(@).typeahead
      source: (query)->
        pos = @$element.getCursorPosition()
        a = query.lastIndexOf "{{", pos
        b = query.lastIndexOf "}}", pos - 1

        if a is -1 or b > a
          @mode = ""
          return []
        else
          @tpos = a + 2
          @tquery = query.substring(@tpos, pos)
          @mode = "entity"
          return entities

      updater: (item)->
        if @mode == "entity"
          before = @$element.val().substr(0, @tpos)

          pos = @$element.getCursorPosition()
          val = @$element.val()
          a = val.indexOf "{{", pos
          b = val.indexOf "}}", pos
          b = -1 if a > pos and b > a
          pos = b + 2 if b isnt -1
          after = val.substr(pos)
          "#{before}#{item}}}#{after}"

      matcher: (item)->
        if @mode == "entity"
          ~item.toLowerCase().indexOf(@tquery)
        else
          false




$ ->

  $view = $(".conversation-sandbox")
  return unless $view.length > 0

  $examples = $("#conversation_examples")
  $phrases = $("#conversation_phrases")
  $form = $("#conversation_form")

  $examples.find("input").focus()

  entities = []
  $.getJSON "/conversation/entities", (data) ->
    entities = data.entities

  $view.on "keydown", "input[type=text]", (e) ->
    if e.which is 13
      e.preventDefault()
      if e.metaKey or e.ctrlKey
        submitExamples() if $(e.target).hasClass("conversation-example")
      else
        $li = $(e.target).closest("li")
        $ul = $li.parent()
        $newExample = $ $li[0].cloneNode(true)
        $newExample.find("input").val("")
        $newExample.appendTo($ul)
        $input = $newExample.find("input")
        $input.autocompleteEntities(entities) if $input.hasClass("autocomplete-entities")
        $input.focus()

    else if e.which is 8
      return unless $(e.target).val() is ""
      e.preventDefault()
      $li = $(e.target).parent()
      return if $li.prev().length is 0

      $li.prev().find("input").focus()
      $li.remove()

  submitExamples = ->
    params = $("#conversation_examples_form").serialize()
    $.get "/conversation/recognize", params, (data) ->
      $form.show()
      html = _.map data.phrases, (phrase) ->
        """
        <li>
          <input type="text" name="examples[]" autocomplete="off" value="#{phrase}" class="conversation-phrase autocomplete-entities" />
        </li>
        """
      $phrases.html(html.join("\n")).find("input").focus()
      $phrases.find("input").autocompleteEntities(entities)

  $("#recognize_examples").click (e) ->
    e.preventDefault()
    submitExamples()
