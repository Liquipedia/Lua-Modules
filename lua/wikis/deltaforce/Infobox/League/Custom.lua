---
-- @Liquipedia
-- page=Module:Infobox/League/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Page = Lua.import('Module:Page')

local Injector = Lua.import('Module:Widget/Injector')
local League = Lua.import('Module:Infobox/League')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title
local Center = Widgets.Center

---@class DeltaForceLeagueInfobox: InfoboxLeague
local CustomLeague = Class.new(League)
local CustomInjector = Class.new(Injector)

local PLATFORMS = {
	pc = 'PC',
	mobile = 'Mobile',
	cross = 'Cross-Platform',
	default = 'Unknown',
}

local MODES = {
	wf = 'Warfare',
	op = 'Operations',
	default = 'Unknown',
}

---@param frame Frame
---@return Widget
function CustomLeague.run(frame)
	local league = CustomLeague(frame)
	league:setWidgetInjector(CustomInjector(league))

	league.args.mode = MODES[(league.args.mode or 'default'):lower():gsub(' ', '')]
	league.args.platform = PLATFORMS[(league.args.platform or 'default'):lower():gsub(' ', '')]

	return league:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		Array.appendWith(widgets,
			Cell{name = 'Mode', children = {args.mode}},
			Cell{name = 'Platform', children = {args.platform}}
		)
	elseif id == 'customcontent' then
		if String.isNotEmpty(args.map1) then
			local game = String.isNotEmpty(args.game) and ('/' .. args.game) or ''
			local maps = {}

			for _, map in ipairs(self.caller:getAllArgsForBase(args, 'map')) do
				table.insert(maps, tostring(self.caller:_createNoWrappingSpan(
					Page.makeInternalLink({}, map, map .. game)
				)))
			end
			table.sort(maps)
			table.insert(widgets, Title{children = 'Maps'})
			table.insert(widgets, Center{children = {table.concat(maps, '&nbsp;• ')}})
		end
	elseif id == 'gamesettings' then
		table.insert(widgets, Cell{
			name = 'Patch',
			children = {self.caller:_createPatchCell(args)}
		})
	end

	return widgets
end

---@param args table
---@return string?
function CustomLeague:_createPatchCell(args)
	if String.isEmpty(args.patch) then
		return nil
	end
	local content

	if String.isEmpty(args.epatch) then
		content = '[[' .. args.patch .. '|'.. args.patch .. ']]'
	else
		content = '[[' .. args.patch .. '|'.. args.patch .. ']]' .. ' &ndash; ' ..
		'[[' .. args.epatch .. '|'.. args.epatch .. ']]'
	end

	return content
end

---@param content Html|string|number|nil
---@return Html
function CustomLeague:_createNoWrappingSpan(content)
	return mw.html.create('span')
		:css('white-space', 'nowrap')
		:node(content)
end

---@param args table
---@return string[]
function CustomLeague:getWikiCategories(args)
	return {
		args.mode and (args.mode .. ' Competitions') or 'Tournaments without specified mode',
		args.platform and (args.platform .. ' Tournaments') or 'Tournaments on unknown platforms',
	}
end

return CustomLeague
