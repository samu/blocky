# openKeywords = /begin|module|class|def|if/
# inbetweenKeywords = /private|rescue|else/
# endKeywords = /end/
openKeywords = /begin|case|class|def|do|for|module|unless|while/
ifKeyword = /if/
inbetweenKeywords = /break|else|elsif|ensure|next|rescue|return/
endKeywords = /end/

class Parameters
  constructor: (@keyword, @lineNumber, @position, @length) ->

class BlockMap
  constructor: ->
    @map = []

  push: (block) ->
    @entryAt(block.begin.lineNumber)[block.begin.position] = {parameters: block.begin, appendants: block.getAppendants(block.begin.lineNumber)}
    for inbetween in block.inbetweens
      @entryAt(inbetween.lineNumber)[inbetween.position] = {parameters: inbetween, appendants: block.getAppendants(inbetween.lineNumber)}
    @entryAt(block.end.lineNumber)[block.end.position] = {parameters: block.end, appendants: block.getAppendants(block.end.lineNumber)}

  entryAt: (lineNumber) ->
    @map[lineNumber] ||= []

class Block
  constructor: (@begin) ->
    @inbetweens = []

  pushInbetween: (parameters) ->
    @inbetweens.push(parameters)

  pushEnd: (parameters) ->
    @end = parameters

  getAppendants: (skip) ->
    appendants = []
    appendants.push([@begin.lineNumber, @begin.position]) unless skip is @begin.lineNumber
    appendants.push([@end.lineNumber, @end.position])  unless skip is @end.lineNumber
    for inbetween in @inbetweens
      appendants.push([inbetween.lineNumber, inbetween.position]) unless skip is inbetween.lineNumber
    return appendants

class Stack
  constructor: (@blockMap) ->
    invisiblesSpace = atom.config.get('editor.invisibles.space')
    @invisiblesRegex = new RegExp("^#{invisiblesSpace}*if")
    @stack = []

  push: (parameters, line) ->
    # TODO
    # this tests the inbetweens first, because of the if that also appears in elsif
    # maybe this should be done with a more specific regex
    if inbetweenKeywords.test(parameters.keyword)
      @getTop()?.pushInbetween(parameters)

    else if ifKeyword.test(parameters.keyword)
      if @invisiblesRegex.test(line.text)
        @stack.push(new Block(parameters))

    else if openKeywords.test(parameters.keyword)
      @stack.push(new Block(parameters))

    else if endKeywords.test(parameters.keyword)
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
