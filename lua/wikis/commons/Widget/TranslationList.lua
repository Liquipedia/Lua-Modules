---
-- @Liquipedia
-- page=Module:Widget/TranslationList
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Variables = Lua.import('Module:Variables')

local Link = Lua.import('Module:Widget/Basic/Link')
local HtmlWidget = Lua.import('Module:Widget/Html/All')
local Widget = Lua.import('Module:Widget')

---@class TranslationList: Widget
---@operator call(table): TranslationList
local TranslationList = Class.new(Widget)

local DEFAULT_LIMIT = 3

---@return Widget[]
function TranslationList:render()
	-- can not use defaultProps due to casting to number
	local limit = tonumber(self.props.limit) or DEFAULT_LIMIT

	local translations = TranslationList._getTranslations()
	Variables.varDefine('total_number_of_translations', #translations)

	translations = Array.sub(Array.randomize(translations), 1, limit)

	return HtmlWidget.Ul{children = Array.map(translations, function(translation)
		return HtmlWidget.Li{
			children = {
				Link{link = translation.pagename, children = {translation.name}},
			}
		}
	end)}
end

---Fetches "Translations" datapoints
---@return table
function TranslationList._getTranslations()
	return mw.ext.LiquipediaDB.lpdb('datapoint', {
		limit = 5000,
		conditions = '[[type::translation]]'
	})
end

return TranslationList
