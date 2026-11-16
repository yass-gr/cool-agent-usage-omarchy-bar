import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Usage.js" as Usage

// Stacked usage rings for every agent Omarchy has actually seen on this machine.
// A left or right bar stacks them. A top or bottom bar lays the same rings in a row.
BarWidget {
  id: root
  moduleName: "io.github.yass-gr.agent-rings"

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string usageDir: (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/omarchy/agents/usage"
  readonly property string omarchyPath: Quickshell.env("OMARCHY_PATH") || (home + "/.local/share/omarchy")
  readonly property int maxRings: {
    var value = settings ? settings.maxRings : 16
    var count = Number(value === undefined || value === null ? 16 : value)
    if (!isFinite(count)) count = 16
    return Math.max(1, Math.min(24, Math.round(count)))
  }
  readonly property int gap: 4
  readonly property int ringSize: Math.max(16, barSize - 2)
  readonly property string fontFamily: bar && bar.fontFamily ? bar.fontFamily : "sans-serif"

  property var agentIds: []
  property var agents: []

  visible: agents.length > 0
  implicitWidth: vertical
    ? barSize
    : (agents.length > 0 ? agents.length * ringSize + (agents.length - 1) * gap : 0)
  implicitHeight: vertical
    ? (agents.length > 0 ? agents.length * ringSize + (agents.length - 1) * gap : 0)
    : barSize

  Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  function rescan() {
    if (!listProcess.running) listProcess.running = true
  }

  function applyListing(output) {
    var ids = []
    var lines = String(output || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var name = lines[i].trim()
      if (name.slice(-5) === ".json") ids.push(name.slice(0, -5))
    }
    ids.sort()
    if (JSON.stringify(ids) !== JSON.stringify(agentIds)) agentIds = ids
  }

  function rebuild() {
    var records = []
    for (var i = 0; i < readers.count; i++) {
      var reader = readers.objectAt(i)
      if (reader && reader.record) records.push(reader.record)
    }
    var next = Usage.present(records)
    if (next.length > maxRings) next = next.slice(0, maxRings)
    agents = next
  }

  function refresh() {
    if (bar) bar.run("omarchy-agent-usage-update")
  }

  function tip(agent) {
    return Usage.tooltip(agent, strings.t("ring.noLimit"))
  }

  function markUrls(id) {
    var paths = Usage.markCandidates(omarchyPath, id)
    var urls = []
    for (var i = 0; i < paths.length; i++) urls.push("file://" + paths[i])
    return urls
  }

  function onRing(button) {
    if (!bar) return
    if (button === Qt.MiddleButton) refresh()
    else if (button === Qt.RightButton) bar.run("omarchy-agent --pick")
    else bar.run("omarchy-shell shell toggle omarchy.agents")
  }

  Process {
    id: listProcess
    running: false
    command: ["find", root.usageDir, "-maxdepth", "1", "-name", "*.json", "-printf", "%f\n"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyListing(text)
    }
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.rescan()
  }

  Instantiator {
    id: readers
    model: root.agentIds
    delegate: AgentRecord {
      required property var modelData
      path: root.usageDir + "/" + modelData + ".json"
      onRecordChanged: root.rebuild()
    }
    onObjectAdded: root.rebuild()
    onObjectRemoved: root.rebuild()
  }

  Item {
    id: stack
    anchors.centerIn: parent
    width: root.vertical ? root.ringSize : root.implicitWidth
    height: root.vertical ? root.implicitHeight : root.ringSize

    Repeater {
      model: root.agents

      Ring {
        id: ringItem
        required property var modelData
        required property int index
        width: root.ringSize
        height: root.ringSize
        x: root.vertical ? 0 : (LayoutMirroring.enabled
          ? stack.width - width - index * (root.ringSize + root.gap)
          : index * (root.ringSize + root.gap))
        y: root.vertical ? index * (root.ringSize + root.gap) : 0
        fraction: modelData.fraction
        initials: modelData.initials
        label: modelData.name
        markUrls: root.markUrls(modelData.id)
        fontFamily: root.fontFamily
        onRingHovered: if (root.bar) root.bar.showTooltip(ringItem, root.tip(modelData))
        onRingExited: if (root.bar) root.bar.hideTooltip(ringItem)
        onRingPressed: function (button) { root.onRing(button) }
      }
    }
  }
}
