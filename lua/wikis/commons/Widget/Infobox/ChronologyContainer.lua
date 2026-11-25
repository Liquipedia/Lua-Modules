---
-- @Liquipedia
-- page=Module:Widget/Infobox/ChronologyContainer
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Logic = Lua.import('Module:Logic')

local Component = Lua.import('Module:Widget/Component')
local ChronologyDisplay = Lua.import('Module:Widget/Infobox/Chronology')

---@param props {title: string?, showTitle: boolean?, args: table?}
---@return Widget?
local function Chronology(props)
	local args = props.args or {}

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
		title = props.title,
		showTitle = props.showTitle,
	}
end

return Component.component(Chronology)
