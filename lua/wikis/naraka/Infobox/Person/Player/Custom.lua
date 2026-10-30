---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Class = Lua.import('Module:Class')
local Math = Lua.import('Module:MathUtil')
local String = Lua.import('Module:StringUtils')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')
local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

-- Condition query dependencies
local Condition = Lua.import('Module:Condition')
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local ColumnName = Condition.ColumnName
local ConditionUtil = Condition.Util

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local CURRENT_YEAR = tonumber(os.date('%Y'))

-- S-Tier tournament champion filter conditions
local S_TIER_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionNode(ColumnName('liquipediatier'), Comparator.eq, 1),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

-- A-Tier tournament champion filter conditions
local A_TIER_CONDITIONS = {
	ConditionUtil.noneOf(ColumnName('liquipediatiertype'), {'Showmatch', 'Qualifier'}),
	ConditionNode(ColumnName('liquipediatier'), Comparator.eq, 2),
	ConditionNode(ColumnName('placement'), Comparator.eq, 1),
}

---@class NarakaInfoboxPlayer: InfoboxPerson
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return VNode
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	local args = player.args

	-- Automatic achievements: display S-Tier and A-Tier separately
	local sTierIcons = Achievements.player{
		noTemplate = true,
		baseConditions = S_TIER_CONDITIONS,
	}
	local aTierIcons = Achievements.player{
		noTemplate = true,
		baseConditions = A_TIER_CONDITIONS,
	}

	local achievementSections = {}

	-- Tier label on left, icons keep centered
	local function renderTierRow(label, icons)
		return '<div style="position:relative;width:100%;;padding:6px 10px;box-sizing:border-box;text-align:center;">' ..
			'<span style="position:absolute;left:10px;top:50%;transform:translateY(-50%);font-size:1.2em;font-weight:700;color:#000;white-space:nowrap;">' .. label .. '</span>' ..
			'<span style="display:inline-block;">' .. icons .. '</span>' ..
			'</div>'
	end

	if String.isNotEmpty(sTierIcons) then
		table.insert(achievementSections, renderTierRow('S-Tier', sTierIcons))
	end

	if String.isNotEmpty(aTierIcons) then
		table.insert(achievementSections, renderTierRow('A-Tier', aTierIcons))
	end

	args.achievements = table.concat(achievementSections, '')

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
		if currentYearEarnings == 0 then return widgets end
		local currentYearEarningsDisplay = '$' .. mw.getContentLanguage():formatNum(Math.round(currentYearEarnings))

		table.insert(widgets, Cell{name = 'Approx. Earnings '.. CURRENT_YEAR, children = {currentYearEarningsDisplay}})
	end

	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	return lpdbData
end

return CustomPlayer
