path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
_ = require 'underscore-plus'
Blocky = require '../lib/blocky'

describe "BlockyView", ->
  [editor, editorElement] = []

  fullyTokenize = (tokenizedBuffer) ->
    tokenizedBuffer.setVisible(true)
    advanceClock() while tokenizedBuffer.firstInvalidRow()?

  prepare = (fileName) ->
    waitsForPromise ->
      atom.workspace.open(fileName)
    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorElement = atom.views.getView(editor)
      fullyTokenize(editor.displayBuffer.tokenizedBuffer)

  beforeEach ->
    [editor, editorElement] = []
    waitsForPromise ->
      atom.packages.activatePackage("language-ruby")
    waitsForPromise ->
      atom.packages.activatePackage("blocky")

  describe "basic case", ->
    expectNoHighlights = ->
      decorations = editor.getHighlightDecorations().filter (decoration) -> decoration.properties.class is 'bracket-matcher'
      expect(decorations.length).toBe 0

    expectHighlightsOld = (index, start, end) ->
      decorations = editor.getHighlightDecorations().filter (decoration) -> decoration.properties.class is 'bracket-matcher'
      range = decorations[index].marker.getBufferRange()
      expect(range.start).toEqual start
      expect(range.end).toEqual end

    expectHighlights = (expectedLineNumber, expectedColumn, expectedLength) ->
      decorations = editor.getHighlightDecorations().filter (decoration) ->
        clazz = decoration.properties.class
        range = decoration.marker.getBufferRange()
        column = range.start.column
        lineNumber = range.start.row
        length = range.end.column - range.start.column
        clazz is 'bracket-matcher' and
          lineNumber is expectedLineNumber and
          column is expectedColumn and
          length is expectedLength
      expect(decorations.length).toBe 1

    beforeEach ->
      prepare('basic.rb')

    it "highlights block structures", ->
      editor.setCursorBufferPosition([0, 0])
      expectHighlights(0, 0, 5)
      expectHighlights(6, 0, 3)

      editor.setCursorBufferPosition([0, 3])
      expectHighlights(0, 0, 5)
      expectHighlights(6, 0, 3)

      editor.setCursorBufferPosition([0, 5])
      expectHighlights(0, 0, 5)
      expectHighlights(6, 0, 3)

      editor.setCursorBufferPosition([0, 6])
      expectNoHighlights()

      editor.setCursorBufferPosition([1, 0])
      expectNoHighlights()

      editor.setCursorBufferPosition([1, 2])
      expectHighlights(1, 2, 3)
      expectHighlights(3, 2, 6)
      expectHighlights(5, 2, 3)

  describe "expandSelection", ->
    beforeEach ->
      atom.config.set("editor.invisibles.space", " ")
      prepare('big.rb')

    it "expands the selection", ->
      editor.setCursorBufferPosition([5, 6])
      atom.commands.dispatch(editorElement, "blocky:expand-selection")
      expect(editor.getSelectedBufferRange()).toEqual [[3, 6], [9, 9]]
