openKeywords = /^(begin|case|class|def|do ?|for|module|while)$/
ifOrUnlessKeyword = /^if|unless$/
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

fromLineInfo = (editor, lineInfo) ->
  buffer = editor.getBuffer()

  blockMap = new BlockMap()
  stack = new Stack(blockMap)

  for line in lineInfo
    stack.push(new Parameters(line.keyword, line.row, line.position, line.length), buffer.lineForRow(line.row))

  return blockMap.map

keywordRegexes = [openKeywords, ifOrUnlessKeyword, intermediateKeywords, notInlineRescue, endKeyword]

isRelevantKeyword = (keyword) ->
  keywordRegexes.some((regex) => regex.test(keyword))

module.exports.fromLineInfo = fromLineInfo
module.exports.isRelevantKeyword = isRelevantKeyword
