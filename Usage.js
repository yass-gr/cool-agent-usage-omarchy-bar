.pragma library

// Turns Omarchy agent usage records into the rings on the bar.
// No QML imports, so the same file loads under Node after the pragma line is stripped.

var PREFERRED = [
  "claude", "codex", "cursor", "grok", "opencode", "opencode-go",
  "agy", "google", "copilot", "kimi", "hermes"
]

function number(value) {
  var n = Number(value)
  return isFinite(n) ? n : 0
}

function safeId(id) {
  return /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(id) && id.indexOf("..") < 0
}

function plain(text) {
  return String(text || "").replace(/[<>&]/g, "").replace(/\s+/g, " ").trim().slice(0, 120)
}

function fraction(value) {
  var n = Number(value)
  if (!isFinite(n) || n < 0) return 0
  if (n > 1 && n <= 100) n = n / 100
  return n > 1 ? 1 : n
}

function isAvailable(record) {
  if (!record || typeof record !== "object") return false
  var id = String(record.id || "")
  if (!safeId(id)) return false
  if (record.ready === true) return true
  if (Array.isArray(record.limits) && record.limits.length > 0) return true
  if (record.hasLocalStats === true) return true
  return number(record.totalPrompts) > 0 || number(record.totalSessions) > 0
}

function ringFraction(record) {
  var limits = record && Array.isArray(record.limits) ? record.limits : []
  var best = 0
  for (var i = 0; i < limits.length; i++) {
    var next = fraction(limits[i] && limits[i].percent)
    if (next > best) best = next
  }
  return best
}

function windows(record) {
  var limits = record && Array.isArray(record.limits) ? record.limits : []
  var out = []
  for (var i = 0; i < limits.length; i++) {
    var item = limits[i] || {}
    var label = plain(item.label || item.title || "")
    if (!label) continue
    out.push({ label: label, percent: fraction(item.percent) })
  }
  return out
}

function initials(name) {
  var words = plain(name).split(" ").filter(function (word) { return word.length > 0 })
  if (words.length === 0) return "?"
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase()
  return (words[0].charAt(0) + words[1].charAt(0)).toUpperCase()
}

function compare(a, b) {
  var left = PREFERRED.indexOf(a.id)
  var right = PREFERRED.indexOf(b.id)
  if (left < 0) left = PREFERRED.length
  if (right < 0) right = PREFERRED.length
  if (left !== right) return left - right
  return String(a.name).localeCompare(String(b.name))
}

function present(records) {
  var out = []
  var seen = {}
  var list = Array.isArray(records) ? records : []
  for (var i = 0; i < list.length; i++) {
    var record = list[i]
    if (!isAvailable(record)) continue
    var id = String(record.id)
    if (seen[id]) continue
    seen[id] = true
    var name = plain(record.name || id)
    out.push({
      id: id,
      name: name,
      fraction: ringFraction(record),
      windows: windows(record),
      status: plain(record.usageStatusText || ""),
      initials: initials(name)
    })
  }
  out.sort(compare)
  return out
}

function tooltip(agent, noLimit) {
  var lines = [agent.name]
  if (!agent.windows || agent.windows.length === 0) {
    lines.push(agent.status || noLimit || "No limit yet")
  } else {
    for (var i = 0; i < agent.windows.length; i++) {
      var item = agent.windows[i]
      lines.push(item.label + "  " + Math.round(item.percent * 100) + "%")
    }
    if (agent.status) lines.push(agent.status)
  }
  return lines.join("\n")
}

function markCandidates(omarchyPath, id) {
  if (!safeId(String(id || ""))) return []
  var root = String(omarchyPath || "").replace(/\/+$/, "")
  if (!root || root.indexOf("\n") >= 0) return []
  var names = [String(id)]
  if (id === "opencode-go") names.push("opencode")
  if (id === "google") names.push("agy")
  var dir = root + "/shell/plugins/agents/assets/"
  return names.map(function (name) { return dir + name + ".svg" })
}
