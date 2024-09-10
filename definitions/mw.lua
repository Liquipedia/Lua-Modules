---@meta mw
-- luacheck: ignore
---This file contains definitions and simulations of the MediaWiki enviroment
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

---Adds one to the "expensive parser function" count, and throws an exception if it exceeds the limit (see $wgExpensiveParserFunctionLimit).
function mw.incrementExpensiveFunctionCount() end

---Returns true if the current #invoke is being `substed`, false otherwise.
---@return boolean
function mw.isSubsting() end

---See www.mediawiki.org/wiki/Extension:Scribunto/Lua_reference_manual#mw.loadData
---@param module string
---@return table
function mw.loadData(module)
	--TODO: add __index that errors
	return require(module)
end

---This is the same as mw.loadData(), except it loads data from JSON pages rather than Lua tables. The JSON content must be an array or object. See also mw.text.jsonDecode().
---@param page string
---@return table
function mw.loadJsonData(page) end

---Serializes object to a human-readable representation, then returns the resulting string.
---@param object any
---@return string
function mw.dumpObject(object) end

---Passes the arguments to mw.allToString(), then appends the resulting string to the log buffer.
---@param ... any
function mw.log(...) end

---Calls mw.dumpObject() and appends the resulting string to the log buffer. If prefix is given, it will be added to the log buffer followed by an equals sign before the serialized string is appended (i.e. the logged text will be "prefix = object-string").
---@param object any
---@param prefix any?
function mw.logObject(object, prefix) end

---@class Frame
---@field args table?
mw.frame = {}

---Returns the current frame object, typically the frame object from the most recent #invoke.
---@return Frame
---@nodiscard
function mw.getCurrentFrame()
	return setmetatable(mw.frame, {})
end

---Call a parser function, returning an appropriate string. This is preferable to frame:preprocess, but whenever possible, native Lua functions or Scribunto library functions should be preferred to this interface.
---@param name string
---@param args table|string
---@return string
---@overload fun(self, params: {name: string, args: table|string}): string
---@overload fun(self, name: string, ...: string): string
function mw.frame:callParserFunction(name, args) end

---This is transclusion. As in transclusion, if the passed title does not contain a namespace prefix it will be assumed to be in the Template: namespace.
---@param params {title: string, args: table?}
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
function mw.frame:getTitle() return '' end

---Create a new Frame object that is a child of the current frame, with optional arguments and title.
--This is mainly intended for use in the debug console for testing functions that would normally be called by {{#invoke:}}. The number of frames that may be created at any one time is limited.
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

---Returns a list of supported hashing algorithms, for use in mw.hash.hashValue().
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
---@param builder? Html|string|number
---@return self
function mw.html:node(builder) end

---Appends an undetermined number of wikitext strings to the mw.html object. Note that this stops at the first nil item.
---@param ... string|number|nil
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
---@param value string|number|nil
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
---@param value string|number|nil
---@return self
---@overload fun(self, param: {[string]: string|number|nil})
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

--- Include the full functionality for faking
mw.html = require('3rd.mw.html')

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
function mw.language.getContentLanguage()
	return setmetatable(mw.language, {})
end
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
function mw.language.new(code)
	return mw.language.getContentLanguage()
end
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
function mw.language:ucfirst(str)
	-- TODO: UTF8 support in fake
	if str == 'übung' then
		return 'Übung'
	end
	return (str:gsub("^%l", string.upper))
end

---Converts the string to a representation appropriate for case-insensitive comparison. Note that the result may not make any sense when displayed.
---@param str string
---@return string
function mw.language:caseFold(str) end

---Formats a number with grouping and decimal separators appropriate for the given language. Given 123456.78, this may produce "123,456.78", "123.456,78", or even something like "١٢٣٬٤٥٦٫٧٨" depending on the language and wiki configuration.
---@param num number
---@param options? {noCommafy: boolean}
---@return string
function mw.language:formatNum(num, options)
	local k
	local formatted = tostring(num)
	while true do
		formatted, k = string.gsub(formatted, '^(-?%d+)(%d%d%d)', '%1,%2')
		if (k == 0) then
			break
		end
	end
	return formatted
end

---Formats a date according to the given format string. If timestamp is omitted, the default is the current time. The value for local must be a boolean or nil; if true, the time is formatted in the wiki's local time rather than in UTC.
---@param format string
---@param timestamp string|osdateparam?
---@param localTime boolean?
---@return number|string
function mw.language:formatDate(format, timestamp, localTime)
	local function localTimezoneOffset(ts)
		local utcDt = os.date("!*t", ts)
		local localDt = os.date("*t", ts)
		localDt.isdst = false
		return os.difftime(os.time(localDt --[[@as osdateparam]]), os.time(utcDt --[[@as osdateparam]]))
	end

	local function parseDateString(timeString)
		local year, month, day = timeString:match('(%d%d%d%d)-?(%d%d)-?(%d%d)')
		local hour = timeString:match('%d%d%d%d%-?%d%d%-?%d%d[ T]?(%d%d)')
		local minute = timeString:match('%d%d%d%d%-?%d%d%-?%d%d[ T]?%d%d:?(%d%d)')
		local second = timeString:match('%d%d%d%d%-?%d%d%-?%d%d[ T]?%d%d:?%d%d:?(%d%d)')

		return year, month, day, hour, minute, second
	end

	local function makeOsdateParam(year, month, day, hour, minute, second)
		return {year = year, month = month or 1, day = day or 1, hour = hour or 0, min = minute, sec = second}
	end

	if format == 'U' then
		if not timestamp then
			return os.time(os.date("!*t") --[[@as osdateparam]])
		end
		if type(timestamp) ~= 'string' then
			return os.time(timestamp)
		end
		local tzHour, tzMinutes = timestamp:match('([%-%+]%d?%d):(%d%d)$')
		local offset = 0
		if tzHour then
			offset = tonumber(tzHour) * 3600 + tonumber(tzMinutes) * 60
		end

		local year, month, day, hour, minute, second = parseDateString(timestamp)
		if not year then
			return ''
		end

		local ts = os.time(makeOsdateParam(year, month, day, hour, minute, second)) - offset

		return ts + localTimezoneOffset(ts)
	elseif format == 'c' then
		local outFormat = '%Y-%m-%dT%H:%M:%S'
		if not timestamp then
			return os.date(outFormat) --[[@as string]]
		end
		if type(timestamp) == 'string' and string.sub(timestamp, 1, 1) == '@' then
			return os.date(outFormat, tonumber(string.sub(timestamp, 2))) --[[@as string]]
		end
		if type(timestamp) == 'string' then
			local year, month, day, hour, minute, second = parseDateString(timestamp)
			if not year then
				return ''
			end
			return os.date(outFormat, os.time(makeOsdateParam(year, month, day, hour, minute, second))) --[[@as string]]
		end
		return os.date(outFormat, os.time(timestamp)) --[[@as string]]
	end
	return ''
end

---Breaks a duration in seconds into more human-readable units, e.g. 12345 to 3 hours, 25 minutes and 45 seconds, returning the result as a string.
---@param seconds number
---@param chosenIntervals table
---@return string
function mw.language:formatDuration(seconds, chosenIntervals) end

---This takes a number as formatted by lang:formatNum() and returns the actual number. In other words, this is basically a language-aware version of tonumber().
---@param str string
---@return number
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
---@overload fun(self, param: string|number):self
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

---@alias namespaceInfo {id: number, name: string, canonicalName: string, displayName: string, hasSubpages: boolean, hasGenderDistinction: boolean, isCapitalized: boolean, isContent: boolean, isIncludable: boolean, isMovable:boolean, isSubject: boolean, isTalk: boolean, defaultContentModel: string, aliases: string[], subject: namespaceInfo, talk: namespaceInfo, associated: namespaceInfo}
---@class Site
---@field currentVersion string
---@field scriptPath string
---@field server string
---@field siteName string
---@field namespaces table<number|string, namespaceInfo>
---@field contentNamespaces table<number|string, namespaceInfo>
---@field subjectNamespaces table<number|string, namespaceInfo>
---@field talkNamespaces table<number|string, namespaceInfo>
---@field stats {pages: number, articles: number, files: number, edits: number, users: number, activeUsers: number, admins: number}
mw.site = {server = 'https://liquipedia.net/wiki/'}

---Returns a table holding data about available interwiki prefixes. If filter is the string "local", then only data for local interwiki prefixes is returned. If filter is the string "!local", then only data for non-local prefixes is returned. If no filter is specified, data for all prefixes is returned. A "local" prefix in this context is one that is for the same project.
---@param filter nil|'local'|'!local'
---@return {prefix: string, url: string, isProtocolRelative: boolean, isLocal: boolean, isCurrentWiki: boolean, isTranscludable: boolean, isExtraLanguageLink: boolean, displayText:string, tooltip: string?}
function mw.site.interwikiMap(filter) end

mw.text = {}

---Replaces HTML entities in the string with the corresponding characters.
---@param s string
---@param decodeNamedEntities boolean?
---@return string
function mw.text.decode(s, decodeNamedEntities) end

---Replaces characters in a string with HTML entities. Characters '<', '>', '&', '"', and the non-breaking space are replaced with the appropriate named entities; all others are replaced with numeric entities.
---@param s string
---@param charset string?
---@return string
function mw.text.encode(s, charset) end

---Decodes a JSON string. flags is 0 or a combination (use +) of the flags mw.text.JSON_PRESERVE_KEYS and mw.text.JSON_TRY_FIXING.
---@param s string
---@param flags number?
---@return table
function mw.text.jsonDecode(s, flags)
	return require('3rd.jsonlua.mock_json'):decode(s)
end

---Encode a JSON string. Errors are raised if the passed value cannot be encoded in JSON. flags is 0 or a combination (use +) of the flags mw.text.JSON_PRESERVE_KEYS and mw.text.JSON_PRETTY.
---@param s any
---@param flags number?
---@return string
function mw.text.jsonEncode(s, flags)
	return require('3rd.jsonlua.mock_json'):encode(s)
end

---Removes all MediaWiki strip markers from a string.
---@param s string
---@return string
function mw.text.killMarkers(s) end

---Joins a list, prose-style. In other words, it's like table.concat() but with a different separator before the final item.
---@param list table
---@param separator string?
---@param conjunction string?
---@return string
function mw.text.listToText(list, separator, conjunction) end

---Replaces various characters in the string with HTML entities to prevent their interpretation as wikitext.
---@param s string
---@return string
function mw.text.nowiki(s)
	-- TODO: This only covers some
	return (string.gsub( s, '["&\'<=>%[%]{|}]', {
		['"'] = '&#34;',
		['&'] = '&#38;',
		["'"] = '&#39;',
		['<'] = '&#60;',
		['='] = '&#61;',
		['>'] = '&#62;',
		['['] = '&#91;',
		[']'] = '&#93;',
		['{'] = '&#123;',
		['|'] = '&#124;',
		['}'] = '&#125;',
	}))
end

---Splits the string into substrings at boundaries matching the Ustring pattern pattern. If plain is specified and true, pattern will be interpreted as a literal string rather than as a Lua pattern.
---@param s string|number
---@param pattern string?
---@param plain boolean?
---@return string[]
function mw.text.split(s, pattern, plain)
	pattern = pattern or "%s"
	local t = {}
	for str in string.gmatch(s, "([^"..pattern.."]+)") do
			table.insert(t, str)
	end
	return t
end

---Returns an iterator function that will iterate over the substrings that would be returned by the equivalent call to mw.text.split().
---@param s string
---@param pattern string?
---@param plain boolean?
---@return function
function mw.text.gsplit(s, pattern, plain) end

---Generates an HTML-style tag for name.
---@param name string
---@param attrs table?
---@param content nil|string|boolean
---@return string
---@overload fun(params: {name: string, attrs: table, content: nil|string|boolean})
function mw.text.tag(name, attrs, content) end

---Remove whitespace or other characters from the beginning and end of a string.
---@param s string
---@param charset string?
---@return string
function mw.text.trim(s, charset)
	-- TODO: UTF8 support in fake
	return string.match( s, '^()%s*$' ) and '' or string.match( s, '^%s*(.*%S)' )
end

---Truncates text to the specified length in code points, adding ellipsis if truncation was performed. If length is positive, the end of the string will be truncated; if negative, the beginning will be removed
---@param text string
---@param length number
---@param ellipsis string?
---@param adjustLength boolean
---@return string
function mw.text.truncate(text, length, ellipsis, adjustLength) end

---Replaces MediaWiki <nowiki> strip markers with the corresponding text. Other types of strip markers are not changed.
---@param s string
---@return string
function mw.text.unstripNoWiki(s) end

---Equivalent to mw.text.killMarkers( mw.text.unstripNoWiki( s ) ).
---@param s string
---@return string
function mw.text.unstrip(s) end


---@class Title
---@field id number
---@field interwiki string
---@field namespace number
---@field nsText string
---@field subjectNsText string
---@field text string
---@field prefixedText string
---@field fullText string
---@field rootText string
---@field baseText string
---@field subpageText string
---@field canTalk string
---@field fragment string?
---@field exists boolean
---@field file File
---@field fileExists boolean
---@field isContentPage boolean
---@field isExternal boolean
---@field isLocal boolean
---@field isRedirect boolean
---@field isSpecialPage boolean
---@field isSubpage boolean
---@field isTalkPage boolean
---@field contentModel string
---@field basePageTitle Title
---@field rootPageTitle Title
---@field talkPageTitle Title?
---@field subjectPageTitle Title
---@field redirectTarget Title|false
---@field protectionLevels table
---@field cascadingProtection table
mw.title = {
	namespace = 0,
	nsText = '',
	text = 'FakePage',
	prefixedText = 'FakePage',
	fullText = 'FakePage',
	baseText = 'FakePage',
}

---@class File
---@field exists boolean
---@field width number
---@field height number
---@field pages {width: number, height: number}[]?
---@field size number
---@field mimeType string
---@field length number

---Test for whether two titles are equal. Note that fragments are ignored in the comparison.
---@param a Title
---@param b Title
---@return boolean
function mw.title.equals(a, b) end

---Returns -1, 0, or 1 to indicate whether the title a is less than, equal to, or greater than title b.
---@param a Title
---@param b Title
---@return -1|0|1
function mw.title.compare(a, b) end

---Returns the title object for the current page.
---@return Title
function mw.title.getCurrentTitle()
	return setmetatable(mw.title, {})
end

---Creates a new title object. This function is expensive when called with an ID.
---If the text string does not specify a namespace, namespace (which may be any key found in mw.site.namespaces) will be used.
---If the text is not a valid title, nil is returned.
---@param text string
---@param namespace string?
---@return Title?
---@overload fun(id: number):Title?
function mw.title.new(text, namespace)
	return setmetatable(mw.title, {})
end

---Creates a title object with title title in namespace namespace, optionally with the specified fragment and interwiki prefix. namespace may be any key found in mw.site.namespaces. If the resulting title is not valid, returns nil.
---Note that, unlike mw.title.new(), this method will always apply the specified namespace.
---If the text is not a valid title, nil is returned.
---@param namespace string
---@param title string
---@param fragment string?
---@param interwiki string?
---@return Title?
function mw.title.makeTitle(namespace, title, fragment, interwiki) end

---Whether this title is a subpage of the given title.
---@param title2 Title
---@return boolean
function mw.title:isSubpageOf(title2) end

---Whether this title is in the given namespace.
---@param ns string|number
---@return boolean
function mw.title:inNamespace(ns)
	if ns == 0 then
		return true
	end
	return false
end

---Whether this title is in any of the given namespaces.
---@param ... string|number
---@return boolean
function mw.title:inNamespaces(...) end

---Whether this title's subject namespace is in the given namespace.
---@param ns string|number
---@return boolean
function mw.title:hasSubjectNamespace(ns) end

---The same as mw.title.makeTitle( title.namespace, title.text .. '/' .. text ).
---@param text string
---@return Title
function mw.title:subPageTitle(text) end

---Returns title.text encoded as it would be in a URL.
---@return string
function mw.title:partialUrl() end

---Returns the full URL (with optional query table/string) for this title.
---@param query? table|string
---@param proto? 'http'|'https'|'relative'|'canonical'
---@return string
function mw.title:fullUrl(query, proto) end

---Returns the local URL (with optional query table/string) for this title.
---@param query? table|string
---@return string
function mw.title:localUrl(query) end

---Returns the canonical URL (with optional query table/string) for this title.
---@param query? table|string
---@return string
function mw.title:canonicalUrl(query) end

---Returns the (unparsed) content of the page, or nil if there is no page. The page will be recorded as a transclusion.
---@return string?
function mw.title:getContent() end

---@class ustring
---@field maxPatternLength number The maximum allowed length of a pattern, in bytes.
---@field maxStringLength number The maximum allowed length of a string, in bytes.
mw.ustring = {}

---Returns individual bytes; identical to string.byte().
---@see string.byte
---@param s string|number
---@param i? integer
---@param j? integer
---@return integer ...
function mw.ustring.byte(s, i, j) end

---Returns the byte offset of a character in the string. The default for both l and i is 1. i may be negative, in which case it counts from the end of the string.
---@param s string|number
---@param l? integer
---@param i? integer
---@return integer ...
function mw.ustring.byteoffset(s, l, i) end

---Much like string.char(), except that the integers are Unicode codepoints rather than byte values.
---@see string.char
---@param ... integer
---@return string
function mw.ustring.char(...) end

---Much like string.byte(), except that the return values are codepoints and the offsets are characters rather than bytes.
---@see string.byte
---@param s string|number
---@param i? integer
---@param j? integer
---@return integer ...
function mw.ustring.codepoint(s, i, j) end

---Much like string.find(), except that the pattern is extended as described in Ustring patterns and the init offset is in characters rather than bytes.
---@see string.find
---@param s string|number
---@param pattern string|number
---@param init? integer
---@param plain? boolean
---@return integer|nil start
---@return integer|nil end
---@return any|nil ... captured
function mw.ustring.find(s, pattern, init, plain) end

---Identical to string.format(). Widths and precisions for strings are expressed in bytes, not codepoints.
---@see string.format
---@param format string|number
---@param ... any
---@return string
function mw.ustring.format(format, ...) end

---Returns three values for iterating over the codepoints in the string. i defaults to 1, and j to -1. This is intended for use in the iterator form of for:
---@param s string|number
---@param i? integer
---@param j? integer
---@return string
function mw.ustring.gcodepoint(s, i, j) end

---Much like string.gmatch(), except that the pattern is extended as described in Ustring patterns.
---@see string.gmatch
---@param s string|number
---@param pattern string|number
---@return fun():string, ...
function mw.ustring.gmatch(s, pattern) end

---Much like string.gmatch(), except that the pattern is extended as described in Ustring patterns.
---@see string.gsub
---@param s string|number
---@param pattern string|number
---@param repl string|number|table|function
---@param n? integer
---@return string
---@return integer count
function mw.ustring.gsub(s, pattern, repl, n) end

---Returns true if the string is valid UTF-8, false if not.
---@param s string|number
---@return boolean
function mw.ustring.isutf8(s) end

---Returns the length of the string in codepoints, or nil if the string is not valid UTF-8.
---@see string.len
---@param s string|number
---@return integer
function mw.ustring.len(s) end

---Much like string.lower(), except that all characters with lowercase to uppercase definitions in Unicode are converted.
---@see string.lower
---@param s string|number
---@return string
function mw.ustring.lower(s)
	if s == 'Örban' then
		return 'örban'
	end
	return string.lower(s)
end

---Much like string.match(), except that the pattern is extended as described in Ustring patterns and the init offset is in characters rather than bytes.
---@see string.match
---@param s string|number
---@param pattern string|number
---@param init? integer
---@return any ...
function mw.ustring.match(s, pattern, init) end

---Identical to string.rep().
---@see string.rep
---@param s string|number
---@param n integer
---@return string
function mw.ustring.rep(s, n) end

---Identical to string.sub().
---@see string.sub
---@param s string|number
---@param i integer
---@param j? integer
---@return string
function mw.ustring.sub(s, i, j) end

---Converts the string to Normalization Form C (also known as Normalization Form Canonical Composition). Returns nil if the string is not valid UTF-8.
---@param s string|number
---@return string?
function mw.ustring.toNFC(s) return tostring(s) end

---Converts the string to Normalization Form D (also known as Normalization Form Canonical Decomposition). Returns nil if the string is not valid UTF-8.
---@param s string|number
---@return string?
function mw.ustring.toNFD(s) return tostring(s) end

---Converts the string to Normalization Form KC (also known as Normalization Form Compatibility Composition). Returns nil if the string is not valid UTF-8.
---@param s string|number
---@return string?
function mw.ustring.toNFKC(s) return tostring(s) end

---Converts the string to Normalization Form KD (also known as Normalization Form Compatibility Decomposition). Returns nil if the string is not valid UTF-8.
---@param s string|number
---@return string?
function mw.ustring.toNFKD(s) return tostring(s) end

---Much like string.upper(), except that all characters with uppercase to lowercase definitions in Unicode are converted.
---@see string.upper
---@param s string|number
---@return string
function mw.ustring.upper(s) return string.upper(s) end

mw.uri = {}
function mw.uri.localUrl(s, s2) return '' end

mw.ext = {}
mw.ext.LiquipediaDB = require('definitions.liquipedia_db')

mw.ext.VariablesLua = {}
---@alias wikiVariableKey string|number
---@alias wikiVariableValue string|number|nil

---Fake storage for enviroment simulation
---@private
mw.ext.VariablesLua.variablesStorage = {}

---Stores a wiki-variable and returns the empty string
---@param name wikiVariableKey
---@param value wikiVariableValue
---@return string #always an empty string
function mw.ext.VariablesLua.vardefine(name, value)
	mw.ext.VariablesLua.variablesStorage[name] = value
	return ''
end

---Stores a wiki-variable and returns the stored value
---@param name wikiVariableKey Key of the wiki-variable
---@param value wikiVariableValue Value of the wiki-variable
---@return string
function mw.ext.VariablesLua.vardefineecho(name, value)
	mw.ext.VariablesLua.vardefine(name, value)
	return mw.ext.VariablesLua.var(name)
end

---Gets the stored value of a wiki-variable
---@param name wikiVariableKey Key of the wiki-variable
---@return string
function mw.ext.VariablesLua.var(name)
	return mw.ext.VariablesLua.variablesStorage[name] and tostring(mw.ext.VariablesLua.variablesStorage[name]) or ''
end

---Checks if a wiki-variable is stored
---@param name wikiVariableKey Key of the wiki-variable
---@return boolean
function mw.ext.VariablesLua.varexist(name)
	return mw.ext.VariablesLua.variablesStorage[name] ~= nil
end

mw.ext.CurrencyExchange = {}

---@param amount number
---@param fromCurrency string
---@param toCurrency string
---@param date? string
---@return number
function mw.ext.CurrencyExchange.currencyexchange(amount, fromCurrency, toCurrency, date)
	-- Fake mock number
	return 0.97097276906869
end

mw.ext.TeamLiquidIntegration = {}

---Adds a category to a page
---@param name string
---@param sortName string?
function mw.ext.TeamLiquidIntegration.add_category(name, sortName) end

---Follows page redirects
---@param name string
---@return string
function mw.ext.TeamLiquidIntegration.resolve_redirect(name) return name end

mw.ext.TeamTemplate = {}

---@param teamteplate string
---@param date string|number?
---@return {templatename: string, historicaltemplate: string?, shortname: string, name: string, bracket: string, page: string, icon: string, image: string, legacyimage: string, legacyimagedark: string}
function mw.ext.TeamTemplate.raw(teamteplate, date) end

---@param teamteplate string
---@return {[string]: string} ## key is formated as `YYYY-MM-DD`and values are team template names
function mw.ext.TeamTemplate.raw_historical(teamteplate) end

---@param teamteplate string
---@return boolean
function mw.ext.TeamTemplate.teamexists(teamteplate) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.team(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.team2(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.teamshort(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.team2short(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.teambracket(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.teamicon(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.teamimage(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.teampage(teamteplate, date) end

---@param teamteplate string
---@param date string|number?
---@return string
function mw.ext.TeamTemplate.teampart(teamteplate, date) end

mw.ext.SearchEngineOptimization = {}

---@param desc string
function mw.ext.SearchEngineOptimization.metadescl(desc) end

---@param image string
function mw.ext.SearchEngineOptimization.metaimage(image) end

mw.ext.Brackets = {}
---@param idToCheck string
---@return string
function mw.ext.Brackets.checkBracketDuplicate(idToCheck)
	return 'ok'
end

mw.ext.Dota2DB = {}

---@alias dota2VetoEntry {hero: string?, order: number?}
---@alias dota2TeamVeto {bans: dota2VetoEntry[]?, picks: dota2VetoEntry[]?}
---@alias dota2PlayerItem {name: string?, image: string?, image_url: string?}

---@class dota2MatchTeamPlayer
---@field aghanimsScepterBuff 0|1|nil
---@field aghanimsShardBuff 0|1|nil
---@field assists integer?
---@field backpackItems dota2PlayerItem[]?
---@field buildingDamage integer?
---@field damage integer?
---@field deaths integer?
---@field denies integer?
---@field facet string?
---@field goldPerMinute integer?
---@field heroId integer?
---@field heroName string?
---@field id integer?
---@field items dota2PlayerItem[]?
---@field kills integer?
---@field lastHits integer?
---@field level integer?
---@field moonShardBuff 0|1|nil
---@field name string?
---@field neutralItem dota2PlayerItem?
---@field position 1|2|3|4|5|nil
---@field towerDamage integer?
---@field totalGold integer?
---@field wards {observerKills: integer?, observerPlaced: integer?, sentryKills: integer?, sentryPlaced: integer?}?
---@field xpPerMinute integer?

---@class dota2MatchTeam
---@field barracksDestroyed integer?
---@field players dota2MatchTeamPlayer[]
---@field roshanKills integer?
---@field side 'radiant'|'dire'|nil
---@field towersDestroyed integer?

---@class dota2MatchData
---@field heroVeto {team1: dota2TeamVeto[], team2:dota2TeamVeto[]}
---@field length string?
---@field lengthInSeconds integer?
---@field patch string?
---@field startTime string?
---@field team1 dota2MatchTeam
---@field team2 dota2MatchTeam
---@field team1score integer?
---@field team2score integer?
---@field winner 1|2|nil

---@param matchId integer
---@param reversed boolean?
---@return dota2MatchData
function mw.ext.Dota2DB.getBigMatch(matchId, reversed) end

return mw
