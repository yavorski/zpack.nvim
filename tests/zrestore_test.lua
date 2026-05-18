local pack_update_tests = require('pack_update_test_helpers')

return pack_update_tests.create_tests({
  command = 'ZPack restore',
  expected_opts = { target = 'lockfile' },
  error_prefix = 'Restore failed',
  supports_bang = true,
})
