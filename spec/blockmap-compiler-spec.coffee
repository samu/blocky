path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
_ = require 'underscore-plus'
Blocky = require '../lib/blocky'
{getBlockmapCompilationStrategy} = require '../lib/get-blockmap-compilation-strategy'

describe "compile", ->
  [editor, editorView, map] = []

  prepare = (fileName) ->
    waitsForPromise ->
      atom.workspace.open(fileName)
    runs ->
      editor = atom.workspace.getActiveTextEditor()
      map = getBlockmapCompilationStrategy(editor)(editor)

  beforeEach ->
    [editor, editorView, map] = []

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage("language-ruby")

  describe "basic case", ->
    beforeEach ->
      prepare('basic.rb')

    it "finds block structures", ->
      expect(_.keys(map).length).toBe 5
      expect(map[0][0].parameters.keyword).toBe "class"
      expect(map[1][2].parameters.keyword).toBe "def"
      expect(map[3][2].parameters.keyword).toBe "rescue"
      expect(map[5][2].parameters.keyword).toBe "end"
      expect(map[6][0].parameters.keyword).toBe "end"

    it "knows the appendants for every code block", ->
      expect(map[0][0].appendants.length).toBe 1
      expect(map[0][0].appendants[0]).toEqual [6,0]

      expect(map[1][2].appendants.length).toBe 2
      expect(map[1][2].appendants[0]).toEqual [5,2]
      expect(map[1][2].appendants[1]).toEqual [3,2]

      expect(map[6][0].appendants.length).toBe 1
      expect(map[6][0].appendants[0]).toEqual [0,0]

  describe "malformed cases", ->
    describe "when there are too many end keywords", ->
      beforeEach ->
        prepare('too-many-end-keywords.rb')

      it "doesnt throw errors if it cant match all pairs", ->
        expect(map).toBeDefined()

    describe "when there are not enough end keywords", ->
      beforeEach ->
        prepare('not-enough-end-keywords.rb')

      it "doesnt throw errors if it cant match all pairs", ->
        expect(map).toBeDefined()

    describe "when there are keywords, that includes other keywords", ->

      describe "extend keywords", ->
        beforeEach ->
          prepare('extend.rb')

        it "ignores them", ->
          expect(_.keys(map).length).toBe 2
          expect(map[0][0].parameters.keyword).toBe "class"
          expect(map[1]).toBe undefined
          expect(map[2][0].parameters.keyword).toBe "end"

      describe "defined? keywords", ->
        beforeEach ->
          prepare('defined.rb')

        it "ignores them", ->
          expect(_.keys(map).length).toBe 2
          expect(map[0][0].parameters.keyword).toBe "def"
          expect(map[1]).toBe undefined
          expect(map[2][0].parameters.keyword).toBe "end"

  describe "if statements", ->
    describe "basic if", ->
      beforeEach ->
        prepare("basic-if.rb")

      it "finds them", ->
        expect(_.keys(map).length).toBe 2
        expect(map[0][2].parameters.keyword).toBe "if"
        expect(map[1]).toBe undefined
        expect(map[2][2].parameters.keyword).toBe "end"

    describe "one-line if", ->
      beforeEach ->
        prepare("one-line-if.rb")

      it "ignores them", ->
        expect(_.keys(map).length).toBe 2
        expect(map[0][0].parameters.keyword).toBe "begin"
        expect(map[1]).toBe undefined
        expect(map[2][0].parameters.keyword).toBe "end"

      describe "with assignment", ->
        beforeEach ->
          prepare("one-line-if-with-assignment.rb")

        it "ignores them", ->
          expect(_.keys(map).length).toBe 2
          expect(map[0][0].parameters.keyword).toBe "def"
          expect(map[1]).toBe undefined
          expect(map[2][0].parameters.keyword).toBe "end"

    describe "assignment with if", ->
      beforeEach ->
        prepare("assignment-with-if.rb")

      it "doesnt ignore them", ->
        expect(_.keys(map).length).toBe 5
        expect(map[1][10].parameters.keyword).toBe "if"
        expect(map[3][2].parameters.keyword).toBe "else"
        expect(map[5][2].parameters.keyword).toBe "end"

  describe "unless statements", ->
    describe "basic unless", ->
      beforeEach ->
        prepare("basic-unless.rb")

      it "finds them", ->
        expect(_.keys(map).length).toBe 2
        expect(map[0][2].parameters.keyword).toBe "unless"
        expect(map[1]).toBe undefined
        expect(map[2][2].parameters.keyword).toBe "end"

    describe "one-line unless", ->
      beforeEach ->
        prepare("one-line-unless.rb")

      it "ignores them", ->
        expect(_.keys(map).length).toBe 2
        expect(map[0][0].parameters.keyword).toBe "begin"
        expect(map[1]).toBe undefined
        expect(map[2][0].parameters.keyword).toBe "end"

      describe "with assignment", ->
        beforeEach ->
          prepare("one-line-unless-with-assignment.rb")

        it "ignores them", ->
          expect(_.keys(map).length).toBe 2
          expect(map[0][0].parameters.keyword).toBe "def"
          expect(map[1]).toBe undefined
          expect(map[2][0].parameters.keyword).toBe "end"

    describe "assignment with unless", ->
      beforeEach ->
        prepare("assignment-with-unless.rb")

      it "doesnt ignore them", ->
        expect(_.keys(map).length).toBe 5
        expect(map[1][10].parameters.keyword).toBe "unless"
        expect(map[3][2].parameters.keyword).toBe "else"
        expect(map[5][2].parameters.keyword).toBe "end"

  describe "rescue statements", ->
    describe "one-line rescue", ->
      beforeEach ->
        prepare("one-line-rescue.rb")

      it "ignores them", ->
        expect(_.keys(map).length).toBe 2
        expect(map[0][0].parameters.keyword).toBe "def"
        expect(map[1]).toBe undefined
        expect(map[2]).toBe undefined
        expect(map[3][0].parameters.keyword).toBe "end"

  describe "do-blocks", ->
    describe "with parameters", ->
      beforeEach ->
        prepare("do-block-with-parameters.rb")

      it "finds them", ->
        expect(_.keys(map).length).toBe 2
        expect(map[0][10].parameters.keyword).toBe "do"
        expect(map[1]).toBe undefined
        expect(map[2][0].parameters.keyword).toBe "end"
