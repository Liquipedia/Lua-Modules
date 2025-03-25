---
-- @Liquipedia
-- wiki=valorant
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Abbreviation = require('Module:Abbreviation')
local Array = require('Module:Array')
local CharacterIcon = require('Module:CharacterIcon')
local Class = require('Module:Class')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')
local Page = require('Module:Page')
local Region = require('Module:Region')
local SignaturePlayerAgents = require('Module:SignaturePlayerAgents')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Template = require('Module:Template')
local Variables = require('Module:Variables')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local BANNED = mw.loadData('Module:Banned')

local SIZE_AGENT = '20px'

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{
		convertrole = true,
		addlpdbdata = true,
		specialRoles = player.args.historySpecialRoles
	}
	player.args.autoTeam = true
	player.args.agents = SignaturePlayerAgents.get{player = player.pagename, top = 3}

	return player:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local caller = self.caller
	local args = caller.args

	if id == 'custom' then
		local icons = Array.map(args.agents, function(agent)
			return CharacterIcon.Icon{character = agent, size = SIZE_AGENT}
		end)
		return {
			Cell{name = 'Signature Agent' .. (#icons > 1 and 's' or ''), content = {table.concat(icons, '&nbsp;')}}
		}
	elseif id == 'status' then
		Array.appendWith(widgets,
			Cell{name = 'Years Active (Player)', content = {args.years_active}},
			Cell{name = 'Years Active (' .. Abbreviation.make('Org', 'Organisation') .. ')', content = {args.years_active_org}},
			Cell{name = 'Years Active (Coach)', content = {args.years_active_coach}},
			Cell{name = 'Years Active (Talent)', content = {args.years_active_talent}}
		)

	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	elseif id == 'region' then
		return {}
	end
	return widgets
end

---@param categories string[]
---@return string[]
function CustomPlayer:getWikiCategories(categories)
	return Array.append(categories,
		(self.role or {}).category,
		(self.role2 or {}).category
	)
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	lpdbData.extradata.role = (self.role or {}).variable
	lpdbData.extradata.role2 = (self.role2 or {}).variable
	lpdbData.extradata.isplayer = CustomPlayer._isNotPlayer(args.role) and 'false' or 'true'

	Array.forEach(args.agents, function (agent, index)
		lpdbData.extradata['agent' .. index] = agent
	end)

	lpdbData.region = Region.name({region = args.region, country = args.country})

	return lpdbData
end

---@return string?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
		return
			tostring(MatchTicker.player{recentLimit = 3}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
end

return CustomPlayer
