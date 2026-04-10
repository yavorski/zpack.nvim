# Public API

Stable surface for third-party tooling (e.g. [zshow.nvim](https://github.com/sairyy/zshow.nvim)). Everything else under `zpack.*` is internal.

```lua
local api = require('zpack.api')
```

## `zpack.PluginInfo`

```lua
{
  name   = string,
  src    = string,
  status = "loaded"|"pending"|"loading"|"disabled"|"installing",
  lazy   = boolean,
  path   = string?, -- nil while installing
}
```

## `api.get_plugins()`

Returns `zpack.PluginInfo[]`, sorted by `name`.

## `api.get_plugin(name)`

Returns `zpack.PluginInfo?` for the given resolved name.
