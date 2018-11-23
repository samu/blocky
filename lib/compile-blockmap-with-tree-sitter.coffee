{fromLineInfo, isRelevantKeyword} = require './blockmap-compiler'

traverseNodes = (acc, node) ->
  keyword = node.type
  length = node.endPosition.column - node.startPosition.column
  row = node.startPosition.row
  position = node.startPosition.column

  if isRelevantKeyword(keyword) && length == node.type.length
    acc.push
      keyword: keyword
      row: row
      position: position
      length: length

  node.children.forEach((child) => traverseNodes(acc, child))

getLineInfo = (editor) ->
  root = editor.buffer.getLanguageMode().tree.rootNode

  acc = []
  traverseNodes(acc, root)

  # TODO the following code is needed because TreeSitter seems to emit duplicate Nodes for certain
  #      keywords. For example, an entry for `rescue` might appear twice. Hopefully this code can
  #      be removed in the future if TreeSitter changes this behaviour.
  map = {}
  acc.forEach((item) => map["#{item.row}#{item.position}"] = item)

  acc = Object.keys(map).map((key) => map[key]).sort((a, b) => a.row - b.row)

  return acc

compileBlockmapWithTreeSitter = (editor) ->
  return new Promise((resolve) =>
    editor.buffer.getLanguageMode().parseCompletePromise().then(() =>
      resolve(fromLineInfo(editor, getLineInfo(editor)))
    )
  )

module.exports.compileBlockmapWithTreeSitter = compileBlockmapWithTreeSitter
