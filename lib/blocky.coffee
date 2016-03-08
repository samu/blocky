BlockyView = null

module.exports = Blocky =
  activate: ->
    atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name is "Ruby"
        BlockyView ?= require './blocky-view'
        editorElement = atom.views.getView(editor)
        new BlockyView(editor, editorElement)
