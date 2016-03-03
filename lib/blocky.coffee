BlockyView = null

module.exports = Blocky =
  activate: ->
    atom.workspace.observeTextEditors (editor) =>
      if editor.getGrammar().name is "Ruby"
        BlockyView ?= require './blocky-view'
        new BlockyView(editor, atom.views.getView(editor))
