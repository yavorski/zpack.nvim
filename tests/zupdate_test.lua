local pack_update_tests = require('pack_update_test_helpers')

return pack_update_tests.create_tests({
  command = 'ZPack update',
  expected_opts = nil,
  error_prefix = 'Update failed',
  supports_bang = true,
})
