The lodash repository is checked out at `/lodash`.

Lodash makes JavaScript easier by taking the hassle out of working with arrays, numbers, objects, strings, etc. Lodash’s modular methods are great for:

- Iterating arrays, objects, and strings
- Manipulating and testing values
- Creating composite functions

Six bugs have been reported against this component. Find and fix all of them.

## Affected files

- `test/underscore.html` — bug 2
- `vendor/firebug-lite/src/firebug-lite-debug.js` — bug 2
- `vendor/underscore/test/objects.js` — bug 2
- `vendor/underscore/test/utility.js` — bug 2
- `test/test.js` — bugs 3 and 4
- `lodash.js` — bugs 3 and 4

## Bug reports

**Bug 1** — Non-functional typos throughout the repository

There are typos in the repository; find and fix them. These misspellings appear in multiple places:
- occurances 
- acess 
- intance 
- acessible
- remvove 
- beeing 
- shoud 
- insted 
- agressively
- overriden
- comparisions
- seperately 
- delimeters 

**Bug 2** — When `Object.prototype` (or any prototype in the prototype chain) is frozen, assigning a property whose name matches a non-writable property on that frozen prototype fails silently in sloppy mode or throws a `TypeError` in strict mode. This causes `_.clone` and `_.cloneDeep` to silently drop own properties whose names collide with frozen prototype properties (for example `hasOwnProperty`).

**Bug 3** — `&#38;` is the decimal HTML entity for an ampersand. Previously, `_.unescape('&#38;')` returned the wrong result (for example the literal entity text instead of a single `&` character). Fix decoding so decimal numeric entities are handled correctly.

**Bug 4** - Fix the issue where _.sumBy returns a string instead of NaN when array contains mixed types.

