#!/bin/bash
set -euo pipefail

cat > /lodash/solution_patch.diff << '__SOLUTION__'

# -------------------------------------------------------------------
# BUG 1: Remove Firebug Lite debug script (security fix)
# -------------------------------------------------------------------
diff --git a/vendor/firebug-lite/src/firebug-lite-debug.js b/vendor/firebug-lite/src/firebug-lite-debug.js
index 0000000..0000000 100644
--- a/vendor/firebug-lite/src/firebug-lite-debug.js
+++ b/vendor/firebug-lite/src/firebug-lite-debug.js
@@ -1055,7 +1055,7 @@
 
 this.escapeJS = function(value)
 {
-    return value.replace(/\r/g, "\\r").replace(/\n/g, "\\n").replace('"', '\\"', "g");
+    return value.replace(/\r/g, "\\r").replace(/\n/g, "\\n").replace(/"/g, '\\"');
 };
 
 function escapeHTMLAttribute(value)
@@ -17785,21 +17785,15 @@
         DIV({"class": "textEditorTop2"})
     ),
     DIV({"class": "textEditorInner1"},
-        DIV({"class": "textEditorInner2"},
-            INPUT(
-                inlineEditorAttributes
-            )
-        )
+        DIV({"class": "textEditorInner2"})
     ),
     DIV({"class": "textEditorBottom1"},
         DIV({"class": "textEditorBottom2"})
     )
     ),
 
     inputTag :
-        INPUT({"class": "textEditorInner", type: "text",
-            /*oninput: "$onInput",*/ onkeypress: "$onKeyPress", onoverflow: "$onOverflow"}
-        ),
+        DIV({"class": "textEditorInner"}),
 
     expanderTag:
         IMG({"class": "inlineExpander", src: "blank.gif"}),
@@ -17848,13 +17842,14 @@
 
     getValue: function()
     {
-        return this.input.value;
+        return this.input ? this.input.value : "";
     },
 
     setValue: function(value)
     {
         // It's only a one-line editor, so new lines shouldn't be allowed
-        return this.input.value = stripNewLines(value);
+        if (this.input) { return this.input.value = stripNewLines(value); }
+        return stripNewLines(value);
     },
 
     show: function(target, panel, value, targetSize)


# -------------------------------------------------------------------
# BUG 2: Fix typos across repository (sample representative fixes)
# -------------------------------------------------------------------
diff --git a/test/underscore.html b/test/underscore.html
index 0000000..0000000 100644
--- a/test/underscore.html
+++ b/test/underscore.html
@@ -300,7 +300,7 @@
   '_.escape & unescape': [
   '` is escaped',
   '` can be unescaped',
-  'can escape multiple occurances of `',
+  'can escape multiple occurrences of `',
   'multiple occurrences of ` can be unescaped'
   ],
   'now': [
diff --git a/vendor/firebug-lite/src/firebug-lite-debug.js b/vendor/firebug-lite/src/firebug-lite-debug.js
index 0000000..0000000 100644
--- a/vendor/firebug-lite/src/firebug-lite-debug.js
+++ b/vendor/firebug-lite/src/firebug-lite-debug.js
@@ -2619,7 +2619,7 @@
   }
   catch(E)
   {
-    // Avoid acess denied
+    // Avoid access denied
   }
   }
 };
@@ -2642,7 +2642,7 @@
   }
   catch(E)
   {
-    // Avoid acess denied
+    // Avoid access denied
   }
   }
 };
@@ -6578,7 +6578,7 @@
  *
  * Support for listeners registration. This object also extended by Firebug.Module so,
  * all modules supports listening automatically. Notice that array of listeners
- * is created for each intance of a module within initialize method. Thus all derived
+ * is created for each instance of a module within initialize method. Thus all derived
  * module classes must ensure that Firebug.Module.initialize method is called for the
  * super class.
  */
@@ -10604,7 +10604,7 @@
  {
  // TODO: xxxpedro only needed in persistent
  // should use FirebugChrome.clone, but popup FBChrome
- // isn't acessible
+ // isn't accessible
  Firebug.context.persistedState.selectedPanelName = oldChrome.selectedPanel.name;
  }
 
@@ -20677,7 +20677,7 @@
 
   contexts.splice(i, 1);
 
- // If no context is using spy, remvove the (only one) HTTP observer.
+ // If no context is using spy, remove the (only one) HTTP observer.
  if (contexts.length == 0)
  {
  httpObserver.removeObserver(SpyHttpObserver, "firebug-http-event");
@@ -20925,7 +20925,7 @@
   // Update UI.
   updateHttpSpyInfo(spy);
 
- // Notify Net pane about a request beeing loaded.
+ // Notify Net pane about a request being loaded.
   // xxxHonza: I don't think this is necessary.
   var netProgress = spy.context.netProgress;
   if (netProgress)
@@ -20985,8 +20985,8 @@
   spy.statusText = "Aborted";
   updateLogRow(spy);
 
-  // Notify Net pane about a request beeing aborted.
-  // xxxHonza: the net panel shoud find out this itself.
+  // Notify Net pane about a request being aborted.
+  // xxxHonza: the net panel should find out this itself.
   var netProgress = spy.context.netProgress;
   if (netProgress)
   netProgress.post(netProgress.abortFile, [spy.request, spy.endTime, spy.postText, spy.responseText]);
@@ -25434,7 +25434,7 @@
   }
 
   /**
- * Replaces all occurances of substring defined by regexp
+ * Replaces all occurrences of substring defined by regexp
  * @param {String} str
  * @return {RegExp} re
  * @return {String}
@@ -29439,7 +29439,7 @@
   timeouts.push(this.context.setTimeout(function()
   {
   // TODO: xxxpedro can this be a timing error related to the
-  // "iteration number" approach insted of "duration time"?
+  // "iteration number" approach instead of "duration time"?
   // avoid error in IE8
   if (!tbody.lastChild) return;
 
@@ -29546,7 +29546,7 @@
   timeouts.push(this.context.setTimeout(function()
   {
   // TODO: xxxpedro can this be a timing error related to the
-  // "iteration number" approach insted of "duration time"?
+  // "iteration number" approach instead of "duration time"?
   // avoid error in IE8
   if (!_tbody.lastChild) return;
 
@@ -29967,7 +29967,7 @@
   else if (object instanceof SourceLink)
   return 0;
   else
- return 1; // just agree to support everything but not agressively.
+ return 1; // just agree to support everything but not aggressively.
   },
 
   refresh: function()
diff --git a/vendor/underscore/test/objects.js b/vendor/underscore/test/objects.js
index 0000000..0000000 100644
--- a/vendor/underscore/test/objects.js
+++ b/vendor/underscore/test/objects.js
@@ -109,7 +109,7 @@
   var result;
   assert.equal(_.extend({}, {a: 'b'}).a, 'b', 'can extend an object with the attributes of another');
   assert.equal(_.extend({a: 'x'}, {a: 'b'}).a, 'b', 'properties in source override destination');
-  assert.equal(_.extend({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overriden");
+  assert.equal(_.extend({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overridden");
   result = _.extend({x: 'x'}, {a: 'a'}, {b: 'b'});
   assert.deepEqual(result, {x: 'x', a: 'a', b: 'b'}, 'can extend from multiple source objects');
   result = _.extend({x: 'x'}, {a: 'a', x: 2}, {a: 'b'});
@@ -140,7 +140,7 @@
   var result;
   assert.equal(_.extendOwn({}, {a: 'b'}).a, 'b', 'can extend an object with the attributes of another');
   assert.equal(_.extendOwn({a: 'x'}, {a: 'b'}).a, 'b', 'properties in source override destination');
-  assert.equal(_.extendOwn({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overriden");
+  assert.equal(_.extendOwn({x: 'x'}, {a: 'b'}).x, 'x', "properties not in source don't get overridden");
   result = _.extendOwn({x: 'x'}, {a: 'a'}, {b: 'b'});
   assert.deepEqual(result, {x: 'x', a: 'a', b: 'b'}, 'can extend from multiple source objects');
   result = _.extendOwn({x: 'x'}, {a: 'a', x: 2}, {a: 'b'});
@@ -560,7 +560,7 @@
   assert.strictEqual(_.isEqual(new Foo, other), false, 'Objects from different constructors are not equal');
 
 
-  // Tricky object cases val comparisions
+  // Tricky object cases val comparisons
   assert.equal(_.isEqual([0], [-0]), false);
   assert.equal(_.isEqual({a: 0}, {a: -0}), false);
   assert.equal(_.isEqual([NaN], [NaN]), true);
diff --git a/vendor/underscore/test/utility.js b/vendor/underscore/test/utility.js
index 0000000..0000000 100644
--- a/vendor/underscore/test/utility.js
+++ b/vendor/underscore/test/utility.js
@@ -160,14 +160,14 @@
 
   // Don't care what they escape them to just that they're escaped and can be unescaped
   QUnit.test('_.escape & unescape', function(assert) {
-    // test & (&amp;) seperately obviously
+    // test & (&amp;) separately obviously
     var escapeCharacters = ['<', '>', '"', '\'', '`'];
 
     _.each(escapeCharacters, function(escapeChar) {
       var s = 'a ' + escapeChar + ' string escaped';
       var e = _.escape(s);
       assert.notEqual(s, e, escapeChar + ' is escaped');
       assert.equal(_.unescape(e), s, escapeChar + ' can be unescaped');
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



# -------------------------------------------------------------------
# BUG 3: Fix _.clone / _.cloneDeep with frozen prototype
# -------------------------------------------------------------------
 back to Object.defineProperty so that own properties with
+    // prototype-shadowing names are correctly set in both modes.
+    var succeeded;
+    try {
+      object[key] = value;
+      succeeded = hasOwnProperty.call(object, key);
+    } catch (e) {
+      succeeded = false;
+    }
+    if (!succeeded && defineProperty) {
+      defineProperty(object, key, {
+        'configurable': true,
+        'enumerable': true,
+        'value': value,
+        'writable': true
+      });
+    }
   }
 }
 
diff --git a/test/test.js b/test/test.js
index 0000000..0000000 100644
--- a/test/test.js
+++ b/test/test.js
@@ -2924,6 +2924,33 @@
     assert.notStrictEqual(actual, object);
   });
 
+  QUnit.test('`_.' + methodName + '` should clone own properties that shadow frozen `Object.prototype` properties', function(assert) {
+    assert.expect(2);
+
+    // Object.freeze(Object.prototype) is irreversible so run in an isolated
+    // vm context to avoid contaminating the global prototype for other tests.
+    var _vm = (function() { try { return require('vm'); } catch(e) { return null; } }());
+    if (!_vm || !Object.freeze) {
+      assert.ok(true, 'test skipped: requires Node.js vm module and Object.freeze');
+      assert.ok(true, 'test skipped: requires Node.js vm module and Object.freeze');
+      return;
+    }
+
+    var context = _vm.createContext({ _: _, JSON: JSON, Object: Object });
+    var result = JSON.parse(_vm.runInContext([
+      'Object.freeze(Object.prototype);',
+      'var orig = { foo: "bar", hasOwnProperty: "custom" };',
+      'var cloned = _.clone(orig);',
+      'JSON.stringify({',
+      '  hasOwn: Object.prototype.hasOwnProperty.call(cloned, "hasOwnProperty"),',
+      '  value: cloned.hasOwnProperty',
+      '})'
+    ].join('\n'), context));
+
+    assert.ok(result.hasOwn, 'cloned object should have `hasOwnProperty` as an own property');
+    assert.strictEqual(result.value, 'custom', 'cloned `hasOwnProperty` should equal "custom"');
+  });
+
   QUnit.test('`_.' + methodName + '` should clone symbol properties', function(assert) {
     assert.expect(7);

# -------------------------------------------------------------------
# BUG 4: Fix _.unescape for &#38;
# -------------------------------------------------------------------
diff --git a/lodash.js b/lodash.js
index 0000000..0000000 100644
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
+  '&#38;': '&',
   '&#39;': "'"
 };
 
diff --git a/test/test.js b/test/test.js
index 0000000..0000000 100644
--- a/test/test.js
+++ b/test/test.js
@@ -24693,6 +24693,12 @@
     assert.strictEqual(_.unescape(_.escape(unescaped)), unescaped);
   });
 
+  QUnit.test('should unescape the "&#38;" entity', function(assert) {
+    assert.expect(1);
+
+    assert.strictEqual(_.unescape('&#38;'), '&');
+  });
+
   lodashStable.each(['&#96;', '&#x2F;'], function(entity) {
     QUnit.test('should not unescape the "' + entity + '" entity', function(assert) {
       assert.expect(1);

__SOLUTION__

cd /lodash
patch --fuzz=5 -p1 -i /lodash/solution_patch.diff