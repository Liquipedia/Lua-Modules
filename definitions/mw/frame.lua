-- luacheck: ignore
---@meta mw.frame

---@class Frame
---@field args table
frame = {}

---Call a parser function, returning an appropriate string. This is preferable to frame:preprocess, but whenever possible, native Lua functions or Scribunto library functions should be preferred to this interface.
---@param name string
---@param args table|string
---@return string
---@overload fun(self, params: {name: string, args: table|string}): string
---@overload fun(self, name: string, ...: string): string
function frame:callParserFunction(name, args) end

---This is transclusion. As in transclusion, if the passed title does not contain a namespace prefix it will be assumed to be in the Template: namespace.
---@param params {title: string, args: table}
---@return string
function frame:callParserFunction(params) end

---This is equivalent to a call to frame:callParserFunction() with function name '#tag:' .. name and with content prepended to args.
---@param name string
---@param content string
---@param args table|string
---@return string
---@overload fun(self, params: {name: string, content: string, args: table|string}): string
function frame:callParserFunction(name, content, args) end

---Called on the frame created by {{#invoke:}}, returns the frame for the page that called {{#invoke:}}. Called on that frame, returns nil.
---@return Frame
function frame:getParent() end

---Returns the title associated with the frame as a string. For the frame created by {{#invoke:}}, this is the title of the module invoked.
---@return string
function frame:getTitle() end

---Returns the title associated with the frame as a string. For the frame created by {{#invoke:}}, this is the title of the module invoked.
---@param params {title: string, args: table}
---@return string
function frame:newChild(params) end

---This expands wikitext in the context of the frame, i.e. templates, parser functions, and parameters such as {{{1}}} are expanded.
---Not recommended. Use frame:expandTemplate or frame:callParserFunction depending on usecase.
---@param params {text: string}
---@return string
---@overload fun(self, text: string): string
function frame:preprocess(params) end

---Gets an object for the specified argument, or nil if the argument is not provided.
---The returned object has one method, object:expand(), that returns the expanded wikitext for the argument.
---@param params {arg: string}
---@return {expand: fun(self):string}
---@overload fun(self, arg: string): {expand: fun(self):string}
function frame:getArgument(params) end

---Returns an object with one method, object:expand(), that returns the result of frame:preprocess( text ).
---@param params {text: string}
---@return {expand: fun(self):string}
---@overload fun(self, text: string): {expand: fun(self):string}
function frame:newParserValue(params) end

---Returns an object with one method, object:expand(), that returns the result of frame:expandTemplate called with the given arguments.
---@param params {title: string, args: table}
---@return {expand: fun(self):string}
function frame:newTemplateParserValue(params) end

return frame
