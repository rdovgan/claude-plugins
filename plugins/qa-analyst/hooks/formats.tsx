import type { ConfigRow, EngineInterface, Register } from 'claude-code'

// Output format toggles (D-44): the plugin's boolean userConfig fields as buttons above
// the prompt, the enabled ones on a violet background, and the enabled list as the
// plugin's status line under it. A press changes the option as /config does.
// Runs only in Claude Code builds with hooks modules; the shell hooks do not depend on it.
// Kept the same in qa-analyst and java-analyst, except the *_FORMATS variable (D-19).

const VIOLET = '#8b5cf6'

type Format = { key: string; name: string; enabled: boolean }

// The format name is the option key up to the first '_': visual_artifact -> visual.
function nameOf(key: string): string {
  return key.split('_')[0] ?? key
}

async function formats($: EngineInterface): Promise<{ list: Format[]; isEnv: boolean }> {
  const prefix = `${$.plugin.name}.`
  const rows: ConfigRow[] = (await $.config.list()).filter(r => r.key.startsWith(prefix) && typeof r.value === 'boolean')
  // Read as the shell hooks do (lib.sh): empty is unset, names are split on commas and spaces, case does not matter.
  const env = await $.env.get('QA_ANALYST_FORMATS')
  const envList = env ? env.toLowerCase().split(/[\s,]+/).filter(Boolean) : null
  const list = rows.map(r => {
    const name = nameOf(r.key.slice(prefix.length))
    return { key: r.key, name, enabled: envList ? envList.includes(name) : r.value === true }
  })
  return { list, isEnv: envList !== null }
}

async function showStatus($: EngineInterface): Promise<void> {
  const { list } = await formats($)
  const on = list.filter(f => f.enabled).map(f => f.name)
  $.ui.status(list.length ? `formats: ${on.length ? on.join(', ') : 'none'}` : undefined)
}

async function toggle($: EngineInterface, f: Format): Promise<void> {
  const { deny } = await $.config.set({ key: f.key, value: !f.enabled })
  if (deny) $.ui.toast(`${f.name}: ${deny}`)
  await showStatus($)
  $.ui.invalidate('ui.render')
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const result = await next(e)
    await showStatus($)
    return result
  })

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
        {isEnv ? <Text dimColor>(set by QA_ANALYST_FORMATS)</Text> : null}
      </Box>
    )
  })
}
