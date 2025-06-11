---
-- @Liquipedia
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
local Region = require('Module:Region')
local SignaturePlayerAgents = require('Module:SignaturePlayerAgents')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

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
			Cell{
				name = 'Years Active (' .. Abbreviation.make{text = 'Org', title = 'Organisation'} .. ')',
				content = {args.years_active_org}
			},
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

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	Array.forEach(args.agents, function (agent, index)
		lpdbData.extradata['agent' .. index] = agent
	end)

	lpdbData.region = Region.name({region = args.region, country = args.country})

	return lpdbData
end

---@return Widget?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
		return HtmlWidgets.Fragment{
			children = {
				MatchTicker.player{recentLimit = 3},
				UpcomingTournaments{name = teamPage}
			}
		}
	end
end

return CustomPlayer
