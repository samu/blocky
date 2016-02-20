BlockyView = require './blocky-view'
{Point, CompositeDisposable} = require 'atom'

module.exports = Blocky =
  blockyView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    atom.workspace.observeTextEditors (editor) ->
      @editor = editor
      scanRange = new Range(@editor.buffer.getFirstPosition(), @editor.buffer.getEndPosition())
      @editor.scan /class/g, (result) ->
        console.log "here"
        console.log result.match, result.matchText, result.range

    @blockyView = new BlockyView(state.blockyViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @blockyView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'blocky:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @blockyView.destroy()

  serialize: ->
    blockyViewState: @blockyView.serialize()

  toggle: ->
    console.log 'Blocky was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
