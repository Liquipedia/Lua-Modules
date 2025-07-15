---
-- @Liquipedia
-- page=Module:Widget/Infobox/Chronology
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')

local Widget = Lua.import('Module:Widget')
local ChronologyDisplay = Lua.import('Module:Widget/Infobox/ChronologyDisplay')

---@class ChronologyWidget: Widget
---@operator call(table): ChronologyWidget
---@field props {title: string?, showTitle: boolean?, args: table?}
local Chronology = Class.new(Widget)

---@return Widget?
function Chronology:render()
	local args = self.props.args or {}

	---@param input string?
	---@return {link:string, display: string}?
	local processLinkInput = function(input)
		if Logic.isEmpty(input) then return end
		---@cast input -nil
		local link, text = unpack(mw.text.split(input, '|'))
		return {
			link = link,
			text = text or link,
		}
	end

	---@type {previous: {link:string, text: string}?, next: {link:string, text: string}?}[]
	local links = Array.mapIndexes(function(index)
		local postFix = index == 1 and '' or index

		return Logic.nilIfEmpty({
			previous = processLinkInput(args['previous' .. postFix]),
			next = processLinkInput(args['next' .. postFix]),
		})
	end)

	return ChronologyDisplay{
		links = links,
		title = self.props.title,
		showTitle = self.props.showTitle,
	}
end

return Chronology
