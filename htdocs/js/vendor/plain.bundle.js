/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./js/SimpleToolbar.js":
/*!*****************************!*\
  !*** ./js/SimpleToolbar.js ***!
  \*****************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "itemTypes": () => (/* binding */ itemTypes),
/* harmony export */   "SimpleToolbar": () => (/* binding */ SimpleToolbar)
/* harmony export */ });
/* harmony import */ var _ToolbarDropdown_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./ToolbarDropdown.js */ "./js/ToolbarDropdown.js");
/* harmony import */ var _ToolbarItem_js__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./ToolbarItem.js */ "./js/ToolbarItem.js");
/* harmony import */ var _ToolbarItemGroup_js__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./ToolbarItemGroup.js */ "./js/ToolbarItemGroup.js");
/* harmony import */ var _ToolbarMenu_js__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./ToolbarMenu.js */ "./js/ToolbarMenu.js");




//import './sass/menu-button.scss';

const itemTypes = {
    dropdown: _ToolbarDropdown_js__WEBPACK_IMPORTED_MODULE_0__.ToolbarDropdown,
    menu: _ToolbarMenu_js__WEBPACK_IMPORTED_MODULE_3__.ToolbarMenu,
    buttongroup: _ToolbarItemGroup_js__WEBPACK_IMPORTED_MODULE_2__.ToolbarGroup,
    link: _ToolbarItem_js__WEBPACK_IMPORTED_MODULE_1__.LinkItem,
    spacer: _ToolbarItem_js__WEBPACK_IMPORTED_MODULE_1__.SpacerItem,
    defaultType: _ToolbarItem_js__WEBPACK_IMPORTED_MODULE_1__.ToolbarItem
};

class SimpleToolbar {
  constructor(items, label, editorId, opts) {
    this.opts = opts || {};
    this.iconClass = this.opts.iconClass || "fas fa-";
    this.itemTypes = this.opts.itemTypes || itemTypes;
    this.items = this.createItems(items);
    this.label = label;
    this.editorId = editorId;
    this.editorView = document.getElementById(editorId);
    this.navItems = this.items.flatMap(item => item.navItem());

    this.domNode = this.createElement();
    this.current = 0;

    this.last = this.navItems.length - 1;

    this.navItems[this.current].domNode.setAttribute('tabindex', '0');

    this.domNode.addEventListener('keydown', e => {
        var flag = false;
        switch (e.key) {

        case " ":
        case "Spacebar":
        case "Enter":
            this.activateItem(this.navItems[this.current]);
            flag = true;
            break;

        case "ArrowRight":
        case "Right":
            this.setFocusToNext(this);
            flag = true;
            break;

        case "ArrowLeft":
        case "Left":
            this.setFocusToPrevious(this);
            flag = true;
            break;

        case "Home":
            this.current = 0;
            this.setFocusItem(this.navItems[0]);
            flag = true;
            break;

        case "End":
            this.current = this.last;
            this.setFocusItem(this.navItems[this.last]);
            flag = true;
            break;

        default:
            break;
        }

        if (flag) {
            e.stopPropagation();
            e.preventDefault();
        }

    });
  }

  updateOpts(opts) {
    this.activateItem = opts.activate  || this.activateItem;
    this.update = opts.update  || this.update;
    this.iconClass = opts.iconClass  || this.iconClass;
  }

  setFocusItem (item) {
    this.navItems.forEach(item => {item.domNode.setAttribute('tabindex', '-1');});
    this.current = this.navItems.indexOf(item);
    item.domNode.setAttribute('tabindex', '0');
    item.domNode.focus();
  }

  setFocusToNext () {
    this.current = this.current === this.last ? 0 : this.current + 1;
    let newItem = this.navItems[this.current];
    this.setFocusItem(newItem);
  }

  setFocusToPrevious () {
    this.current = this.current === 0 ? this.last : this.current - 1;
    let newItem = this.navItems[this.current];
    this.setFocusItem(newItem);
  }

  createItems(items) {
      return items.map( item => {
          var itemClass;
          if (item.type) {
            itemClass = this.itemTypes[item.type];
          }
          itemClass = itemClass || this.itemTypes.defaultType;
          return new itemClass(this, item);
      });
  }

  createElement() {
      let toolbar = document.createElement("div");
      toolbar.classList = "st-menubar format";
      toolbar.setAttribute("role", "toolbar");
      toolbar.setAttribute("aria-label", this.label);
      toolbar.setAttribute("aria-controls", this.editorId);

      let inner = document.createElement("div");
      inner.classList = "group characteristics";

      this.items.forEach(item => inner.appendChild(item.domNode));

      toolbar.appendChild(inner);
      return toolbar;
  }

  activateItem(item) {
      item.action();
    }

  update() {return true; }

  destroy() { this.domNode.remove(); }
}


/**
 * Callback that determines if an item should be styled as currently-active
 * @callback activeCallback
 * @param {Object} state
 * @return {boolean} 
 */

 /**
 * Callback that determines if an item should be styled as enabled or not.
 * @callback enabledCallback
 * @param {Object} state
 * @return {boolean} 
 */

/***/ }),

/***/ "./js/ToolbarDropdown.js":
/*!*******************************!*\
  !*** ./js/ToolbarDropdown.js ***!
  \*******************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "ToolbarDropdown": () => (/* binding */ ToolbarDropdown)
/* harmony export */ });
/* harmony import */ var _toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./toolbar-utils.js */ "./js/toolbar-utils.js");


/**
 * A toolbar item with expandable dropdown list to select items from.
 *
 * @export
 * @class ToolbarDropdown
 */
class ToolbarDropdown {
    constructor(toolbar, opts) {
        let { label, action, enable, id, items} = opts;

        this.toolbar = toolbar;
        this.label = label;
        this.action = action;
        this.enable = enable;
        this.id = id || (0,_toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__.stripLabel)(label);
        this.items = items.map((item, i) => {
            let ddItem = new DropdownItem(this, item);
            if (item.default_item) {
                this.default_item = ddItem;
                this.default_i = i;
            }
            return ddItem;
        });


        this.selected = this.default_item;
        this.current = this.default_i;

        this.action = () => {};
        this.last = this.items.length - 1;

        this.btn = new DropdownButton(this);

        this.domNode = this.createElement();

        this.domNode.addEventListener('keydown', e => {
            if (e.key == 'Home' || e.key == 'PageUp') {
                this.current = 0;
                this.items[0].domNode.focus();
                e.stopPropagation();
                e.preventDefault();
            }

            if (e.key == 'End' || e.key == 'PageDown') {
                this.current = this.last;
                this.items[this.last].domNode.focus();
                e.stopPropagation();
                e.preventDefault();
            }

            if (['ArrowRight', 'Right', 'Left', 'ArrowLeft', 'Tab'].includes(e.key)) {
                this.close(true);
            }
        });

        this.domNode.addEventListener("focusout", e => {
            setTimeout(() => { 
           if (!this.domNode.contains(document.activeElement)) {this.close();}
            });
        });

    }

    /**
     * Opens the dropdown list.
     *
     * @memberof ToolbarDropdown
     */
    open() {
        // Set CSS properties
        this.list.style.display = 'block';
        this.list.style.zIndex = 100;

        // Set aria-expanded attribute
        this.btn.domNode.setAttribute('aria-expanded', 'true');
    }

    /**
     * Hides the dropdown list.
     *
     * @memberof ToolbarDropdown
     */
    close() {
            this.list.style.display = 'none';
            this.btn.domNode.removeAttribute('aria-expanded');
      }

    /**
     * Returns whether the dropdown list is currently open.
     *
     * @return {boolean} 
     * @memberof ToolbarDropdown
     */
    isOpen() {
        return this.btn.domNode.getAttribute('aria-expanded') === 'true';
    }

    /**
     * Set focus to the dropdown button.
     *
     * @memberof ToolbarDropdown
     */
    buttonFocus() {
        this.btn.domNode.focus();
    }

    createElement() {
        let dropdown = document.createElement("div");
        dropdown.classList = 'st-dropdown menu-popup group';
        dropdown.setAttribute('tabindex', '-1');

        let list = document.createElement('ul');
        list.setAttribute('role', 'menu');
        list.setAttribute('aria-label', this.label);
        list.setAttribute('id', this.id);
        dropdown.appendChild(this.btn.domNode);

        this.items.forEach(item => {
            list.appendChild(item.domNode);
        });
        this.list = list;
        dropdown.appendChild(list);

        return dropdown;
    }

    /**
     * Returns the dropdown button as the navigable item for this element.
     *
     * @return {Object} 
     * @memberof ToolbarDropdown
     */
    navItem() {
        return this.btn;
    }

    setSelected(item) {
        this.selected = item;
        this.current = this.items.indexOf(item);
        this.items.forEach(item => item.domNode.setAttribute("aria-checked", false));
        this.btn.domNode.setAttribute("aria-label", item.label);
        this.btn.domNode.innerText = item.label;
        let arrow = document.createElement('span');
        arrow.classList = "st-button-arrow";
        this.btn.domNode.appendChild(arrow);
        item.domNode.setAttribute("aria-checked", true);
    }

    activateItem(item) {
        this.setSelected(item);
        this.toolbar.activateItem(item);
        this.buttonFocus();
        this.close(true);
    }

    /**
     * Move focus from current dropdown item to next.
     *
     * @memberof ToolbarDropdown
     */
    setFocusToNext() {
        this.current = this.current === this.last ? 0 : this.current + 1;
        this.items[this.current].domNode.focus();
    }

    /**
     * Move focus from current dropdown to previous.
     *
     * @memberof ToolbarDropdown
     */
    setFocusToPrevious() {
        this.current = this.current === 0 ? this.last : this.current - 1;
        this.items[this.current].domNode.focus();
    }

    getActive(state) {
        let activeSelected = false;
        this.items.forEach(item => {
            let active = item.active(state);
            if (active) {
                this.setSelected(item);
                activeSelected = true;
            }
        });
        if (!activeSelected) {
            this.setSelected(this.default_item);
        }
    }

}

/**
 * The button element that represents the dropdown in the toolbar.
 * Activating it toggles the dropdown open and closed.
 *
 * @class DropdownButton
 */
class DropdownButton {
    /**
     * Creates an instance of DropdownButton.
     * @param {ToolbarDropdown} menu - Parent Dropdown item this button belongs to.
     * @memberof DropdownButton
     */
    constructor(menu) {
        this.menu = menu;
        this.domNode = this.createElement();
        this.active = (state) => {this.menu.getActive(state);};

        this.domNode.addEventListener('click', e => {
            this.menu.toolbar.setFocusItem(this);
            this.menu.isOpen() ? this.menu.close(true) : this.menu.open();
        });

        this.domNode.addEventListener('keydown', e => {
            let keys = [" ", "Spacebar", "Up", "ArrowUp", "Down", "ArrowDown", "Enter"];
            if (keys.includes(e.key)) {
                this.menu.open();
                this.menu.selected.domNode.focus();
                e.stopPropagation();
                e.preventDefault();
            }
        });
    }

    /**
     * Creates DOM element for the dropdown button.
     *
     * @return {Element} 
     * @memberof DropdownButton
     */
    createElement() {
        let btn = document.createElement('button');
        btn.setAttribute('type', 'button')
        btn.setAttribute('aria-haspopup', 'true');
        btn.setAttribute('aria-label', this.menu.selected.label);
        btn.setAttribute('tabindex', '-1');
        btn.classList = "st-item st-dropdown-button";
        let selectedText = document.createTextNode(this.menu.selected.label);
        btn.appendChild(selectedText);
        let arrow = document.createElement('span');
        arrow.classList = "st-button-arrow";
        btn.appendChild(arrow);

        return btn;

    }
}

class DropdownItem {
    constructor(menu, item) {
        let {value, icon, label, action, active, default_item} = item;

        this.menu = menu;
        this.label = label;
        this.value = value || (0,_toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__.stripLabel)(label);
        this.icon = icon || value || (0,_toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__.stripLabel)(label);
        this.action = action;
        this.active = active;

        this.default_item = default_item ? true : false;
        this.domNode = this.createElement();

        this.domNode.addEventListener('click', e => {
            this.menu.activateItem(this);
            this.menu.toolbar.editorView.focus();
        });

        this.domNode.addEventListener('keydown', e => {
            if (e.key == 'Up' || e.key == 'ArrowUp') {
                this.menu.setFocusToPrevious();
                e.stopPropagation();
                e.preventDefault();
            }
            if (e.key == 'Down' | e.key == 'ArrowDown') {
                this.menu.setFocusToNext();
                e.stopPropagation();
                e.preventDefault();
            }

            if (e.key == ' ' || e.key == 'Spacebar' || e.key == 'Enter') {
                this.menu.activateItem(this);
                e.stopPropagation();
                e.preventDefault();
            }
        });


    }

    createElement() {
        let liItem = document.createElement('li');
        liItem.setAttribute('role', 'menuitemradio');
        liItem.setAttribute('aria-checked', this.selected);
        liItem.setAttribute('tabindex', '-1');
        liItem.appendChild(document.createTextNode(this.label));
        liItem.classList = "st-dropdown-item";

        return liItem;
    }
}

/***/ }),

/***/ "./js/ToolbarItem.js":
/*!***************************!*\
  !*** ./js/ToolbarItem.js ***!
  \***************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "ToolbarItem": () => (/* binding */ ToolbarItem),
/* harmony export */   "LinkItem": () => (/* binding */ LinkItem),
/* harmony export */   "SpacerItem": () => (/* binding */ SpacerItem)
/* harmony export */ });
/* harmony import */ var _toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./toolbar-utils.js */ "./js/toolbar-utils.js");


/**
 * A plain button representing a standalone action.
 *
 * @export
 * @class ToolbarItem
 */
class ToolbarItem {
  /**
   * Creates an instance of ToolbarItem.
   * @param {SimpleToolbar} toolbar - Parent toolbar this item belongs to.
   * @param {Object} item - Item configuration.
   * @param {string} item.label - Item label, used for display tooltip.
   * @param {string} item.value - Value of the item button. Defaults to lowercase, 
   *  space-stripped version of label if not set.
   * @param {string} item.icon - Class name for this item's icon. Defaults to value if not set.
   * @param {Function} item.action - Callback function to fire when the item is activated.
   * @param {activeCallback} item.active - Callback function to determine if the item should be styled as active.
   * @param {enabledCallback} item.enabled - Callback function to determine if the item should be styled as enabled.
   * @memberof ToolbarItem
   */
  constructor(toolbar, item) {
    let {value, icon, label, action, active, enabled} = item;
    this.label = label;
    this.value = value || (0,_toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__.stripLabel)(label);
    this.icon = icon || value || (0,_toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__.stripLabel)(label);
    this.toolbar = toolbar;
    this.action = action;

    this.baseActive = active;
    if (enabled) {
      if (typeof(enabled) == "boolean") {
      this.baseEnabled = () => {return enabled;};
      } else {
        this.baseEnabled = enabled;
      }
    } else if (action) {
      this.baseEnabled = action;
    }
    this.active = (state) => {
      if (this.baseActive && this.baseActive(state)) {
        this.setPressed();
      } else {
        this.resetPressed();
      }
    };

    this.enabled = (state) => {
      if (this.baseEnabled && this.baseEnabled(state)) {
        this.enable();
      } else {
        this.disable();
      }
    };

    this.domNode = this.createElement();

    this.domNode.addEventListener('click', e => {
      this.toolbar.setFocusItem(this);
      this.toolbar.activateItem(this);
      this.toolbar.editorView.focus();
    });

    this.domNode.addEventListener('focus', e => {
      this.toolbar.domNode.classList.add('focus');
    });
    this.domNode.addEventListener('blur', e => {
      this.toolbar.domNode.classList.remove('focus');
    });

  }

  /**
   * Returns this item for the list of navigable items.
   *
   * @return {Object} 
   * @memberof ToolbarItem
   */
  navItem() {
    return this;
  }

  /**
   * Returns whether this element has the 'pressed' state.
   *
   * @return {boolean} 
   * @memberof ToolbarItem
   */
  isPressed() {
    return this.domNode.getAttribute('aria-pressed') === 'true';
  }

  /**
   * Sets element 'pressed' state
   *
   * @memberof ToolbarItem
   */
  setPressed() {
    this.domNode.setAttribute('aria-pressed', 'true');
  }

  /**
   * Clears element 'pressed' state
   *
   * @memberof ToolbarItem
   */
  resetPressed() {
    this.domNode.setAttribute('aria-pressed', 'false');
  }

  /**
   * Marks the element as disabled.
   *
   * @memberof ToolbarItem
   */
  disable() {
    this.domNode.setAttribute('aria-disabled', 'true');
    this.domNode.setAttribute('disabled', 'true');
  }

  /**
   * Clears element 'disabled' state.
   *
   * @memberof ToolbarItem
   */
  enable() {
    this.domNode.removeAttribute('aria-disabled');
    this.domNode.removeAttribute('disabled');
  }

  /**
   * Returns the DOM element for this item.
   *
   * @return {Element} 
   * @memberof ToolbarItem
   */
  createElement() {
    let btn = document.createElement('button');
    btn.setAttribute('type', 'button');
    btn.setAttribute('aria-pressed', 'false');
    btn.setAttribute('aria-label', this.label);
    btn.setAttribute('data-balloon-pos', 'up');
    btn.setAttribute('data-balloon-blunt', true);
    btn.setAttribute('value', this.value);
    btn.setAttribute('tabindex', '-1');
    btn.classList = "st-item popup " + this.value;

    let icon = document.createElement('span');
    icon.setAttribute('aria-hidden', 'true');
    icon.classList = this.toolbar.iconClass + this.icon;

    btn.appendChild(icon);

    return btn;
  }

}

class LinkItem {
  constructor(toolbar, link, icon, label) {
    this.toolbar = toolbar;
    this.link = link;
    this.icon = icon;
    this.label = label;
    this.domNode = this.createElement();
  }

  navItem() { return this; }

  createElement() {
    let a = document.createElement('a');
    a.setAttribute('aria-pressed', 'false');
    a.setAttribute('aria-label', this.label);
    a.setAttribute('data-balloon-pos', 'up');
    a.setAttribute('data-balloon-blunt', true);
    a.setAttribute('href', this.link);
    a.setAttribute('tabindex', '-1');
    a.classList = "st-item st-link popup button";

    let icon = document.createElement('span');
    icon.setAttribute('aria-hidden', 'true');
    icon.classList = this.toolbar.iconClass + this.icon;

    a.appendChild(icon);

    return a;
  }
}

class SpacerItem {
  constructor(toolbar, item) {
    let {width, expanding} = item;
    this.toolbar = toolbar;
    this.width = width;
    this.expanding = expanding || false;
    this.domNode = this.createElement();
  }

  navItem() { return []; }

  createElement() {
    let div = document.createElement('div');
    div.classList = "st-spacer";
    div.style.display = "inline-block";
    if (this.width) {
      div.style.width = this.width;
    }
    if (this.expanding) {
      div.style.flexGrow = 1;
    }
    return div;
  }
}

/***/ }),

/***/ "./js/ToolbarItemGroup.js":
/*!********************************!*\
  !*** ./js/ToolbarItemGroup.js ***!
  \********************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "ToolbarGroup": () => (/* binding */ ToolbarGroup)
/* harmony export */ });
/* harmony import */ var _ToolbarItem_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./ToolbarItem.js */ "./js/ToolbarItem.js");


/**
 * ToolbarGroups represent a group of mutually exclusive actions - that is, the results of any action
 * will override the results of any of the other actions in the group.
 *
 * @export
 * @class ToolbarGroup
 */
class ToolbarGroup {
    /**
     * Creates an instance of ToolbarGroup.
     * @param {SimpleToolbar} toolbar - Parent toolbar instance
     * @param {Object} opts - Configuration options
     * @param {string} opts.label - Label that describes the entire group, used by screenreaders
     * @param {Object[]} opts.items - Array of configuration options.
     * @memberof ToolbarGroup
     */
    constructor(toolbar, opts) {
      let {label, items} = opts;
      this.toolbar = toolbar;
      this.label = label;
      this.items = items.map(item => {
        return new ToolbarGroupItem(toolbar, this, item);
      });
  
      this.current = 0;
      this.last = this.items.length - 1;
  
      this.domNode = this.createElement();
  
      this.domNode.addEventListener('focus', e => {
        this.items.forEach((item, i) => {
          if (item.domNode.getAttribute('tabindex').value == 0) {
            this.current = i;
          }
        });
      });
  
      // Up and down arrow keys cycle through items within this group.
      this.domNode.addEventListener('keydown', e => {
  
        if (e.key == 'Down' || e.key == 'ArrowDown') {
          this.current = this.current === this.last ? 0 : this.current + 1;
          let newItem = this.items[this.current];
          this.toolbar.setFocusItem(newItem);
  
          e.stopPropagation();
          e.preventDefault();
        } else if (e.key == 'Up' || e.key == 'ArrowUp') {
          this.current = this.current === 0 ? this.last : this.current - 1;
          let newItem = this.items[this.current];
          this.toolbar.setFocusItem(newItem);
  
          e.stopPropagation();
          e.preventDefault();
        }
      });
  
    }
  
    /**
     * Returns the items that should be keyboard-navigable.
     *
     * @return {Object} 
     * @memberof ToolbarGroup
     */
    navItem() {
      return this.items;
    }
  
    /**
     * Returns the DOM element for this group, including all child items.
     *
     * @return {Element} 
     * @memberof ToolbarGroup
     */
    createElement() {
      let group = document.createElement('div');
      group.className = 'group';
      group.setAttribute('role', 'radiogroup');
      group.setAttribute('aria-label', this.label);
      group.classList = 'st-button-group';
  
      this.items.forEach(item => {
        group.appendChild(item.domNode);
      });
      return group;
    }
  
    /**
     * Clears the 'checked' state on every item in the group.
     *
     * @memberof ToolbarGroup
     */
    resetChecked() {
      this.items.forEach(item => item.resetChecked());
    }
  
  }
  
/**
 * Subclass of ToolbarItem that implements the 'radio' role and
 * functions for manipulating the state of it's 'checked' attribute.
 *
 * @class ToolbarGroupItem
 * @extends {ToolbarItem}
 */
class ToolbarGroupItem extends _ToolbarItem_js__WEBPACK_IMPORTED_MODULE_0__.ToolbarItem {
  
    /**
     * Creates an instance of ToolbarGroupItem.
     * @param {SimpleToolbar} toolbar - Parent toolbar this item and it's group belong to.
     * @param {ToolbarGroup} group - Parent ToolbarGroup this item belongs to.
     * @param {Object} item - Item configuration object.
     * 
     * @memberof ToolbarGroupItem
     */
    constructor(toolbar, group, item) {
      let {action} = item;
      super(toolbar, item);
  
      this.group = group;
      this.baseAction = action;

      // Wrap action to handle radio toggle within the group.
      this.action = (...args) => {
        this.group.resetChecked();
        this.setChecked();
        this.baseAction(...args);
      };

      this.active = (state) => {
        if (this.baseActive && this.baseActive(state)) {
          this.setChecked();
        } else {
          this.resetChecked();
        }
      };
  
    }
  
    /**
     * Creates and returns the DOM element for a ToolbarGroupItem
     *
     * @return {Element} 
     * @memberof ToolbarGroupItem
     */
    createElement() {
      let btn = super.createElement();
      document.createElement('button');
      btn.setAttribute('type', 'button');
      btn.setAttribute('role', 'radio');
      btn.setAttribute('aria-checked', 'false');
  
      return btn;
    }
  
    /**
     * Toggle the item to 'checked' state
     *
     * @memberof ToolbarGroupItem
     */
    setChecked() {
      this.domNode.setAttribute('aria-checked', 'true');
      this.domNode.checked = true;
  
    }
  
    /**
     * Clear item 'checked' state.
     *
     * @memberof ToolbarGroupItem
     */
    resetChecked() {
      this.domNode.setAttribute('aria-checked', 'false');
      this.domNode.checked = false;
    }
  
  }

/***/ }),

/***/ "./js/ToolbarMenu.js":
/*!***************************!*\
  !*** ./js/ToolbarMenu.js ***!
  \***************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "ToolbarMenu": () => (/* binding */ ToolbarMenu)
/* harmony export */ });
/* harmony import */ var _toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./toolbar-utils.js */ "./js/toolbar-utils.js");


/**
 * A toolbar item with expandable dropdown of unrelated actions to select from
 * (for related actions, see {ToolbarDropdown})
 *
 * @export
 * @class ToolbarDropdown
 */
class ToolbarMenu {
    constructor(toolbar, opts) {
        this.toolbar = toolbar;
        let { label, id, items} = opts;
        this.label = label;
        this.id = id || (0,_toolbar_utils_js__WEBPACK_IMPORTED_MODULE_0__.stripLabel)(label);
        this.current = 0;
        this.items = items.map((item) => { return new DropdownItem(this, item);});
        this.action = () => {};
        this.last = this.items.length - 1;

        this.btn = new DropdownButton(this);

        this.domNode = this.createElement();

        this.domNode.addEventListener('keydown', e => {
            if (e.key == 'Home' || e.key == 'PageUp') {
                this.current = 0;
                this.items[0].domNode.focus();
                e.stopPropagation();
                e.preventDefault();
            }

            if (e.key == 'End' || e.key == 'PageDown') {
                this.current = this.last;
                this.items[this.last].domNode.focus();
                e.stopPropagation();
                e.preventDefault();
            }

            if (['ArrowRight', 'Right', 'Left', 'ArrowLeft', 'Tab'].includes(e.key)) {
                this.close(true);
            }
        });
        
        this.domNode.addEventListener("focusout", e => {
            setTimeout(() => { 
           if (!this.domNode.contains(document.activeElement)) {this.close();}
            });
        });

        this.domNode.addEventListener("blur", e => {
            this.close();
        });

    }

    /**
     * Opens the dropdown list.
     *
     * @memberof ToolbarDropdown
     */
    open() {
        // Set CSS properties
        this.list.style.display = 'block';
        this.list.style.zIndex = 100;

        // Set aria-expanded attribute
        this.btn.domNode.setAttribute('aria-expanded', 'true');
    }

    /**
     * Hides the dropdown list.
     *
     * @memberof ToolbarDropdown
     */
    close() {
        this.list.style.display = 'none';
        this.btn.domNode.removeAttribute('aria-expanded');
    }

    /**
     * Returns whether the dropdown list is currently open.
     *
     * @return {boolean} 
     * @memberof ToolbarDropdown
     */
    isOpen() {
        return this.btn.domNode.getAttribute('aria-expanded') === 'true';
    }

    /**
     * Set focus to the dropdown button.
     *
     * @memberof ToolbarDropdown
     */
    buttonFocus() {
        this.btn.domNode.focus();
    }

    createElement() {
        let dropdown = document.createElement("div");
        dropdown.classList = 'st-menu menu-popup group';
        dropdown.setAttribute('tabindex', '-1');

        let list = document.createElement('ul');
        list.setAttribute('role', 'menu');
        list.setAttribute('aria-label', this.label);
        list.setAttribute('id', this.id);
        dropdown.appendChild(this.btn.domNode);

        this.items.forEach(item => {
            list.appendChild(item.domNode);
        });
        this.list = list;
        dropdown.appendChild(list);

        return dropdown;
    }

    /**
     * Returns the dropdown button as the navigable item for this element.
     *
     * @return {Object} 
     * @memberof ToolbarDropdown
     */
    navItem() {
        return this.btn;
    }

    setSelected(item) {
        this.toolbar.activateItem(item);
        this.buttonFocus();
        this.close(true);
    }

    /**
     * Move focus from current dropdown item to next.
     *
     * @memberof ToolbarDropdown
     */
    setFocusToNext() {
        this.current = this.current === this.last ? 0 : this.current + 1;
        this.items[this.current].domNode.focus();
    }

    /**
     * Move focus from current dropdown to previous.
     *
     * @memberof ToolbarDropdown
     */
    setFocusToPrevious() {
        this.current = this.current === 0 ? this.last : this.current - 1;
        this.items[this.current].domNode.focus();
    }

}

/**
 * The button element that represents the dropdown in the toolbar.
 * Activating it toggles the dropdown open and closed.
 *
 * @class DropdownButton
 */
class DropdownButton {
    /**
     * Creates an instance of DropdownButton.
     * @param {ToolbarDropdown} menu - Parent Dropdown item this button belongs to.
     * @memberof DropdownButton
     */
    constructor(menu) {
        this.menu = menu;
        this.domNode = this.createElement();


        this.domNode.addEventListener('click', e => {
            this.menu.toolbar.setFocusItem(this);
            this.menu.isOpen() ? this.menu.close(true) : this.menu.open();
        });

        this.domNode.addEventListener('keydown', e => {
            let keys = [" ", "Spacebar", "Up", "ArrowUp", "Down", "ArrowDown", "Enter"];
            if (keys.includes(e.key)) {
                this.menu.open();
                this.menu.items[0].domNode.focus();
                e.stopPropagation();
                e.preventDefault();
            }
        });

    }

    /**
     * Creates DOM element for the dropdown button.
     *
     * @return {Element} 
     * @memberof DropdownButton
     */
    createElement() {
        let btn = document.createElement('button');
        btn.setAttribute('type', 'button')
        btn.setAttribute('aria-haspopup', 'true');
        btn.setAttribute('aria-label', this.menu.label);
        btn.setAttribute('tabindex', '-1');
        btn.classList = "st-item st-menu-button";
        let selectedText = document.createTextNode(this.menu.label);
        btn.appendChild(selectedText);
        let arrow = document.createElement('span');
        arrow.classList = "st-button-arrow";
        btn.appendChild(arrow);

        return btn;

    }
}

class DropdownItem {
    constructor(menu, item) {
        let {label, action, enable} = item;

        this.menu = menu;
        this.action = action;
        this.enable = enable;
        this.label = label;
        this.domNode = this.createElement();

        this.domNode.addEventListener('click', e => {
            this.menu.setSelected(this);
        });

        this.domNode.addEventListener('keydown', e => {
            if (e.key == 'Up' || e.key == 'ArrowUp') {
                this.menu.setFocusToPrevious();
                e.stopPropagation();
                e.preventDefault();
            }
            if (e.key == 'Down' | e.key == 'ArrowDown') {
                this.menu.setFocusToNext();
                e.stopPropagation();
                e.preventDefault();
            }

            if (e.key == ' ' || e.key == 'Spacebar' || e.key == 'Enter') {
                this.menu.setSelected(this);
                e.stopPropagation();
                e.preventDefault();
            }
        });


    }

    createElement() {
        let liItem = document.createElement('li');
        liItem.setAttribute('role', 'menuitem');
        liItem.setAttribute('aria-pressed', false);
        liItem.setAttribute('tabindex', '-1');
        liItem.appendChild(document.createTextNode(this.label));
        liItem.classList = "st-menu-item";

        return liItem;
    }
}

/***/ }),

/***/ "./js/toolbar-utils.js":
/*!*****************************!*\
  !*** ./js/toolbar-utils.js ***!
  \*****************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony export */ __webpack_require__.d(__webpack_exports__, {
/* harmony export */   "stripLabel": () => (/* binding */ stripLabel)
/* harmony export */ });
/**
 * Takes a human-readable label and returns it lowercased, with spaces replaced
 * by "-", for use in HTML attributes.
 *
 * @export
 * @param {String} label
 * @return {String} 
 */
function stripLabel(label) {
    return label.toLowerCase().replaceAll(/ /g, "-");
}

/***/ }),

/***/ "./plain.js":
/*!******************!*\
  !*** ./plain.js ***!
  \******************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
/* harmony import */ var _js_SimpleToolbar__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./js/SimpleToolbar */ "./js/SimpleToolbar.js");


function wrappingItem(tag, label, icon) {
    const value = label.toLowerCase().replace(/ /, "-");
    const finalIcon = icon || value;

    return {
        icon: finalIcon,
        value: value,
        label: label,
        action: insertAround(`<${tag}>`, `</${tag}>`),
        active: false,
        enabled: true
    };
}

const TextArea = document.querySelector("textarea[name=event]");
const imageButton = document.getElementById("image-upload");

function insertImage(){
    imageButton.click()
}

function insertAround(startText, endText) {
    return function() {
    let [start, end] = [TextArea.selectionStart, TextArea.selectionEnd];
    TextArea.setRangeText(startText, start, start, 'preserve');
    end = end + startText.length;
    TextArea.setRangeText(endText, end, end, 'preserve');
    TextArea.setSelectionRange(start + startText.length, end);
    };
}

let items = [
    wrappingItem("b", "Bold"),
    wrappingItem("i", "Italic"),
    wrappingItem("u", "Underline"),
    wrappingItem("s", "Strikethrough"),
    wrappingItem("pre", "Code", "terminal"),
    {action: insertAround("<ul><li>", "</li></ul>"), label: 'Bullet List', icon: 'list-ul', value: 'bullet-list', enabled: true},
    wrappingItem("blockquote", 'Blockquote', 'quote-left'),
    {action: insertImage, label: 'Insert image', icon: 'image', value: 'image', enabled: true},
    {action: insertAround('<a href="">', "</a>"), label: 'Insert link', icon: 'link', value: 'link', enabled: true},
    {action: insertAround('<user name="', '">'), label: 'Insert user', icon: 'user', value: 'user', enabled: true },
    {action: insertAround('<cut text="Read more">', "</cut>"), label: 'Insert cut', icon: 'cut', value: 'cut', enabled: true },
    {type: 'dropdown', label: 'heading', id: 'heading', items: [
      {...wrappingItem("h1", 'Heading 1', 'heading'), default_item: true},
      wrappingItem("h2", 'Heading 2', 'heading'),
      wrappingItem("h3", 'Heading 3', 'heading'),
      wrappingItem("h4", 'Heading 4', 'heading'),
      wrappingItem("h5", 'Heading 5', 'heading'),
      wrappingItem("h6", 'Heading 6', 'heading'),
    ]}];


var plainToolbar = null;
var mdToolbar = null;

function setupPlain() {
    plainToolbar = new _js_SimpleToolbar__WEBPACK_IMPORTED_MODULE_0__.SimpleToolbar(items, "toolbar", "entry-body");
    TextArea.parentNode.insertBefore(plainToolbar.domNode, TextArea);
}


// Set up RTE on load if it's set as default format
if (document.querySelector('#editor').value.includes("html")) {
    setupPlain();
  }
  
  // Watch the format select for changes, and add or destroy the RTE as necessary
  document.querySelector('#editor').addEventListener('change', e => {
    let format = e.target.value;
    if (format.includes("html") && !plainToolbar) {
      setupPlain();
    }
    if (!format.includes("html") && plainToolbar) {
      plainToolbar.destroy();
      plainToolbar = null;
    }
  })


/***/ }),

/***/ "./sass/menu-button.scss":
/*!*******************************!*\
  !*** ./sass/menu-button.scss ***!
  \*******************************/
/***/ ((__unused_webpack_module, __webpack_exports__, __webpack_require__) => {

__webpack_require__.r(__webpack_exports__);
// extracted by mini-css-extract-plugin


/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		if(__webpack_module_cache__[moduleId]) {
/******/ 			return __webpack_module_cache__[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/define property getters */
/******/ 	(() => {
/******/ 		// define getter functions for harmony exports
/******/ 		__webpack_require__.d = (exports, definition) => {
/******/ 			for(var key in definition) {
/******/ 				if(__webpack_require__.o(definition, key) && !__webpack_require__.o(exports, key)) {
/******/ 					Object.defineProperty(exports, key, { enumerable: true, get: definition[key] });
/******/ 				}
/******/ 			}
/******/ 		};
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/hasOwnProperty shorthand */
/******/ 	(() => {
/******/ 		__webpack_require__.o = (obj, prop) => (Object.prototype.hasOwnProperty.call(obj, prop))
/******/ 	})();
/******/ 	
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	(() => {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = (exports) => {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	})();
/******/ 	
/************************************************************************/
/******/ 	// startup
/******/ 	// Load entry module
/******/ 	__webpack_require__("./plain.js");
/******/ 	// This entry module used 'exports' so it can't be inlined
/******/ 	__webpack_require__("./sass/menu-button.scss");
/******/ })()
;
//# sourceMappingURL=plain.bundle.js.map