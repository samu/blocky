{fromLineInfo} = require './blockmap-compiler'

getPositionAndLength = (tags, index) ->
  counter = 0
  position = 0
  while counter < index
    position += tags[counter]
    counter++
  return [position, tags[counter]]

compileBlockMapWithTokenizedBuffer = (editor) ->
  tokenizedLines = editor.tokenizedBuffer.tokenizedLines
  lineInfo = []

  for line, lineNumber in tokenizedLines
    break if !line
    tags = line.tags.filter (n) -> n >= 0
    for token, index in line.tokens
      for scope in token.scopes
        if scope.indexOf("keyword") >= 0
          [position, length] = getPositionAndLength(tags, index)

          lineInfo.push({keyword: token.value, row: lineNumber, position: position, length: length})

  return fromLineInfo(editor, lineInfo)

module.exports.compileBlockMapWithTokenizedBuffer = compileBlockMapWithTokenizedBuffer
