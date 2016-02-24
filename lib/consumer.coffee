# openKeywords = /begin|module|class|def|if/
# inbetweenKeywords = /private|rescue|else/
# endKeywords = /end/
openKeywords = /begin|case|class|def|do|for|if|module|unless|while/
inbetweenKeywords = /break|else|elsif|ensure|next|rescue|return/
endKeywords = /end/

class Parameters
  constructor: (@keyword, @lineNumber, @position, @length) ->

class BlockMap
  constructor: ->
    @map = {}

  push: (block) ->
    @map[block.begin.lineNumber] = {parameters: block.begin, appendants: block.getAppendants(block.begin.lineNumber)}
    for inbetween in block.inbetweens
      @map[inbetween.lineNumber] = {parameters: inbetween, appendants: block.getAppendants(inbetween.lineNumber)}
    @map[block.end.lineNumber] = {parameters: block.end, appendants: block.getAppendants(block.end.lineNumber)}

class Block
  constructor: (@begin) ->
    @inbetweens = []

  pushInbetween: (parameters) ->
    @inbetweens.push(parameters)

  pushEnd: (parameters) ->
    @end = parameters

  getAppendants: (skip) ->
    appendants = []
    appendants.push(@begin.lineNumber) unless skip is @begin.lineNumber
    appendants.push(@end.lineNumber)  unless skip is @end.lineNumber
    for inbetween in @inbetweens
      appendants.push(inbetween.lineNumber) unless skip is inbetween.lineNumber
    return appendants

class Stack
  constructor: (@blockMap) ->
    @stack = []

  push: (parameters) ->
    # TODO
    # this tests the inbetweens first, because of the if that also appears in elsif
    # maybe this should be done with a more specific regex
    if inbetweenKeywords.test(parameters.keyword)
      @stack[@stack.length-1].pushInbetween(parameters)

    else if openKeywords.test(parameters.keyword)
      @stack.push(new Block(parameters))

    else if endKeywords.test(parameters.keyword)
      @stack[@stack.length-1].pushEnd(parameters)
      block = @stack.pop()
      @blockMap.push(block)

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
          # console.log token.value, position, length
          stack.push(new Parameters(token.value, lineNumber, position, length))

  # console.log blockMap.map
  return blockMap.map
