const assert = require('assert')
const addon = require('bindings')('target')

assert.equal(addon.hello, "hello world");
assert.equal(addon.addNums(3, 3, 3), 9);
assert.deepEqual(addon.createArray('jim', 'bob', 3), ['jim', 'bob', 3])

assert.equal(addon.getOrDefault([1, 2, 3], 0/*index*/, 'unexpected'/*default*/), 1)
assert.equal(addon.getOrDefault([1, 2, 3], 5/*index*/, 'expected'/*default*/), 'expected')
