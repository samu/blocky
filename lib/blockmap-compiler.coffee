openKeywords = /begin|case|class|def|do|for|module|unless|while/
ifKeyword = /if/
intermediateKeywords = /break|else|elsif|ensure|next|rescue|return/
endKeyword = /end/

class Parameters
  constructor: (@keyword, @lineNumber, @position, @length) ->

class BlockMap
  constructor: ->
    @map = []

  entryAt: (lineNumber) ->
    @map[lineNumber] ||= []

  putEntry: (parameters, block) ->
    @entryAt(parameters.lineNumber)[parameters.position] =
      {parameters, appendants: block.getAppendants(parameters.lineNumber)}

  push: (block) ->
    @putEntry(block.begin, block)
    for intermediate in block.intermediates
      @putEntry(intermediate, block)
    @putEntry(block.end, block)

class Block
  constructor: (@begin) ->
    @intermediates = []

  pushInbetween: (parameters) ->
    @intermediates.push(parameters)

  pushEnd: (parameters) ->
    @end = parameters

  getAppendants: (skip) ->
    appendants = []
    appendants.push([@begin.lineNumber, @begin.position]) unless skip is @begin.lineNumber
    appendants.push([@end.lineNumber, @end.position])  unless skip is @end.lineNumber
    for intermediate in @intermediates
      appendants.push([intermediate.lineNumber, intermediate.position]) unless skip is intermediate.lineNumber
    return appendants

class Stack
  constructor: (@blockMap) ->
    invisiblesSpace = atom.config.get('editor.invisibles.space')
    @invisiblesRegex = new RegExp("^#{invisiblesSpace}*if")
    @stack = []

  push: (parameters, line) ->
    # TODO
    # this tests the intermediates first, because of the if that also appears in elsif
    # maybe this should be done with a more specific regex
    if intermediateKeywords.test(parameters.keyword)
      @getTop()?.pushInbetween(parameters)

    else if ifKeyword.test(parameters.keyword)
      if @invisiblesRegex.test(line.text)
        @stack.push(new Block(parameters))

    else if openKeywords.test(parameters.keyword)
      @stack.push(new Block(parameters))

    else if endKeyword.test(parameters.keyword)
      @getTop()?.pushEnd(parameters)
      block = @stack.pop()
      @blockMap.push(block) if block

  getTop: ->
    @stack[@stack.length-1]

getPositionAndLength = (tags, index) ->
  counter = 0
  position = 0
  while counter < index
    position += tags[counter]
    counter++
  return [position, tags[counter]]

module.exports = (lines) ->
  blockMap = new BlockMap()
  stack = new Stack(blockMap)
  for line, lineNumber in lines
    tags = line.tags.filter (n) -> n >= 0
    # console.log line.text
    # console.log tags
    # console.log line.tokens
    for token, index in line.tokens
      for scope in token.scopes
        if scope.indexOf("keyword") >= 0
          [position, length] = getPositionAndLength(tags, index)
          stack.push(new Parameters(token.value, lineNumber, position, length), line)

  # console.log blockMap.map
  return blockMap.map
