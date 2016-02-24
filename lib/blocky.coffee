BlockyView = require './blocky-view'
compileBlockMap = require './consumer'
{CompositeDisposable, Range} = require 'atom'
_ = require 'underscore-plus'

module.exports = Blocky =
  blockyView: null
  modalPanel: null
  subscriptions: null
  editor: null
  markers: []

  activate: ->
    console.log "BLOCKY HAS BEEN ACTIVATED YEAH"
    atom.workspace.observeTextEditors (editor) =>
      @editor = editor
      @subscriptions = new CompositeDisposable

      @subscriptions.add(editor.onDidStopChanging(=> @notifyContentsModified()))
      @subscriptions.add(editor.displayBuffer.onDidTokenize(=> @notifyContentsModified()))
      # TODO debounce
      fuu = (e) => @notifyChangeCursorPosition(e)
      debounced = _.debounce(fuu, 30)
      # debounced = fuu
      @subscriptions.add(editor.onDidChangeCursorPosition(debounced))

  notifyContentsModified: ->
    lines = @editor.displayBuffer.tokenizedBuffer.tokenizedLines
    @blockMap = compileBlockMap(lines)

  decorateKeyword: (lineNumber, position, length) ->
    range = new Range([lineNumber, position], [lineNumber, position + length])
    marker = @editor.markBufferRange(range)
    @editor.decorateMarker(marker, type: 'highlight', class: 'bracket-matcher', deprecatedRegionClass: 'bracket-matcher')
    @markers.push(marker)

  doScrollStuff: ->

  notifyChangeCursorPosition: (e) ->
    console.log "scrolling!"
    marker.destroy() for marker in @markers
    cursorPosition = @editor.getCursorBufferPosition()
    entry = @blockMap[cursorPosition.row]
    if entry
      @decorateKeyword(entry.parameters.lineNumber, entry.parameters.position, entry.parameters.length)
      for lineNo in entry.appendants
        appendant = @blockMap[lineNo]
        @decorateKeyword(appendant.parameters.lineNumber, appendant.parameters.position, appendant.parameters.length)
