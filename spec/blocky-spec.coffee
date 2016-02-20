path = require 'path'
fs = require 'fs-plus'
temp = require 'temp'
Blocky = require '../lib/blocky'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

# ^class\s|\sclass\s

describe "Blocky", ->
  [workspaceElement, activationPromise] = []
  [editor, editorView] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('blocky')

    projectPath = temp.mkdirSync('git-diff-spec-')

    fs.copySync(path.join(__dirname, 'fixtures', 'working-dir'), projectPath)
    atom.project.setPaths([projectPath])

    waitsForPromise ->
      console.log "activate!!"
      atom.workspace.open(path.join(projectPath, 'simple.rb'))

    runs ->
      editor = atom.workspace.getActiveTextEditor()
      editorView = atom.views.getView(editor)

    waitsForPromise ->
      atom.packages.activatePackage("language-ruby")

    runs ->
      atom.packages.activatePackage('blocky')
      atom.commands.dispatch workspaceElement, 'blocky:toggle'

    waitsForPromise ->
      activationPromise

  describe "Unit tests", ->
    it "does stuff", ->


      # runs ->
      # Blocky.methodUnderTest()

  # describe "when the blocky:toggle event is triggered", ->
  #   it "hides and shows the modal panel", ->
  #     # Before the activation event the view is not on the DOM, and no panel
  #     # has been created
  #     expect(workspaceElement.querySelector('.blocky')).not.toExist()
  #
  #     # This is an activation event, triggering it will cause the package to be
  #     # activated.
  #     atom.commands.dispatch workspaceElement, 'blocky:toggle'
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       expect(workspaceElement.querySelector('.blocky')).toExist()
  #
  #       blockyElement = workspaceElement.querySelector('.blocky')
  #       expect(blockyElement).toExist()
  #
  #       blockyPanel = atom.workspace.panelForItem(blockyElement)
  #       expect(blockyPanel.isVisible()).toBe true
  #       atom.commands.dispatch workspaceElement, 'blocky:toggle'
  #       expect(blockyPanel.isVisible()).toBe false
  #
  #   it "hides and shows the view", ->
  #     # This test shows you an integration test testing at the view level.
  #
  #     # Attaching the workspaceElement to the DOM is required to allow the
  #     # `toBeVisible()` matchers to work. Anything testing visibility or focus
  #     # requires that the workspaceElement is on the DOM. Tests that attach the
  #     # workspaceElement to the DOM are generally slower than those off DOM.
  #     jasmine.attachToDOM(workspaceElement)
  #
  #     expect(workspaceElement.querySelector('.blocky')).not.toExist()
  #
  #     # This is an activation event, triggering it causes the package to be
  #     # activated.
  #     atom.commands.dispatch workspaceElement, 'blocky:toggle'
  #
  #     waitsForPromise ->
  #       activationPromise
  #
  #     runs ->
  #       # Now we can test for view visibility
  #       blockyElement = workspaceElement.querySelector('.blocky')
  #       expect(blockyElement).toBeVisible()
  #       atom.commands.dispatch workspaceElement, 'blocky:toggle'
  #       expect(blockyElement).not.toBeVisible()
