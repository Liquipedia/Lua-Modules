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

return mw
