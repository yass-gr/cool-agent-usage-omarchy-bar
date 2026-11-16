const { test } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

function loadUsage() {
  const source = fs
    .readFileSync(path.join(__dirname, "..", "Usage.js"), "utf8")
    .replace(/^\.pragma library\s*/, "")
  const ctx = {}
  vm.createContext(ctx)
  vm.runInContext(source, ctx)
  return ctx
}

const Usage = loadUsage()

test("empty collectors stay off the bar", () => {
  const shown = Usage.present([
    { id: "deepseek", name: "DeepSeek", ready: false, limits: [], totalPrompts: 0, totalSessions: 0 },
    { id: "claude", name: "Claude Code", ready: true, limits: [{ label: "Weekly", percent: 0.43 }] }
  ])
  assert.equal(Array.from(shown, (agent) => agent.id).join(","), "claude")
  assert.equal(shown[0].fraction, 0.43)
})

test("the ring uses the fullest window", () => {
  const [agent] = Usage.present([{
    id: "claude",
    name: "Claude Code",
    ready: true,
    limits: [
      { label: "Session (5-hour)", percent: 0.32 },
      { label: "Weekly (7-day)", percent: 0.43 },
      { label: "Fable Weekly", percent: 0.04 }
    ]
  }])
  assert.equal(agent.fraction, 0.43)
  assert.equal(agent.windows.length, 3)
})

test("claude stays above codex, then the rest follow the preferred order", () => {
  const shown = Usage.present([
    { id: "hermes", name: "Hermes", ready: true, limits: [] },
    { id: "codex", name: "Codex", ready: true, limits: [] },
    { id: "claude", name: "Claude Code", ready: true, limits: [] }
  ])
  assert.equal(Array.from(shown, (agent) => agent.id).join(","), "claude,codex,hermes")
})

test("tooltip text drops markup and prints whole percents", () => {
  const [agent] = Usage.present([{
    id: "claude",
    name: "Claude <note>",
    ready: true,
    limits: [{ label: "Weekly <plan>", percent: 0.436 }],
    usageStatusText: "ok & waiting"
  }])
  assert.equal(agent.name, "Claude note")
  assert.equal(
    Usage.tooltip(agent, "No limit yet"),
    "Claude note\nWeekly plan  44%\nok waiting"
  )
})

test("a percent already in the 0-100 range is scaled down", () => {
  assert.equal(Usage.fraction(43), 0.43)
  assert.equal(Usage.fraction(140), 1)
  assert.equal(Usage.fraction(-3), 0)
})

test("mark paths stay inside the Omarchy assets directory", () => {
  assert.equal(
    Array.from(Usage.markCandidates("/usr/share/omarchy", "claude")).join(","),
    "/usr/share/omarchy/shell/plugins/agents/assets/claude.svg"
  )
  assert.equal(Usage.markCandidates("/usr/share/omarchy", "../claude").length, 0)
  assert.equal(Usage.markCandidates("/usr/share/omarchy", "claude/../../etc").length, 0)
  assert.equal(
    Array.from(Usage.markCandidates("/usr/share/omarchy", "opencode-go")).join(","),
    "/usr/share/omarchy/shell/plugins/agents/assets/opencode-go.svg,/usr/share/omarchy/shell/plugins/agents/assets/opencode.svg"
  )
})

test("an agent with local history still gets a ring", () => {
  const shown = Usage.present([{
    id: "codex",
    name: "Codex",
    ready: true,
    hasLocalStats: true,
    limits: [],
    usageStatusText: "Codex limits unavailable"
  }])
  assert.equal(shown[0].fraction, 0)
  assert.equal(Usage.tooltip(shown[0], "No limit yet"), "Codex\nCodex limits unavailable")
})
