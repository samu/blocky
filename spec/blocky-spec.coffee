path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
_ = require 'underscore-plus'
Blocky = require '../lib/blocky'
compile = require '../lib/blockmap-compiler'

describe "Blocky", ->
  # [workspaceElement, activationPromise] = []
  [editor, editorView, map] = []

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-ruby")

  describe "basic case", ->
    beforeEach ->
      waitsForPromise ->
        atom.workspace.open('basic.rb')
      runs ->
        editor = atom.workspace.getActiveTextEditor()
        lines = editor.displayBuffer.tokenizedBuffer.tokenizedLines
        map = compile(lines)

    it "finds block structures", ->
      expect(_.keys(map).length).toBe 5
      expect(map[0].parameters.keyword).toBe "class"
      expect(map[1].parameters.keyword).toBe "def"
      expect(map[3].parameters.keyword).toBe "rescue"
      expect(map[5].parameters.keyword).toBe "end"
      expect(map[6].parameters.keyword).toBe "end"

    it "knows the appendants for every code block", ->
      expect(map[0].appendants.length).toBe 1
      expect(map[0].appendants[0]).toBe 6

      expect(map[1].appendants.length).toBe 2
      expect(map[1].appendants[0]).toBe 5
      expect(map[1].appendants[1]).toBe 3

      expect(map[6].appendants.length).toBe 1
      expect(map[6].appendants[0]).toBe 0

  describe "malformed cases", ->
    describe "when there are too many end keywords", ->
      it "doesnt throw errors if it cant match all pairs", ->
        waitsForPromise ->
          atom.workspace.open('too-many-end-keywords.rb')
        runs ->
          editor = atom.workspace.getActiveTextEditor()
          lines = editor.displayBuffer.tokenizedBuffer.tokenizedLines
          map = compile(lines)

    describe "when there are not enough end keywords", ->
      it "doesnt throw errors if it cant match all pairs", ->
        waitsForPromise ->
          atom.workspace.open('not-enough-end-keywords.rb')
        runs ->
          editor = atom.workspace.getActiveTextEditor()
          lines = editor.displayBuffer.tokenizedBuffer.tokenizedLines
          map = compile(lines)
