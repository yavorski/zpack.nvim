# Changelog

## [2.0.0](https://github.com/yavorski/zpack.nvim/compare/v1.2.1...v2.0.0) (2026-05-26)


### ⚠ BREAKING CHANGES

* :ZPack with subcommands
* deprecate plugins_dir in favor of { import = 'path' }
* `auto_import` option and `zpack.add()` have been removed.
* ZCleanAll removed, use ZDelete! instead

### Features

* add configurable command prefix ([6124277](https://github.com/yavorski/zpack.nvim/commit/6124277a489e121d3f212522667f38140bc4f330))
* add defaults.cond for global plugin condition ([0b86e8c](https://github.com/yavorski/zpack.nvim/commit/0b86e8c771fd782195b222359f50cf13bf5b0ea2))
* add lazy.nvim version compatibility fields ([e63877b](https://github.com/yavorski/zpack.nvim/commit/e63877b43f529c1143a6d8adc2de59fa49b23200))
* add lazy.nvim-compatible dir and url fields ([06b7c60](https://github.com/yavorski/zpack.nvim/commit/06b7c6008b54d63a5a06a2638a0cd41eb8a422f3))
* add module loader for require-based lazy loading ([e1ade68](https://github.com/yavorski/zpack.nvim/commit/e1ade688803bbfc9844a3b7388d5098cfe6ede5b))
* add opts and main fields for auto-setup ([6bc1c70](https://github.com/yavorski/zpack.nvim/commit/6bc1c7069e21999824b2764655824355153f2076))
* add priority field for controlling startup plugin load order ([a75cf0e](https://github.com/yavorski/zpack.nvim/commit/a75cf0e267e58f0e04e1122cc74165f9a58f83d3))
* add public introspection API for third-party tooling ([b678a07](https://github.com/yavorski/zpack.nvim/commit/b678a0787cfd7fd117ffeff0f125db6688d4dbc4))
* add public introspection API for third-party tooling ([d8940e9](https://github.com/yavorski/zpack.nvim/commit/d8940e9001287fcc10afe2d189cc621e747623b9))
* add spec merging and dependencies support ([8911d52](https://github.com/yavorski/zpack.nvim/commit/8911d52b9192ba161a4fcff1cf902fe6666bccfb))
* add vim.loader and Neovim 0.12+ version check ([30b9f8f](https://github.com/yavorski/zpack.nvim/commit/30b9f8fe63e84ff5efdc7837523d97d463af5892))
* add ZBuild command and unify command patterns ([322db15](https://github.com/yavorski/zpack.nvim/commit/322db15b6d54f6fda30d63ae34c06a6642f85ebb))
* add ZCleanAll command to remove all plugins ([a5738cb](https://github.com/yavorski/zpack.nvim/commit/a5738cb156be3ce0bf192e67cd1031dda99b5503))
* add ZDelete command and fix lazy plugin builds ([c34ad7a](https://github.com/yavorski/zpack.nvim/commit/c34ad7a9b8d7afbdc81e19ab67eaec53b507f39e))
* add ZLoad command to manually load unloaded plugins ([e54e6ce](https://github.com/yavorski/zpack.nvim/commit/e54e6ced6183b9e59ef639b17403969187f40151))
* add zpack.Plugin data to hooks and triggers ([da004ff](https://github.com/yavorski/zpack.nvim/commit/da004ff68a13bb9ca47cb2c9e3e2e7ee48032d65))
* add ZRestore command to restore plugins from lockfile ([2e56772](https://github.com/yavorski/zpack.nvim/commit/2e5677283ad116b0625ef82cdc5f60c0cd621504))
* add ZRestore command to restore plugins from lockfile ([c8888ab](https://github.com/yavorski/zpack.nvim/commit/c8888abb1b9c4103c0ce2f31b61ca5acbcf24b02)), closes [#3](https://github.com/yavorski/zpack.nvim/issues/3)
* adopt Neovim plugin best practices ([#23](https://github.com/yavorski/zpack.nvim/issues/23)) ([2f45de6](https://github.com/yavorski/zpack.nvim/commit/2f45de670e4dcbc6a8ae7b11284764772f1cf3e3))
* auto-expand dir field paths with vim.fn.expand() ([c279f97](https://github.com/yavorski/zpack.nvim/commit/c279f97f8296e5627d82d11dc68fd0b92ef98ad6))
* close lazy.nvim parity gaps across lazy triggers ([#27](https://github.com/yavorski/zpack.nvim/issues/27)) ([9ed473a](https://github.com/yavorski/zpack.nvim/commit/9ed473adbf6af59b650ecd716b56bf0ccbf0d7f8))
* defer subsequent add() calls and add defensive guards ([b42d90d](https://github.com/yavorski/zpack.nvim/commit/b42d90d8256204a605ddc664916bcfc96aec4946))
* **event:** support inline pattern syntax ([88f5617](https://github.com/yavorski/zpack.nvim/commit/88f5617203073323d00628ba125c19b05325650a))
* forward expr/silent/noremap/replace_keycodes on KeySpec ([551cd25](https://github.com/yavorski/zpack.nvim/commit/551cd252ecd67c9b5795bd5530d6ee55c0dfe328))
* **ft:** add filetype lazy-loading with event re-triggering ([04fabdf](https://github.com/yavorski/zpack.nvim/commit/04fabdf0547b1a11fdb2b7656a32add66bbdd03f))
* initial implementation of zpack.nvim ([bd94586](https://github.com/yavorski/zpack.nvim/commit/bd945864a4a8566c2b127c32de7a1b1660aa09ac))
* **keys:** support string and function rhs in lazy key specs ([a8c0946](https://github.com/yavorski/zpack.nvim/commit/a8c0946259e56cd2f0187e18153bbc3f5475cb3b))
* **keys:** support string keys and implement shared key loading ([4085f14](https://github.com/yavorski/zpack.nvim/commit/4085f142b49344de8138b8196cc0b082879f4fa3))
* lazy.nvim spec parity (pin/optional/dev/specs/build/reload/sync) ([#28](https://github.com/yavorski/zpack.nvim/issues/28)) ([b6f82cd](https://github.com/yavorski/zpack.nvim/commit/b6f82cdd9774357b0267f0b896b9d2e1c867743a))
* **lazy:** extend priority support to lazy-loaded plugins ([e671a41](https://github.com/yavorski/zpack.nvim/commit/e671a41ae64b74c91342cca1c1cffde5b12bcfc3))
* **lazy:** support event-specific patterns via EventSpec ([c6bce67](https://github.com/yavorski/zpack.nvim/commit/c6bce678efb9e05954cdc08efb05a9cc5df172e7))
* support bang on :ZPack update/restore; document 0.13 native commands ([4f9b312](https://github.com/yavorski/zpack.nvim/commit/4f9b31274dbedf7ac08b9a138e1bf52bf4fe91b4))
* sync state with vim.pack via PackChanged on plugin removal ([0b65048](https://github.com/yavorski/zpack.nvim/commit/0b65048efd8891ec4e1aba4acc678b35af719b18))
* warn about semver-like version on vim.pack.add error ([643108d](https://github.com/yavorski/zpack.nvim/commit/643108dc68e355ca730e511d38b5eaec25675e84))
* ZDelete force deletes active plugins ([141fb23](https://github.com/yavorski/zpack.nvim/commit/141fb2386566973420565992d91218afef0da116))
* **ZDelete:** clean up state after deletion and improve error handling ([e95f48c](https://github.com/yavorski/zpack.nvim/commit/e95f48c40da1693a02e52f3d8bb9ecac32aa68d2))
* **ZDelete:** warn about active plugin deletion and improve delete order ([7a47260](https://github.com/yavorski/zpack.nvim/commit/7a4726043dc3de3572b7658f77a16f43820b7f35))


### Bug Fixes

* address PR [#21](https://github.com/yavorski/zpack.nvim/issues/21)/[#22](https://github.com/yavorski/zpack.nvim/issues/22) review follow-ups ([c9c6c61](https://github.com/yavorski/zpack.nvim/commit/c9c6c612b9ffe7953e46ff4759d86274b9a9526d))
* check buffer validity before re-triggering FileType events ([a4471ba](https://github.com/yavorski/zpack.nvim/commit/a4471ba37d560014619833161b313a42a2e1c2ad))
* check cond at load time instead of import time ([82fe18a](https://github.com/yavorski/zpack.nvim/commit/82fe18a5fd1590031a0b0873391004de9056e60f))
* **cmd:** "E488: Trailing characters" when invoking lazy trigger cmd with arguments ([d510920](https://github.com/yavorski/zpack.nvim/commit/d510920bdad692f59a4ed6846b59c63813a24a78))
* **cmd:** load plugin when command invoked with args ([15bdbb0](https://github.com/yavorski/zpack.nvim/commit/15bdbb0f06864ceed557858af51d7c2fff567dbc))
* command-specific legacy command deprecation notice ([8970a43](https://github.com/yavorski/zpack.nvim/commit/8970a43b3ab24c7c5d27020e2a23922e198ef5ca))
* correct bang placement in usage hints; always warn on legacy commands ([2f4bf35](https://github.com/yavorski/zpack.nvim/commit/2f4bf356e0faec7d3c99bca725df0d721446b971))
* drop replace_keycodes without expr; centralize noremap alias ([1119c22](https://github.com/yavorski/zpack.nvim/commit/1119c22fe0cc87cf74a4179420e2e7f20abe3419))
* forward ev.data, validate buffer, chain dependencies, and dedupl… ([7ea1529](https://github.com/yavorski/zpack.nvim/commit/7ea1529ba20e0b9a8a1f4f976926a1500d542f4e))
* forward ev.data, validate buffer, chain dependencies, and deduplicate augroups on event re-fire ([2351956](https://github.com/yavorski/zpack.nvim/commit/23519568f1823fcab8c6835b7b7388c1f373fe6e)), closes [#9](https://github.com/yavorski/zpack.nvim/issues/9)
* forward remap to lazy-trigger proxy and cover gap cases ([7db9ad7](https://github.com/yavorski/zpack.nvim/commit/7db9ad7b99610867e7a46c381dba5ebc5574da4c))
* guard non-number priority and non-string import field ([af3f109](https://github.com/yavorski/zpack.nvim/commit/af3f1097152a36493144be22f6e8fd7c32351c90))
* guard non-string src/url/dir in normalize_source ([b127f63](https://github.com/yavorski/zpack.nvim/commit/b127f63279a67f10dd5a3e0c5fc75b7a9cc6785a))
* harden lazy-load path against operator-pending loss + throw-leaks ([#26](https://github.com/yavorski/zpack.nvim/issues/26)) ([c6079d5](https://github.com/yavorski/zpack.nvim/commit/c6079d5b10301bf4c3f59863fd2a23d00271a0e2))
* honor enabled/cond across dependency chains ([b1eab47](https://github.com/yavorski/zpack.nvim/commit/b1eab4799cbe42f0db8a4599ec6bb6733dc25f84))
* improve error handling and fix LSP type warning in loader ([bce3731](https://github.com/yavorski/zpack.nvim/commit/bce3731df7cc6abe19144356cfa96b6a526b64c9))
* **keys:** handle mixed arrays with KeySpec tables and plain strings ([7436d41](https://github.com/yavorski/zpack.nvim/commit/7436d412675a90f17d82d348f4d03d916bb4d786))
* lazy-loaded plugins not fully activating ([a782b9d](https://github.com/yavorski/zpack.nvim/commit/a782b9dffd22e0465f93bb541f75d9fd536338dd))
* lazy-loaded plugins not fully activating ([6b351e5](https://github.com/yavorski/zpack.nvim/commit/6b351e51ae3bd026d80706a11d626d42ea74edad))
* **lazy:** prevent double-execution of hooks with multiple triggers ([18389c6](https://github.com/yavorski/zpack.nvim/commit/18389c66b7771fedc04b0c1794d59ec4e8b49e60))
* **lazy:** support multiple plugins on same command ([1a115db](https://github.com/yavorski/zpack.nvim/commit/1a115dbfac1284cf26f35bb40dd240245a1f0061))
* preserve typeahead order on multi-key sequences ([6b99fcb](https://github.com/yavorski/zpack.nvim/commit/6b99fcb107c1436dfbb7e5cbb0c7072799973a11))
* refresh sorted_plugins cache on add() and setup() ([59e1429](https://github.com/yavorski/zpack.nvim/commit/59e1429bdb03eff06e956c6779a1ded1e90537bc))
* resolve test framework async handling and init hook for lazy plugins ([957c60b](https://github.com/yavorski/zpack.nvim/commit/957c60be494818e966bb2ad77c45fa36b1064109))
* skip lazy trigger setup when builds are pending ([6bea29e](https://github.com/yavorski/zpack.nvim/commit/6bea29eb163b0ba0ae5f939a07a1120eec9c3a2e))
* **tests:** properly exit with error code on test failure ([90b966d](https://github.com/yavorski/zpack.nvim/commit/90b966dbd2c33c1ef294b5efd8cbe0fd95c36461))
* use merged spec for pack_spec.version instead of first spec ([bebe792](https://github.com/yavorski/zpack.nvim/commit/bebe7929b224a2df7f76a22d441cee21c845fabd))
* use vim.pack.get() as source of truth for ZClean ([2d79e1c](https://github.com/yavorski/zpack.nvim/commit/2d79e1ccde5759213608b72ac531ce77ac40bd1b))
* ZDelete! includes zpack.nvim in deletion list ([29de5e6](https://github.com/yavorski/zpack.nvim/commit/29de5e6274d6dfecfe6bdb7da43f9a6d5d8d73f5))


### Performance Improvements

* replace vim.fn.glob with cached vim.uv.fs_scandir ([d6d95db](https://github.com/yavorski/zpack.nvim/commit/d6d95dbdb532cd3ce021542dbcd6bcee0cbb8926))
* restore batch processing for startup plugins ([df7c81f](https://github.com/yavorski/zpack.nvim/commit/df7c81fd047c8bc8002e8a773bc4ab78f99ad308))


### Code Refactoring

* :ZPack with subcommands ([d197fc6](https://github.com/yavorski/zpack.nvim/commit/d197fc6281550f3872c10b1e3ae16b55d656b27b))
* deprecate plugins_dir in favor of { import = 'path' } ([b6e624e](https://github.com/yavorski/zpack.nvim/commit/b6e624e9e329103d227a3dab3c37fc28b7038ca0))
* remove auto_import and add() in favor of spec field ([5c5de51](https://github.com/yavorski/zpack.nvim/commit/5c5de51c488cafa12373f3234bd504313608d940))
