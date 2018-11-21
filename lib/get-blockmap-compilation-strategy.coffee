{compileBlockmapWithTreeSitter} = require './compile-blockmap-with-tree-sitter'
{compileBlockMapWithTokenizedBuffer} = require './compile-blockmap-with-tokenized-buffer'

hasSyntaxTree = (editor) -> editor.buffer.getLanguageMode().getSyntaxNodeAtPosition

getBlockmapCompilationStrategy = (editor) ->
  return if hasSyntaxTree(editor) then compileBlockmapWithTreeSitter else compileBlockMapWithTokenizedBuffer

module.exports.hasSyntaxTree = hasSyntaxTree
module.exports.getBlockmapCompilationStrategy = getBlockmapCompilationStrategy
