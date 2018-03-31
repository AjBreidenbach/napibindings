//var addon = require('bindings')('target')
//console.log(addon.hello.fib(15));



// node parallel //

/*
function fibonacci(n) { return n < 1 ? 1 : fibonacci(n-1) + fibonacci(n-2) }

const fib10 = new Promise(resolve => resolve(fibonacci(35)));
const fib20 = new Promise(resolve => resolve(fibonacci(35)));
const fib30 = new Promise(resolve => resolve(fibonacci(35)));
const fib40 = new Promise(resolve => resolve(fibonacci(35)));

Promise.all([fib10, fib20, fib30, fib40]).then(v => console.log(v));
*/

// node sequential //
/*
function fibonacci(n) { return n < 1 ? 1 : fibonacci(n-1) + fibonacci(n-2) }

console.log(fibonacci(35));
console.log(fibonacci(35));
console.log(fibonacci(35));
console.log(fibonacci(35));
*/

var addon = require('bindings')('target')

const fib10 = new Promise(resolve => resolve(addon.fib(35)));
const fib20 = new Promise(resolve => resolve(addon.fib(35)));
const fib30 = new Promise(resolve => resolve(addon.fib(35)));
const fib40 = new Promise(resolve => resolve(addon.fib(35)));

Promise.all([fib10, fib20, fib30, fib40]).then(v => console.log(v));
