BlockyView = null

module.exports = Blocky =
  activate: ->
    atom.workspace.observeTextEditors (editor) =>
      BlockyView ?= require './blocky-view'
      new BlockyView(editor)
