import QtQuick
import Quickshell.Io

// One usage file. The bar watches the directory listing and gives each json
// its own reader, the same way the built-in Agents panel does.
Item {
  id: root
  visible: false

  property string path: ""
  property var record: null

  function reload() { agentFile.reload() }

  function apply(content) {
    var parsed = null
    try {
      parsed = JSON.parse(String(content || ""))
    } catch (e) {
      parsed = null
    }
    root.record = parsed && typeof parsed === "object" ? parsed : null
  }

  FileView {
    id: agentFile
    path: root.path
    watchChanges: true
    printErrors: false
    onLoaded: root.apply(text())
    onFileChanged: root.reload()
    onLoadFailed: root.record = null
  }
}
