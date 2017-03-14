openKeywords = /^(begin|case|class|def|do ?|for|module|while)$/
ifOrUnlessKeyword = /if|unless/
intermediateKeywords = /else|elsif|ensure/
notInlineRescue = /^\s*rescue/
endKeyword = /^end$/

class Parameters
  constructor: (@keyword, @lineNumber, @position, @length) ->

class BlockMap
  constructor: ->
    @map = []

  entryAt: (lineNumber) ->
    @map[lineNumber] ||= []

  putEntry: (parameters, block) ->
    @entryAt(parameters.lineNumber)[parameters.position] =
      {block, parameters, appendants: block.getAppendants(parameters.lineNumber)}

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

  makeAppendant: (parameters, lineNumberToExclude) ->
    unless lineNumberToExclude is parameters.lineNumber
      [parameters.lineNumber, parameters.position]

  getAppendants: (lineNumberToExclude) ->
    appendants = []
    for candiate in [@begin, @end].concat(@intermediates)
      appendants.push(a) if a = @makeAppendant(candiate, lineNumberToExclude)
    return appendants

class Stack
  constructor: (@blockMap) ->
    keywordPrecededByWhitespace = "^\\s*(if|unless)"
    keywordAsAnAssignment = "^.+=\\s+(if|unless)"
    @isKeywordWithAppendants = new RegExp("(#{keywordPrecededByWhitespace})|(#{keywordAsAnAssignment})")
    @stack = []

  push: (parameters, line) ->
    # TODO
    # this handles the intermediates first, because of the if that also appears
    # in elsif. maybe this should be taken care of with a more specific regex.
    if intermediateKeywords.test(parameters.keyword) || notInlineRescue.test(line)
      @getTop()?.pushInbetween(parameters)

    else if ifOrUnlessKeyword.test(parameters.keyword)
      if @isKeywordWithAppendants.test(line)
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

module.exports = (buffer, tokenizedLines) ->
  blockMap = new BlockMap()
  stack = new Stack(blockMap)
  for line, lineNumber in tokenizedLines
    tags = line && line.tags.filter (n) -> n >= 0
    for token, index in line.tokens
      for scope in token.scopes
        if scope.indexOf("keyword") >= 0
          [position, length] = getPositionAndLength(tags, index)
          stack.push(new Parameters(token.value, lineNumber, position, length), buffer.lineForRow(lineNumber))

  return blockMap.map
