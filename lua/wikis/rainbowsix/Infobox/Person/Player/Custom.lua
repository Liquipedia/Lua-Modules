---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:CharacterNames')
local Class = Lua.import('Module:Class')
local GameAppearances = Lua.import('Module:Infobox/Extension/GameAppearances')
local Page = Lua.import('Module:Page')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Achievements = Lua.import('Module:Infobox/Extension/Achievements')

local ACHIEVEMENTS_BASE_CONDITIONS = {
	'[[liquipediatiertype::!Showmatch]]',
	'[[liquipediatiertype::!Qualifier]]',
	'([[liquipediatier::1]] OR [[liquipediatier::2]])',
	'[[placement::1]]',
}

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local BANNED = Lua.import('Module:Banned', {loadData = true})

local SIZE_OPERATOR = '25x25px'

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{addlpdbdata = true, specialRoles = true}
	-- Automatic achievements
	player.args.achievements = Achievements.player{
		baseConditions = ACHIEVEMENTS_BASE_CONDITIONS
	}

	player.args.banned = tostring(player.args.banned or '')

	player.args.autoTeam = true

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		-- Signature Operators
		local operatorIcons = Array.map(caller:getAllArgsForBase(args, 'operator'), function(operator)
			return CharacterIcon.Icon{character = CharacterNames[operator:lower()], size = SIZE_OPERATOR}
		end)
		table.insert(widgets, Cell{
			name = #operatorIcons > 1 and 'Signature Operators' or 'Signature Operator',
			content = {table.concat(operatorIcons, '&nbsp;')},
		})

		-- Active in Games
		table.insert(widgets, Cell{
			name = 'Game Appearances',
			content = GameAppearances.player{player = caller.pagename}
		})
	elseif id == 'status' then
		return {
			Cell{name = 'Status', content = caller:_getStatusContents()},
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (Org)', content = {args.years_active_manage}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}},
			Cell{name = 'Time Banned', content = {args.time_banned}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	for _, operator, operatorIndex in Table.iter.pairsByPrefix(args, 'operator', {requireIndex = false}) do
		lpdbData.extradata['signatureOperator' .. operatorIndex] = CharacterNames[operator:lower()]
	end

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(),self.args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
end

---@return string[]
function CustomPlayer:_getStatusContents()
	local args = self.args
	local statusContents = {}

	if String.isNotEmpty(args.status) then
		table.insert(statusContents, Page.makeInternalLink({onlyIfExists = true}, args.status) or args.status)
	end

	local banned = BANNED[string.lower(args.banned or '')]
	if not banned and String.isNotEmpty(args.banned) then
		banned = '[[Banned Players|Multiple Bans]]'
		table.insert(statusContents, banned)
	end

	return Array.extendWith(statusContents,
		Array.map(self:getAllArgsForBase(args, 'banned'),
			function(item, _)
				return BANNED[string.lower(item)]
			end
		)
	)
end

return CustomPlayer
