compileBlockMap = require './blockmap-compiler'
{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'

module.exports =
class BlockyView
  constructor: (@editor) ->
    @markers = []
    @subscriptions = new CompositeDisposable

    @subscriptions.add(editor.onDidStopChanging(=> @notifyContentsModified()))
    @subscriptions.add(editor.displayBuffer.onDidTokenize(=>
      @notifyContentsModified()
      @notifyChangeCursorPosition()
    ))
    # TODO debounce
    fuu = (e) => @notifyChangeCursorPosition(e)
    debounced = _.debounce(fuu, 30)
    debounced = fuu
    @subscriptions.add(editor.onDidChangeCursorPosition(debounced))

  destroy: ->
    @subscriptions.dispose()
    @destroyMarkers()

  destroyMarkers: ->
    marker.destroy() for marker in @markers

  notifyContentsModified: ->
    lines = @editor.displayBuffer.tokenizedBuffer.tokenizedLines
    @blockMap = compileBlockMap(lines)

  decorateKeyword: (lineNumber, position, length) ->
    range = new Range([lineNumber, position], [lineNumber, position + length])
    marker = @editor.markBufferRange(range)
    @editor.decorateMarker(marker, type: 'highlight', class: 'bracket-matcher', deprecatedRegionClass: 'bracket-matcher')
    @markers.push(marker)

  liesBetween: (position, begin, end) ->
    begin <= position <= end

  notifyChangeCursorPosition: (e) ->
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
