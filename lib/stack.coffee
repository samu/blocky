module.exports = class Stack
  constructor: ->
    console.log "HERE"
    @startTags = []
    @endTags = []

  push: (keyword, line, lineNumber) ->
    # console.log keyword, line, lineNumber
    if keyword is "end"
      @endTags << {keyword: "end", lineNumber}
    else
      return if keyword is "if"  and not /^\s+if/.test(line)
      @openTags << {keyword: keyword, lineNumber}
