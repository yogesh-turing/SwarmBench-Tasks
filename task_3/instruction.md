The lodash repository at `/lodash` 
Lodash makes JavaScript easier by taking the hassle out of working with arrays,
numbers, objects, strings, etc. Lodash’s modular methods are great for:

Iterating arrays, objects, & strings
Manipulating & testing values
Creating composite functions


Four  bugs have been reported against this component. Find and fix all of them.

## Affected files

- `vendor/firebug-lite/src/firebug-lite-debug.js` — bug 1
- `test/underscore.html` — bug 2
- `vendor/firebug-lite/src/firebug-lite-debug.js` — bug 2
- `tvendor/underscore/test/objects.js` — bug 2
- `vendor/underscore/test/utility.js` — bug 2
- `test/test.js` - bug 3, 4
- `lodash.js` - bug 3, 4

## Bug reports

**Bug 1**
Fix high severity security issue in vendor/firebug-lite/src/firebug-lite-debug.js.
The repository includes the full Firebug Lite debug script (firebug-lite-debug.js) in the vendor directory. This debug tool contains interactive INPUT elements including a text editor input (class 'textEditorInner') that accepts raw user input without sanitization. If this script is served in a production environment, any user — not just developers — can open the Firebug console and execute arbitrary JavaScript in the page context, enabling session token theft, credential harvesting, and DOM manipulation.

**Bug 2** — 
Non functional typos throughout the repository
There are typos in the respository make sure to find them and fix, here are  typos at multiple places.
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

**Bug 3** — `When Object.prototype (or any prototype in the prototype chain) is frozen, assigning a property whose name matches a non-writable property on that frozen prototype fails silently in sloppy mode or throws a TypeError in strict mode. This caused _.clone and _.cloneDeep to silently drop own properties whose names collide with frozen prototype properties (e.g. hasOwnProperty).

**Bug 4** — 
& is the decimal HTML entity for ampersand ("&").
Previously, _.unescape('&#38;') returned '&' instead of '&'.