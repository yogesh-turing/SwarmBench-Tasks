#!/usr/bin/env bash
set -euo pipefail

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/common/editableList.js
@@
-            this.element.addClass('red-ui-editableList-list');
+            this.element.addClass('red-ui-editableList-list');
+            if (this.options.ariaLabel) {
+                this.element.attr('aria-label', this.options.ariaLabel);
+            }
+            if (this.options.ariaLabelledBy) {
+                this.element.attr('aria-labelledby', this.options.ariaLabelledBy);
+            }
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/common/searchBox.js
@@
-                this.optsButton = $('<a class="red-ui-searchBox-opts" href="#"><i class="fa fa-caret-down"></i></a>').attr('aria-label', RED._('search.options.label')).appendTo(this.uiContainer);
+                this.optsButton = $('<a class="red-ui-searchBox-opts" href="#" aria-haspopup="menu" aria-expanded="false"><i class="fa fa-caret-down"></i></a>').attr('aria-label', RED._('search.options.label')).appendTo(this.uiContainer);
@@
-                        menuShown = false;
+                        menuShown = false;
+                        that.optsButton.attr('aria-expanded', 'false');
@@
-                    menuShown = true;
+                    menuShown = true;
+                    that.optsButton.attr('aria-expanded', 'true');
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/common/toggleButton.js
@@
-            this.button = $('<button type="button" class="red-ui-toggleButton '+baseClass+' toggle single"></button>');
+            this.button = $('<button type="button" aria-pressed="false" class="red-ui-toggleButton '+baseClass+' toggle single"></button>');
@@
-                    that.button.addClass("selected");
+                    that.button.addClass("selected");
+                    that.button.attr("aria-pressed", "true");
@@
-                    that.button.removeClass("selected");
+                    that.button.removeClass("selected");
+                    that.button.attr("aria-pressed", "false");
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/common/treeList.js
@@
-            this.element.addClass('red-ui-treeList');
-            this.element.attr("tabIndex",0);
+            this.element.addClass('red-ui-treeList');
+            this.element.attr("tabIndex",0);
+            if (this.options.ariaLabel) {
+                this.element.attr('aria-label', this.options.ariaLabel);
+            }
+            if (this.options.ariaLabelledBy) {
+                this.element.attr('aria-labelledby', this.options.ariaLabelledBy);
+            }
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/common/typedInput.js
@@
-            ["type","placeholder","autocomplete","data-i18n"].forEach(function(d) {
+            ["type","placeholder","autocomplete","data-i18n","aria-label","aria-labelledby"].forEach(function(d) {
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/notifications.js
@@
-        if (!RED.notifications.hide) {
+        if (!RED.notifications.hide) {
             $(n).slideDown(300);
         }
+        // Move focus to the notification when it has actions or is modal —
+        // transient toasts must not steal focus.
+        if (options.modal || options.buttons) {
+            setTimeout(function() {
+                var firstButton = $(n).find('button:visible:first');
+                if (firstButton.length) {
+                    firstButton.trigger('focus');
+                }
+            }, 0);
+        }
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/palette.js
@@
-            '<div id="red-ui-palette-header-'+category+'" class="red-ui-palette-header"><i class="expanded fa fa-angle-down"></i><span>'+label+'</span></div>'+
+            '<div id="red-ui-palette-header-'+category+'" class="red-ui-palette-header" role="button" tabindex="0" aria-expanded="true"><i class="expanded fa fa-angle-down"></i><span>'+label+'</span></div>'+
@@
-                $("#red-ui-palette-header-"+category+" i").removeClass("expanded");
+                $("#red-ui-palette-header-"+category+" i").removeClass("expanded");
+                $("#red-ui-palette-header-"+category).attr("aria-expanded", "false");
@@
-                $("#red-ui-palette-header-"+category+" i").addClass("expanded");
+                $("#red-ui-palette-header-"+category+" i").addClass("expanded");
+                $("#red-ui-palette-header-"+category).attr("aria-expanded", "true");
@@
         $("#red-ui-palette-header-"+category).on('click', function(e) {
             categoryContainers[category].toggle();
         });
+        $("#red-ui-palette-header-"+category).on('keydown', function(e) {
+            if (e.key === 'Enter' || e.key === ' ') {
+                e.preventDefault();
+                categoryContainers[category].toggle();
+            }
+        });
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/sidebar.js
@@
-        sidebar.toggleButton?.toggleClass('selected', isOpen)
+        sidebar.toggleButton?.toggleClass('selected', isOpen)
+        sidebar.toggleButton?.attr('aria-expanded', isOpen ? 'true' : 'false')
@@
-        globalTabBar.overflowButton = $('<button class="red-ui-sidebar-tab-bar-overflow-button"><i class="fa fa-ellipsis-v"></i></button>').attr('aria-label', RED._('sidebar.moreTabs')).appendTo(tabBarTools);
+        globalTabBar.overflowButton = $('<button class="red-ui-sidebar-tab-bar-overflow-button" aria-haspopup="menu" aria-expanded="false"><i class="fa fa-ellipsis-v"></i></button>').attr('aria-label', RED._('sidebar.moreTabs')).appendTo(tabBarTools);
@@
-                        menuShown = false
+                        menuShown = false
+                        globalTabBar.overflowButton.attr('aria-expanded', 'false');
@@
-                menuShown = true
+                menuShown = true
+                globalTabBar.overflowButton.attr('aria-expanded', 'true');
*** End Patch
PATCH

apply_patch <<'"'"'PATCH'"'"'
*** Begin Patch
*** Update File: packages/node_modules/@node-red/editor-client/src/js/ui/tray.js
@@
-                    tray.tray.css({right:0});
+                    tray.tray.css({right:0});
+                    tray.tray.prop("inert", false);
@@
-                tray.tray.css({
+                tray.tray.css({
                     right:-(tray.tray.width()+10)+"px"
                 });
+                tray.tray.prop("inert", true);
*** End Patch
PATCH

npm test -- --help >/dev/null
