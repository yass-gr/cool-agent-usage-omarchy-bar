<img src="assets/icon.svg" width="64" height="64" alt="">

# Agent rings

One ring on the bar for each AI agent Omarchy already tracks on this machine. The green arc is the fullest limit window. The mark in the middle is that agent's logo.

On a left or right bar the rings stack. On a top or bottom bar they sit in a row.

## Install

```bash
omarchy plugin add https://github.com/yass-gr/cool-agent-usage-omarchy-bar.git
omarchy plugin enable io.github.yass-gr.agent-rings --section left
```

## Remove

```bash
omarchy plugin disable io.github.yass-gr.agent-rings
omarchy plugin remove io.github.yass-gr.agent-rings --yes
```

## What it reads

The widget watches `~/.local/state/omarchy/agents/usage/*.json`. Those files are written by `omarchy-agent-usage-update`, the same command the built-in Agents panel uses. An agent is shown when its record is ready, has a limit, or has local history. Collectors with nothing to report stay off the bar.

Hover a ring for each window and its percentage. Left click opens the Agents panel. Right click opens the agent picker. Middle click runs `omarchy-agent-usage-update`.

Logos are loaded from Omarchy itself, at `$OMARCHY_PATH/shell/plugins/agents/assets/<id>.svg`. A missing mark falls back to two letters. The widget does not download anything and does not edit `shell.json` on its own.

`maxRings` in the widget settings caps how many rings are drawn. The default is 16.

## License

[MIT](LICENSE). No extra packages.
