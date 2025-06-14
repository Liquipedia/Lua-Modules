---
-- @Liquipedia
-- page=Module:I18n
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local FnUtil = require('Module:FnUtil')
local Lua = require('Module:Lua')
local String = require('Module:StringUtils')

local I18nData = Lua.import('Module:I18n/Data', {loadData = true})
local I18n = {}

local getLanguage = FnUtil.memoize(function ()
	return mw.language.getContentLanguage():getCode()
end)

---Interpolates an i18n string with data
---TODO Add pluralization support (https://cldr.unicode.org/index/cldr-spec/plural-rules)
---@param key string
---@param data table<string, string|number>?
---@return string
function I18n.translate(key, data)
	local language = getLanguage()
	local langMessages = I18nData[language] or I18nData.en
	local message = langMessages[key] or I18nData.en[key]
	if not message then
		return '⧼' .. key .. '⧽'
	end
	return String.interpolate(message, data or {})
end

return I18n
