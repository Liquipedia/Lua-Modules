---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:CharacterNames')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local TeamTemplate = Lua.import('Module:TeamTemplate')
local UpcomingMatches = Lua.import('Module:Matches Player')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local ACHIEVEMENTS_BASE_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionUtil.anyOf(ColumnName('liquipediatier'), {1, 2}),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

local INPUTS = {
	controller = 'Controller',
	cont = 'Controller',
	c = 'Controller',
	hybrid = 'Hybrid',
	default = 'Mouse & Keyboard',
}

local SIZE_LEGEND = '25x25px'

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	-- Automatic achievements
	player.args.achievements = Achievements.player{
		noTemplate = true,
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local legendIcons = Array.map(caller:getAllArgsForBase(args, 'legends'), function(legend)
			return CharacterIcon.Icon{character = CharacterNames[legend:lower()], size = SIZE_LEGEND}
		end)
		Array.appendWith(widgets,
			Cell{
				name = #legendIcons > 1 and 'Signature Legends' or 'Signature Legend',
				children = {table.concat(legendIcons, '&nbsp;')}
			},
			Cell{name = 'Input', children = {caller:formatInput()}}
		)
	elseif id == 'region' then
		return {}
	elseif id == 'status' then
		return {
			Cell{name = 'Status', children = caller:_getStatusContents()},
			Cell{name = 'Years Active (Player)', children = {args.years_active}},
			Cell{name = 'Years Active (Org)', children = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', children = {args.years_active_coach}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			children = {args.retired}
		})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.extradata.input = self:formatInput()
	lpdbData.extradata.retired = args.retired

	for _, legend, legendIndex in Table.iter.pairsByPrefix(args, 'legends', {requireIndex = false}) do
		lpdbData.extradata['signatureLegend' .. legendIndex] = CharacterNames[legend:lower()]
	end

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = TeamTemplate.getRaw(args.team2).page
	end

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) then
		return UpcomingMatches.get(self.args)
	end
end

---@return string[]
function CustomPlayer:_getStatusContents()
	local status = Logic.readBool(self.args.banned) and 'Banned' or Logic.emptyOr(self.args.banned, self.args.status)
	return {Page.makeInternalLink({onlyIfExists = true}, status) or status}
end

---@return string
function CustomPlayer:formatInput()
	local lowercaseInput = self.args.input and self.args.input:lower() or nil
	return INPUTS[lowercaseInput] or INPUTS.default
end

return CustomPlayer
