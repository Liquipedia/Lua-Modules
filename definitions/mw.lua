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

---@class Language
mw.language = {}

---The full name of the language for the given language code: native name (language autonym) by default, name translated in target language if a value is given for inLanguage.
---@param code string
---@param inLanguage? string
---@return string
function mw.language.fetchLanguageName(code, inLanguage) end

---Fetch the list of languages known to MediaWiki, returning a table mapping language code to language name.
---@param inLanguage? string
---@param include? 'all'|'mwfile'|'mw'
---@return table
function mw.language.fetchLanguageNames(inLanguage, include) end

---Returns a new language object for the wiki's default content language.
---@return Language
function mw.language.getContentLanguage() end
mw.getContentLanguage = mw.language.getContentLanguage

---Returns a list of MediaWiki's fallback language codes for the specified code.
---@param code string
---@return string[]
function mw.language.getFallbacksFor(code) end

---Returns true if a language code is known to MediaWiki.
---@param code string
---@return boolean
function mw.language.isKnownLanguageTag(code) end

---Checks whether any localisation is available for that language code in MediaWiki.
---@param code string
---@return boolean
function mw.language.isSupportedLanguage(code) end

---Returns true if a language code is of a valid form for the purposes of internal customisation of MediaWiki.
---@param code string
---@return boolean
function mw.language.isValidBuiltInCode(code) end

---Returns true if a language code string is of a valid form, whether or not it exists. This includes codes which are used solely for customisation via the MediaWiki namespace.
---@param code string
---@return boolean
function mw.language.isValidCode(code) end

---Creates a new language object. Language objects do not have any publicly accessible properties, but they do have several methods, which are documented below.
---@param code string
---@return Language
function mw.language.new(code) end
mw.getLanguage = mw.language.new

---Returns the language code for this language object.
---@return string
function mw.language:getCode() end

---Returns a list of MediaWiki's fallback language codes for this language object. Equivalent to mw.language.getFallbacksFor( lang:getCode() ).
---@return string[]
function mw.language:getFallbackLanguages() end

---Returns true if the language is written right-to-left, false if it is written left-to-right.
---@return boolean
function mw.language:isRTL() end

---Converts the string to lowercase, honoring any special rules for the given language.
---@param str string
---@return string
function mw.language:lc(str) end

---Converts the first character of the string to lowercase.
---@param str string
---@return string
function mw.language:lcfirst(str) end

---Converts the string to uppercase, honoring any special rules for the given language.
---@param str string
---@return string
function mw.language:uc(str) end

---Converts the first character of the string to uppercase.
---@param str string
---@return string
function mw.language:ucfirst(str) end

---Converts the string to a representation appropriate for case-insensitive comparison. Note that the result may not make any sense when displayed.
---@param str string
---@return string
function mw.language:caseFold(str) end

---Formats a number with grouping and decimal separators appropriate for the given language. Given 123456.78, this may produce "123,456.78", "123.456,78", or even something like "١٢٣٬٤٥٦٫٧٨" depending on the language and wiki configuration.
---@param num number
---@param options? {noCommafy: boolean}
---@return number
function mw.language:formatNum(num, options) end

---Formats a date according to the given format string. If timestamp is omitted, the default is the current time. The value for local must be a boolean or nil; if true, the time is formatted in the wiki's local time rather than in UTC.
---@param format string
---@param timestamp string?
---@param localTime boolean?
---@return number
function mw.language:formatDate(format, timestamp, localTime) end

---Breaks a duration in seconds into more human-readable units, e.g. 12345 to 3 hours, 25 minutes and 45 seconds, returning the result as a string.
---@param seconds number
---@param chosenIntervals table
---@return string
function mw.language:formatDuration(seconds, chosenIntervals) end

---This takes a number as formatted by lang:formatNum() and returns the actual number. In other words, this is basically a language-aware version of tonumber().
---@param str string
---@return string
function mw.language:parseFormattedNumber(str) end

---This chooses the appropriate grammatical form from forms (which must be a sequence table) or ... based on the number n.
---@param n number
---@param ... string
---@return string
---@overload fun(n: number, forms: table):string
function mw.language:convertPlural(n, ...) end
mw.language.plural = mw.language.convertPlural

---This chooses the appropriate inflected form of word for the given inflection code case.
---@param word string
---@param case string
---@return string
function mw.language:convertGrammar(word, case) end

---This chooses the appropriate inflected form of word for the given inflection code case.
---@param case string
---@param word string
---@return string
function mw.language:gammer(case, word) end

---Returns a Unicode arrow character corresponding to direction:
---@param direction 'forwards'|'backwards'|'left'|'right'|'up'|'down'
---@return '→'|'←'|'↑'|'↓'
function mw.language:getArrow(direction) end

---Returns "ltr" or "rtl", depending on the directionality of the language.
---@return 'ltr'|'rtl'
function mw.language:getDir() end

---@class Message
mw.message = {}

---Creates a new message object for the given message key. The remaining parameters are passed to the new object's params() method.
---@param key string
---@param ... any
---@return Message
function mw.message.new(key, ...) end

---Creates a new message object for the given messages (the first one that exists will be used).
---@param ... string
---@return Message
function mw.message.newFallbackSequence(...) end

---Creates a new message object, using the given text directly rather than looking up an internationalized message.
---@param msg string
---@param ... string
---@return Message
function mw.message.newRawMessage(msg, ...) end

---Wraps the value so that it will not be parsed as wikitext by msg:parse().
---@param value string
---@return string
function mw.message.rawParam(value) end

---Wraps the value so that it will automatically be formatted as by lang:formatNum(). Note this does not depend on the Language library actually being available.
---@param value string
---@return string
function mw.message.numParam(value) end

---Returns a Language object for the default language.
---@return Language
function mw.message.getDefaultLanguage() end

---Add parameters to the message, which may be passed as individual arguments or as a sequence table. Parameters must be numbers, strings, or the special values returned by mw.message.numParam() or mw.message.rawParam(). If a sequence table is used, parameters must be directly present in the table; references using the __index metamethod will not work.
---@param ... string|number
---@return self
---@overload fun(self, params: table):self
function mw.message:params(...) end

---Like :params(), but has the effect of passing all the parameters through mw.message.rawParam() first.
---@param ... string
---@return self
---@overload fun(self, params: table):self
function mw.message:rawParams(...) end

---Like :params(), but has the effect of passing all the parameters through mw.message.numParam() first.
---@param ... number
---@return self
---@overload fun(self, params: table):self
function mw.message:numParams(...) end

---Specifies the language to use when processing the message. lang may be a string or a table with a getCode() method (i.e. a Language object).
---@param lang string
---@return self
function mw.message:inLanguage(lang) end

---Specifies whether to look up messages in the MediaWiki: namespace (i.e. look in the database), or just use the default messages distributed with MediaWiki.
---@param bool boolean
---@return self
function mw.message:useDatabase(bool) end

---Substitutes the parameters and returns the message wikitext as-is. Template calls and parser functions are intact.
---@return string
function mw.message:plain() end

---Returns a boolean indicating whether the message key exists.
---@return boolean
function mw.message:exists() end

---Returns a boolean indicating whether the message key has content. Returns true if the message key does not exist or the message is the empty string.
---@return boolean
function mw.message:isBlank() end

---Returns a boolean indicating whether the message key is disabled. Returns true if the message key does not exist or if the message is the empty string or the string "-".
---@return boolean
function mw.message:isDisabled() end

return mw
