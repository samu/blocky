{CompositeDisposable, Range} = require 'atom'
{getBlockmapCompilationStrategy, hasSyntaxTree} = require './get-blockmap-compilation-strategy'

module.exports =
class BlockyView
  constructor: (@editor, editorElement) ->
    @blockMap = []
    @markers = []
    @subscriptions = new CompositeDisposable

    @subscriptions.add(@editor.onDidStopChanging(=>
      @notifyContentsModified().then =>
        @notifyChangeCursorPosition()
      ))

    @subscriptions.add(@editor.onDidChangeCursorPosition(=> @notifyChangeCursorPosition()))

    @subscriptions.add(atom.commands.add(editorElement, 'blocky:expand-selection', => @expandSelection()))

    @compileBlockMap = getBlockmapCompilationStrategy(@editor)

    if hasSyntaxTree(@editor)
      @notifyContentsModified().then =>
        @notifyChangeCursorPosition()
    else
      @subscriptions.add(@editor.onDidTokenize(=>
        @notifyContentsModified().then =>
          @notifyChangeCursorPosition()
      ))

  destroy: ->
    @subscriptions.dispose()
    @destroyMarkers()

  destroyMarkers: ->
    marker.destroy() for marker in @markers

  notifyContentsModified: ->
    @compileBlockMap(@editor).then((result) => @blockMap = result)

  findCurrentBlock: (cursorPosition) ->
    row = cursorPosition.row
    row-- while row >= 0 and not entries = @blockMap[row]
    return unless entries

    for entry in entries
      if entry and @liesBetween(cursorPosition.column, entry.parameters.position, entry.parameters.position + entry.parameters.length)
        startRow = entry.block.begin.lineNumber
        startCol = entry.block.begin.position
        endRow = entry.block.end.lineNumber
        endCol = entry.block.end.position + entry.block.end.length

        rangeToSelect = new Range([startRow, startCol], [endRow, endCol])
        @editor.setSelectedBufferRange(rangeToSelect)

  expandSelection: ->
    currentBlock = @findCurrentBlock(@editor.getCursorBufferPosition())

  decorateKeyword: (lineNumber, position, length) ->
    range = new Range([lineNumber, position], [lineNumber, position + length])
    marker = @editor.markBufferRange(range)
    @editor.decorateMarker(marker, type: 'highlight', class: 'bracket-matcher', deprecatedRegionClass: 'bracket-matcher')
    @markers.push(marker)

  liesBetween: (position, begin, end) ->
    begin <= position <= end

  notifyChangeCursorPosition: ->
    @destroyMarkers()
    cursorPosition = @editor.getCursorBufferPosition()

    entries = @blockMap[cursorPosition.row]
    if entries
      for entry in entries
        if entry and @liesBetween(cursorPosition.column, entry.parameters.position, entry.parameters.position + entry.parameters.length)
          @decorateKeyword(entry.parameters.lineNumber, entry.parameters.position, entry.parameters.length)
          for [lineNumber, column] in entry.appendants
            appendant = @blockMap[lineNumber][column]
            @decorateKeyword(appendant.parameters.lineNumber, appendant.parameters.position, appendant.parameters.length)
