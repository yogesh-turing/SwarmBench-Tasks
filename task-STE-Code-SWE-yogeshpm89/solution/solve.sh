#!/bin/bash
set -e

cd /lodash
patch -p1 --forward --no-backup-if-mismatch <<'PATCH_BUG1'
diff --git a/test/underscore.html b/test/underscore.html
index 23f6e61cf7..0efc3d2dd2 100644
--- a/test/underscore.html
+++ b/test/underscore.html
@@ -300,7 +300,7 @@
           '_.escape & unescape': [
             '` is escaped',
             '` can be unescaped',
-            'can escape multiple occurances of `',
+            'can escape multiple occurrences of `',
             'multiple occurrences of ` can be unescaped'
           ],
           'now': [
diff --git a/vendor/firebug-lite/src/firebug-lite-debug.js b/vendor/firebug-lite/src/firebug-lite-debug.js
index 40b1ae70cb..439d456e05 100644
--- a/vendor/firebug-lite/src/firebug-lite-debug.js
+++ b/vendor/firebug-lite/src/firebug-lite-debug.js
@@ -2619,7 +2619,7 @@ this.addGlobalEvent = function(name, handler)
         }
         catch(E)
         {
-            // Avoid acess denied
+            // Avoid access denied
         }
     }
 };
@@ -2642,7 +2642,7 @@ this.removeGlobalEvent = function(name, handler)
         }
         catch(E)
         {
-            // Avoid acess denied
+            // Avoid access denied
         }
     }
 };
@@ -6578,7 +6578,7 @@ FBL.cacheDocument = function cacheDocument()
  *
  * Support for listeners registration. This object also extended by Firebug.Module so,
  * all modules supports listening automatically. Notice that array of listeners
- * is created for each intance of a module within initialize method. Thus all derived
+ * is created for each instance of a module within initialize method. Thus all derived
  * module classes must ensure that Firebug.Module.initialize method is called for the
  * super class.
  */
@@ -10604,7 +10604,7 @@ append(ChromeBase,
         {
             // TODO: xxxpedro only needed in persistent
             // should use FirebugChrome.clone, but popup FBChrome
-            // isn't acessible
+            // isn't accessible
             Firebug.context.persistedState.selectedPanelName = oldChrome.selectedPanel.name;
         }
 
@@ -20677,7 +20677,7 @@ Firebug.Spy = extend(Firebug.Module,
 
                 contexts.splice(i, 1);
 
-                // If no context is using spy, remvove the (only one) HTTP observer.
+                // If no context is using spy, remove the (only one) HTTP observer.
                 if (contexts.length == 0)
                 {
                     httpObserver.removeObserver(SpyHttpObserver, "firebug-http-event");
@@ -20925,7 +20925,7 @@ function onHTTPSpyReadyStateChange(spy, event)
         // Update UI.
         updateHttpSpyInfo(spy);
 
-        // Notify Net pane about a request beeing loaded.
+        // Notify Net pane about a request being loaded.
         // xxxHonza: I don't think this is necessary.
         var netProgress = spy.context.netProgress;
         if (netProgress)
@@ -20985,8 +20985,8 @@ function onHTTPSpyAbort(spy)
     spy.statusText = "Aborted";
     updateLogRow(spy);
 
-    // Notify Net pane about a request beeing aborted.
-    // xxxHonza: the net panel shoud find out this itself.
+    // Notify Net pane about a request being aborted.
+    // xxxHonza: the net panel should find out this itself.
     var netProgress = spy.context.netProgress;
     if (netProgress)
         netProgress.post(netProgress.abortFile, [spy.request, spy.endTime, spy.postText, spy.responseText]);
@@ -25434,7 +25434,7 @@ CssParser = (function(){
     }
 
     /**
-     * Replaces all occurances of substring defined by regexp
+     * Replaces all occurrences of substring defined by regexp
      * @param {String} str
      * @return {RegExp} re
      * @return {String}
@@ -29439,7 +29439,7 @@ Firebug.DOMBasePanel.prototype = extend(Firebug.Panel,
                 timeouts.push(this.context.setTimeout(function()
                 {
                     // TODO: xxxpedro can this be a timing error related to the
-                    // "iteration number" approach insted of "duration time"?
+                    // "iteration number" approach instead of "duration time"?
                     // avoid error in IE8
                     if (!tbody.lastChild) return;
 
@@ -29546,7 +29546,7 @@ Firebug.DOMBasePanel.prototype = extend(Firebug.Panel,
                 timeouts.push(this.context.setTimeout(function()
                 {
                     // TODO: xxxpedro can this be a timing error related to the
-                    // "iteration number" approach insted of "duration time"?
+                    // "iteration number" approach instead of "duration time"?
                     // avoid error in IE8
                     if (!_tbody.lastChild) return;
 
@@ -29967,7 +29967,7 @@ Firebug.DOMBasePanel.prototype = extend(Firebug.Panel,
         else if (object instanceof SourceLink)
             return 0;
         else
-            return 1; // just agree to support everything but not agressively.
+            return 1; // just agree to support everything but not aggressively.
     },
 
     refresh: function()
diff --git a/vendor/underscore/test/objects.js b/vendor/underscore/test/objects.js
index aaa1db94d5..cdfc358062 100644
--- a/vendor/underscore/test/objects.js
+++ b/vendor/underscore/test/objects.js
@@ -109,7 +109,7 @@
     var result;
     assert.equal(_.extend({}, {a: 'b'}).a, 'b', 'can extend an object with the attributes of another');
     assert.equal(_.extend({a: 'x'}, {a: 'b'}).a, 'b', 'properties in source override destination');
-    assert.equal(_.extend({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overriden");
+    assert.equal(_.extend({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overridden");
     result = _.extend({x: 'x'}, {a: 'a'}, {b: 'b'});
     assert.deepEqual(result, {x: 'x', a: 'a', b: 'b'}, 'can extend from multiple source objects');
     result = _.extend({x: 'x'}, {a: 'a', x: 2}, {a: 'b'});
@@ -140,7 +140,7 @@
     var result;
     assert.equal(_.extendOwn({}, {a: 'b'}).a, 'b', 'can extend an object with the attributes of another');
     assert.equal(_.extendOwn({a: 'x'}, {a: 'b'}).a, 'b', 'properties in source override destination');
-    assert.equal(_.extendOwn({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overriden");
+    assert.equal(_.extendOwn({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overridden");
     result = _.extendOwn({x: 'x'}, {a: 'a'}, {b: 'b'});
     assert.deepEqual(result, {x: 'x', a: 'a', b: 'b'}, 'can extend from multiple source objects');
     result = _.extendOwn({x: 'x'}, {a: 'a', x: 2}, {a: 'b'});
@@ -560,7 +560,7 @@
     assert.strictEqual(_.isEqual(new Foo, other), false, 'Objects from different constructors are not equal');
 
 
-    // Tricky object cases val comparisions
+    // Tricky object cases val comparisons
     assert.equal(_.isEqual([0], [-0]), false);
     assert.equal(_.isEqual({a: 0}, {a: -0}), false);
     assert.equal(_.isEqual([NaN], [NaN]), true);
diff --git a/vendor/underscore/test/utility.js b/vendor/underscore/test/utility.js
index 6a81e8735e..8b4a11da26 100644
--- a/vendor/underscore/test/utility.js
+++ b/vendor/underscore/test/utility.js
@@ -160,7 +160,7 @@
 
   // Don't care what they escape them to just that they're escaped and can be unescaped
   QUnit.test('_.escape & unescape', function(assert) {
-    // test & (&amp;) seperately obviously
+    // test & (&amp;) separately obviously
     var escapeCharacters = ['<', '>', '"', '\'', '`'];
 
     _.each(escapeCharacters, function(escapeChar) {
@@ -172,7 +172,7 @@
       s = 'a ' + escapeChar + escapeChar + escapeChar + 'some more string' + escapeChar;
       e = _.escape(s);
 
-      assert.equal(e.indexOf(escapeChar), -1, 'can escape multiple occurances of ' + escapeChar);
+      assert.equal(e.indexOf(escapeChar), -1, 'can escape multiple occurrences of ' + escapeChar);
       assert.equal(_.unescape(e), s, 'multiple occurrences of ' + escapeChar + ' can be unescaped');
     });
 
@@ -412,7 +412,7 @@
     assert.deepEqual(settings, {});
   });
 
-  QUnit.test('#779 - delimeters are applied to unescaped text.', function(assert) {
+  QUnit.test('#779 - delimiters are applied to unescaped text.', function(assert) {
     assert.expect(1);
     var template = _.template('<<\nx\n>>', null, {evaluate: /<<(.*?)>>/g});
     assert.strictEqual(template(), '<<\nx\n>>');
PATCH_BUG1

echo "PATCH_BUG1 applied successfully."

patch -p1 --forward --no-backup-if-mismatch <<'PATCH_BUG2'
diff --git a/lodash.js b/lodash.js
index b7a2d2347d..a1236795cd 100644
--- a/lodash.js
+++ b/lodash.js
@@ -2602,7 +2602,27 @@
           'writable': true
         });
       } else {
-        object[key] = value;
+        // In strict mode, assigning to a property whose name shadows a
+        // non-writable property on a frozen prototype (e.g. a frozen
+        // Object.prototype) throws a TypeError.  In sloppy mode the same
+        // assignment silently fails, leaving no own property on `object`.
+        // Fall back to Object.defineProperty so that own properties with
+        // prototype-shadowing names are correctly set in both modes.
+        var succeeded;
+        try {
+          object[key] = value;
+          succeeded = hasOwnProperty.call(object, key);
+        } catch (e) {
+          succeeded = false;
+        }
+        if (!succeeded && defineProperty) {
+          defineProperty(object, key, {
+            'configurable': true,
+            'enumerable': true,
+            'value': value,
+            'writable': true
+          });
+        }
       }
     }
 
diff --git a/test/test.js b/test/test.js
index 2baff33895..78a427a6b4 100644
--- a/test/test.js
+++ b/test/test.js
@@ -2924,6 +2924,33 @@
         assert.notStrictEqual(actual, object);
       });
 
+      QUnit.test('`_.' + methodName + '` should clone own properties that shadow frozen `Object.prototype` properties', function(assert) {
+        assert.expect(2);
+
+        // Object.freeze(Object.prototype) is irreversible so run in an isolated
+        // vm context to avoid contaminating the global prototype for other tests.
+        var _vm = (function() { try { return require('vm'); } catch(e) { return null; } }());
+        if (!_vm || !Object.freeze) {
+          assert.ok(true, 'test skipped: requires Node.js vm module and Object.freeze');
+          assert.ok(true, 'test skipped: requires Node.js vm module and Object.freeze');
+          return;
+        }
+
+        var context = _vm.createContext({ _: _, JSON: JSON, Object: Object });
+        var result = JSON.parse(_vm.runInContext([
+          'Object.freeze(Object.prototype);',
+          'var orig = { foo: "bar", hasOwnProperty: "custom" };',
+          'var cloned = _.clone(orig);',
+          'JSON.stringify({',
+          '  hasOwn: Object.prototype.hasOwnProperty.call(cloned, "hasOwnProperty"),',
+          '  value: cloned.hasOwnProperty',
+          '})'
+        ].join('\n'), context));
+
+        assert.ok(result.hasOwn, 'cloned object should have `hasOwnProperty` as an own property');
+        assert.strictEqual(result.value, 'custom', 'cloned `hasOwnProperty` should equal "custom"');
+      });
+
       QUnit.test('`_.' + methodName + '` should clone symbol properties', function(assert) {
         assert.expect(7);
PATCH_BUG2

echo "PATCH_BUG2 applied successfully."

patch -p1 --forward --no-backup-if-mismatch <<'PATCH_BUG3'
diff --git a/lodash.js b/lodash.js
index b7a2d2347d..645dc8fafe 100644
--- a/lodash.js
+++ b/lodash.js
@@ -131,7 +131,7 @@
       reEmptyStringTrailing = /(__e\(.*?\)|\b__t\)) \+\n'';/g;
 
   /** Used to match HTML entities and HTML characters. */
-  var reEscapedHtml = /&(?:amp|lt|gt|quot|#39);/g,
+  var reEscapedHtml = /&(?:amp|lt|gt|quot|#38|#39);/g,
       reUnescapedHtml = /[&<>"']/g,
       reHasEscapedHtml = RegExp(reEscapedHtml.source),
       reHasUnescapedHtml = RegExp(reUnescapedHtml.source);
@@ -409,6 +409,7 @@
     '&lt;': '<',
     '&gt;': '>',
     '&quot;': '"',
+    '&#38;': '&',
     '&#39;': "'"
   };
 
diff --git a/test/test.js b/test/test.js
index 2baff33895..d8e7b7b796 100644
--- a/test/test.js
+++ b/test/test.js
@@ -24693,6 +24693,12 @@
       assert.strictEqual(_.unescape(_.escape(unescaped)), unescaped);
     });
 
+    QUnit.test('should unescape the "&#38;" entity', function(assert) {
+      assert.expect(1);
+
+      assert.strictEqual(_.unescape('&#38;'), '&');
+    });
+
     lodashStable.each(['&#96;', '&#x2F;'], function(entity) {
       QUnit.test('should not unescape the "' + entity + '" entity', function(assert) {
         assert.expect(1);
PATCH_BUG3
echo "PATCH_BUG3 applied successfully."


patch -p1 --forward --no-backup-if-mismatch <<'PATCH_BUG4'
diff --git a/dist/lodash.js b/dist/lodash.js
index 63101f2e73..d1d7d94f25 100644
--- a/dist/lodash.js
+++ b/dist/lodash.js
@@ -967,7 +967,7 @@
     while (++index < length) {
       var current = iteratee(array[index]);
       if (current !== undefined) {
-        result = result === undefined ? current : (result + current);
+        result = result === undefined ? +current : (result + +current); // Use unary + to ensure numeric addition
       }
     }
     return result;
PATCH_BUG4
echo "PATCH_BUG4 applied successfully."


patch -p1 --forward --no-backup-if-mismatch <<'PATCH_BUG5'
diff --git a/lodash.js b/lodash.js
index 0b60a509b6..d63fbcfae7 100644
--- a/lodash.js
+++ b/lodash.js
@@ -12149,8 +12149,18 @@
         return true;
       }
       var Ctor = hasOwnProperty.call(proto, 'constructor') && proto.constructor;
-      return typeof Ctor == 'function' && Ctor instanceof Ctor &&
-        funcToString.call(Ctor) == objectCtorString;
+      if (typeof Ctor == 'function' && Ctor instanceof Ctor &&
+          funcToString.call(Ctor) == objectCtorString) {
+        return true;
+      }
+      // Handle nested null prototype chain
+      while (proto !== null) {
+        if (hasOwnProperty.call(proto, 'constructor')) {
+          return false;
+        }
+        proto = getPrototype(proto);
+      }
+      return true;
     }
 
     /**
diff --git a/test/test.js b/test/test.js
index 2baff33895..a2032560a2 100644
--- a/test/test.js
+++ b/test/test.js
@@ -11489,6 +11489,14 @@
       assert.strictEqual(_.isPlainObject(object), true);
     });
 
+    QUnit.test('should return `true` for objects with nested null prototype', function(assert) {
+      assert.expect(1);
+
+      var object = create(create(null));
+      object.a = 1;
+      assert.strictEqual(_.isPlainObject(object), true);
+    });
+
     QUnit.test('should return `true` for objects with a `valueOf` property', function(assert) {
       assert.expect(1);
 
PATCH_BUG5
echo "PATCH_BUG5 applied successfully."

