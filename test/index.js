const assert = require('assert')
const addon = require('bindings')('main')

assert.strictEqual(addon.hello, "hello world");
assert.strictEqual(addon.addNums(3, 3, 3), 9);
assert.deepStrictEqual(addon.createArray('jim', 'bob', 3), ['jim', 'bob', 3])

assert.strictEqual(addon.getOrDefault([1, 2, 3], 0/*index*/, 'unexpected'/*default*/), 1)
assert.strictEqual(addon.getOrDefault([1, 2, 3], 5/*index*/, 'expected'/*default*/), 'expected')
