-- luacheck: ignore
---@meta mw
mw = {}

---Adds a warning which is displayed above the preview when previewing an edit. `text` is parsed as wikitext.
---@param text string
function mw.addWarning(text) end

---Calls tostring() on all arguments, then concatenates them with tabs as separators.
---@param ... any
---@return string
---@nodiscard
function mw.allToString(...) end

---Creates a deep copy of a value. All tables (and their metatables) are reconstructed from scratch. Functions are still shared, however.
---@generic T
---@param value T
---@return T
---@nodiscard
function mw.clone(value) end

---Returns the current frame object, typically the frame object from the most recent #invoke. 
---@return Frame
---@nodiscard
function mw.getCurrentFrame() end

---Adds one to the "expensive parser function" count, and throws an exception if it exceeds the limit (see $wgExpensiveParserFunctionLimit).
function mw.incrementExpensiveFunctionCount() end

---Returns true if the current #invoke is being substed, false otherwise. See Returning text above for discussion on differences when substing versus not substing.
---@return boolean
function mw.isSubsting() end

---See www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual#mw.loadData
---@param module string
---@return table
function mw.loadData(module) end

---This is the same as mw.loadData(), except it loads data from JSON pages rather than Lua tables. The JSON content must be an array or object. See also mw.text.jsonDecode().
---@param page string
---@return table
function mw.loadData(page) end

---Serializes object to a human-readable representation, then returns the resulting string.
---@param object any
---@return string
function mw.dumpObject(object) end

---Passes the arguments to mw.allToString(), then appends the resulting string to the log buffer.
---@param ... any
function mw.log(...) end

---Calls mw.dumpObject() and appends the resulting string to the log buffer. If prefix is given, it will be added to the log buffer followedby an equals sign before the serialized string is appended (i.e. the logged text will be "prefix = object-string").
---@param object any
---@param prefix any?
function mw.logObject(object, prefix) end

---@class Frame
---@field args table
mw.frame = {}

---Call a parser function, returning an appropriate string. This is preferable to frame:preprocess, but whenever possible, native Lua functions or Scribunto library functions should be preferred to this interface.
---@param name string
---@param args table|string
---@return string
---@overload fun(self, params: {name: string, args: table|string}): string
---@overload fun(self, name: string, ...: string): string
function mw.frame:callParserFunction(name, args) end

---This is transclusion. As in transclusion, if the passed title does not contain a namespace prefix it will be assumed to be in the Template: namespace.
---@param params {title: string, args: table}
---@return string
function mw.frame:expandTemplate(params) end

---This is equivalent to a call to frame:callParserFunction() with function name '#tag:' .. name and with content prepended to args.
---@param name string
---@param content string
---@param args table|string
---@return string
---@overload fun(self, params: {name: string, content: string, args: table|string}): string
function mw.frame:extensionTag(name, content, args) end

---Called on the frame created by {{#invoke:}}, returns the frame for the page that called {{#invoke:}}. Called on that frame, returns nil.
---@return Frame
function mw.frame:getParent() end

---Returns the title associated with the frame as a string. For the frame created by {{#invoke:}}, this is the title of the module invoked.
---@return string
function mw.frame:getTitle() end

---Returns the title associated with the frame as a string. For the frame created by {{#invoke:}}, this is the title of the module invoked.
---@param params {title: string, args: table}
---@return string
function mw.frame:newChild(params) end

---This expands wikitext in the context of the frame, i.e. templates, parser functions, and parameters such as {{{1}}} are expanded.
---Not recommended. Use frame:expandTemplate or frame:callParserFunction depending on usecase.
---@param params {text: string}
---@return string
---@overload fun(self, text: string): string
function mw.frame:preprocess(params) end

---Gets an object for the specified argument, or nil if the argument is not provided.
---The returned object has one method, object:expand(), that returns the expanded wikitext for the argument.
---@param params {arg: string}
---@return {expand: fun(self):string}
---@overload fun(self, arg: string): {expand: fun(self):string}
function mw.frame:getArgument(params) end

---Returns an object with one method, object:expand(), that returns the result of frame:preprocess( text ).
---@param params {text: string}
---@return {expand: fun(self):string}
---@overload fun(self, text: string): {expand: fun(self):string}
function mw.frame:newParserValue(params) end

---Returns an object with one method, object:expand(), that returns the result of frame:expandTemplate called with the given arguments.
---@param params {title: string, args: table}
---@return {expand: fun(self):string}
function mw.frame:newTemplateParserValue(params) end

mw.hash = {}

---Hashes a string value with the specified algorithm. Valid algorithms may be fetched using mw.hash.listAlgorithms().
---@param algo string
---@param value any
---@return string
function mw.hash.hashValue(algo, value) end

---Hashes a string value with the specified algorithm. Valid algorithms may be fetched using mw.hash.listAlgorithms().
---@return string[]
function mw.hash.listAlgorithms() end

---@class Html
mw.html = {}

---Creates a new mw.html object containing a tagName html element. You can also pass an empty string or nil as tagName in order to create an empty mw.html object.
---@param tagName? string
---@param args? {selfClosing: boolean, parent: Html}
---@return Html
function mw.html.create(tagName, args) end

---Appends a child mw.html (builder) node to the current mw.html instance. If a nil parameter is passed, this is a no-op. A (builder) node is a string representation of an html element.
---@param builder? Html|string
---@return self
function mw.html:node(builder) end

---Appends an undetermined number of wikitext strings to the mw.html object. Note that this stops at the first nil item.
---@param ... string?
---@return self
function mw.html:wikitext(...) end

---Appends a newline to the mw.html object. 
---@return self
function mw.html:newline() end

---Appends a new child node with the given tagName to the builder, and returns a mw.html instance representing that new node. The args parameter is identical to that of mw.html.create
---Note that contrarily to other methods such as html:node(), this method doesn't return the current mw.html instance, but the mw.html instance of the newly inserted tag. Make sure to use html:done() to go up to the parent mw.html instance, or html:allDone() if you have nested tags on several levels.
---@param tagName string
---@param args? {selfClosing: boolean, parent: Html}
---@return Html
function mw.html:tag(tagName, args) end

---Set an HTML attribute with the given name and value on the node. Alternatively a table holding name->value pairs of attributes to set can be passed. In the first form, a value of nil causes any attribute with the given name to be unset if it was previously set.
---@param name string
---@param value string
---@return self
---@overload fun(self, param: {[string]: string})
function mw.html:attr(name, value) end

---Get the value of a html attribute previously set using html:attr() with the given name.
---@param name string
---@return string
function mw.html:getAttr(name) end

---Adds a class name to the node's class attribute. If a nil parameter is passed, this is a no-op.
---@param class string?
---@return self
function mw.html:addClass(class) end

---Set a CSS property with the given name and value on the node. Alternatively a table holding name->value pairs of attributes to set can be passed. In the first form, a value of nil causes any attribute with the given name to be unset if it was previously set.
---@param name string
---@param value string
---@return self
---@overload fun(self, param: {[string]: string})
function mw.html:css(name, value) end

---Add some raw css to the node's style attribute. If a nil parameter is passed, this is a no-op.
---@param css string?
---@return self
function mw.html:cssText(css) end

---Returns the parent node under which the current node was created.
---@return Html
function mw.html:done() end

---Like html:done(), but traverses all the way to the root node of the tree and returns it.
---@return Html
function mw.html:allDone() end


return mw
