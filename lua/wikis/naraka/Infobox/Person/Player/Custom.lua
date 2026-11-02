---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local DateExt = Lua.import('Module:Date/Ext')
local Math = Lua.import('Module:MathUtil')
local String = Lua.import('Module:StringUtils')
local TeamTemplate = Lua.import('Module:TeamTemplate')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = DateExt.getYearOf()

-- T1 and T2 tournament champions
local CHAMPION_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionUtil.anyOf(ColumnName('liquipediatier'), {1, 2}),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

---@class NarakaInfoboxPlayer: InfoboxPerson
---@operator call(Frame): NarakaInfoboxPlayer
local CustomPlayer = Class.new(Player)

---@class NarakaInfoboxPlayerWidgetInjector: WidgetInjector
---@operator call(NarakaInfoboxPlayer): NarakaInfoboxPlayerWidgetInjector
---@field caller NarakaInfoboxPlayer
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	local args = player.args

	args.achievements = Achievements.player{
		noTemplate = true,
		baseConditions = CHAMPION_CONDITIONS,
	}

	-- Uppercase first letter in status
	if args.status then
		args.status = mw.getContentLanguage():ucfirst(args.status)
	end

	return player:createInfobox()
end

---@param id string
---@param widgets Renderable[]
---@return Renderable[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args

	if id == 'custom' then
		local currentYearEarnings = self.caller.earningsPerYear[CURRENT_YEAR] or 0

		if currentYearEarnings == 0 then
			return widgets
		end

		local currentYearEarningsDisplay =
			'$' .. mw.getContentLanguage():formatNum(Math.round(currentYearEarnings))

		table.insert(widgets, Cell{
			name = 'Approx. Earnings ' .. CURRENT_YEAR,
			children = {currentYearEarningsDisplay},
		})
	elseif id == 'region' then
		return {}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			children = {args.retired},
		})
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = TeamTemplate.getPageName(args.team2)
	end

	return lpdbData
end

return CustomPlayer
