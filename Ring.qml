import QtQuick

// One agent. Dark disc, green arc from 12 o'clock, mark in the middle.
// Drawn with short rectangles because a plugin Canvas does not rasterize
// inside the shell.
Item {
  id: ring

  property real fraction: 0
  property var markUrls: []
  property int markIndex: 0
  onMarkUrlsChanged: markIndex = 0
  property string initials: ""
  property string label: ""
  property color arcColor: "#30C070"
  property color discColor: "#121212"
  property color trackColor: "#6A6A6A"
  property color markColor: "#F4F4F4"
  property string fontFamily: "sans-serif"

  signal ringHovered()
  signal ringExited()
  signal ringPressed(int button)

  readonly property real stroke: Math.max(2.5, width * 0.15)
  readonly property real ringRadius: width / 2 - stroke / 2
  readonly property int segments: 64
  readonly property real segStep: 360 / segments
  readonly property real segLength: 2 * ringRadius * Math.sin(Math.PI / segments) * 1.85
  readonly property real shown: Math.max(0, Math.min(1, fraction))

  implicitWidth: 24
  implicitHeight: 24

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: ring.discColor
    border.width: ring.stroke
    border.color: ring.trackColor
    antialiasing: true
  }

  Repeater {
    model: ring.segments

    Rectangle {
      required property int index
      readonly property real segAngle: index * ring.segStep
      readonly property bool arcOn: segAngle <= 360 * ring.shown
      width: ring.segLength
      height: ring.stroke
      radius: height / 2
      rotation: segAngle
      antialiasing: true
      color: ring.arcColor
      visible: arcOn && ring.shown > 0
      x: ring.width / 2 + ring.ringRadius * Math.sin(segAngle * Math.PI / 180) - width / 2
      y: ring.height / 2 - ring.ringRadius * Math.cos(segAngle * Math.PI / 180) - height / 2
    }
  }

  Image {
    id: mark
    anchors.centerIn: parent
    width: ring.width * 0.5
    height: width
    source: ring.markIndex < ring.markUrls.length ? ring.markUrls[ring.markIndex] : ""
    onStatusChanged: {
      if (status === Image.Error && ring.markIndex < ring.markUrls.length)
        Qt.callLater(function () { ring.markIndex = ring.markIndex + 1 })
    }
    sourceSize.width: width * 2
    sourceSize.height: height * 2
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: true
  }

  Text {
    anchors.centerIn: parent
    visible: mark.status !== Image.Ready
    textFormat: Text.PlainText
    text: ring.initials
    color: ring.markColor
    font.family: ring.fontFamily
    font.pixelSize: Math.max(8, ring.width * 0.28)
    font.weight: Font.Medium
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onEntered: ring.ringHovered()
    onExited: ring.ringExited()
    onClicked: function (mouse) { ring.ringPressed(mouse.button) }
  }
}
