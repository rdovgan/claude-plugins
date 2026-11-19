import type { ConfigRow, EngineInterface, Register } from 'claude-code'

// Output format toggles (D-44): the plugin's boolean userConfig fields as buttons above
// the prompt, the enabled ones on a violet background. A press changes the option as /config does.
// No $.ui.status: Claude Code draws a plugin's status line with a ⚠ mark, which reads as a warning.
// The yellow REPORT button at the end runs /<plugin>:report with the formats on now (D-47): the plugin
// talks by default and writes documents only when asked.
// Runs only in Claude Code builds with hooks modules; the shell hooks do not depend on it.
// Kept the same in java-developer, java-analyst, qa-analyst and qa-docs, except the *_FORMATS variable (D-19).

const VIOLET = '#8b5cf6'
const YELLOW = '#facc15'

type Format = { key: string; name: string; enabled: boolean }

// The format name is the option key up to the first '_': visual_artifact -> visual.
function nameOf(key: string): string {
  return key.split('_')[0] ?? key
}

async function formats($: EngineInterface): Promise<{ list: Format[]; isEnv: boolean }> {
  const prefix = `${$.plugin.name}.`
  const rows: ConfigRow[] = (await $.config.list()).filter(r => r.key.startsWith(prefix) && typeof r.value === 'boolean')
  // Read as the shell hooks do (lib.sh): empty is unset, names are split on commas and spaces, case does not matter.
  const env = await $.env.get('QA_DOCS_FORMATS')
  const envList = env ? env.toLowerCase().split(/[\s,]+/).filter(Boolean) : null
  const list = rows.map(r => {
    const name = nameOf(r.key.slice(prefix.length))
    return { key: r.key, name, enabled: envList ? envList.includes(name) : r.value === true }
  })
  return { list, isEnv: envList !== null }
}

async function toggle($: EngineInterface, f: Format): Promise<void> {
  const { deny } = await $.config.set({ key: f.key, value: !f.enabled })
  if (deny) $.ui.toast(`${f.name}: ${deny}`)
  $.ui.invalidate('ui.render')
}

async function report($: EngineInterface): Promise<void> {
  const { list } = await formats($)
  const args = list.filter(f => f.enabled).map(f => `--${f.name}`).join(' ')
  try {
    await $.command.run({ command: `${$.plugin.name}:report`, args })
  } catch (err) {
    $.ui.toast(`report: ${err instanceof Error ? err.message : String(err)}`)
  }
}

export const register: Register = on => {
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const { list, isEnv } = await formats($)
    if (!list.length) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)

    return (
      <Box flexDirection="row">
        <Text dimColor>formats </Text>
        {list.map(f => {
          const chip = f.enabled
            ? <Text backgroundColor={VIOLET} color="white" bold>{` ${f.name} `}</Text>
            : <Text dimColor>{` ${f.name} `}</Text>
          return isEnv
            ? <Text key={f.key}>{chip} </Text>
            : <Button key={f.key} plain label={f.name} onPress={() => toggle($, f)}>{chip} </Button>
        })}
        {isEnv ? <Text dimColor>(set by QA_DOCS_FORMATS) </Text> : null}
        <Button plain label="report" onPress={() => report($)}>
          <Text backgroundColor={YELLOW} color="black" bold>{' ▶ REPORT '}</Text>
        </Button>
      </Box>
    )
  })
}
