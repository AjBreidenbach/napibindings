var addon = require('bindings')('target')
var SegfaultHandler = require('segfault-handler');

SegfaultHandler.registerHandler('crash.log', (signal, address, stack) => console.log(stack));


console.log(addon.hello);

