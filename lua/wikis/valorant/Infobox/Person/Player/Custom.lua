---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Abbreviation = Lua.import('Module:Abbreviation')
local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local Class = Lua.import('Module:Class')
local Logic = Lua.import('Module:Logic')
local MatchTicker = Lua.import('Module:MatchTicker/Custom')
local PlayerIntroduction = Lua.import('Module:PlayerIntroduction/Custom')
local Region = Lua.import('Module:Region')
local SignaturePlayerAgents = Lua.import('Module:SignaturePlayerAgents')
local String = Lua.import('Module:StringUtils')
local Team = Lua.import('Module:Team')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
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
	local args = player.args
	player:setWidgetInjector(CustomInjector(player))

	args.history = TeamHistoryAuto.results{
		convertrole = true,
		addlpdbdata = true,
		specialRoles = args.historySpecialRoles
	}
	args.autoTeam = true
	args.agents = SignaturePlayerAgents.get{player = player.pagename, top = 3}

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			player = player.pagename,
			team = args.team,
			name = args.romanized_name or args.name,
			firstname = args.first_name,
			lastname = args.last_name,
			status = args.status,
			type = player:getPersonType(args).store,
			roles = player._getKeysOfRoles(player.roles),
			id = args.id,
			idIPA = args.idIPA,
			idAudio = args.idAudio,
			birthdate = player.age.birthDateIso,
			deathdate = player.age.deathDateIso,
			nationality = args.country,
			nationality2 = args.country2,
			nationality3 = args.country3,
			subtext = args.subtext,
			freetext = args.freetext,
		}
	end

	return mw.html.create()
		:node(builtInfobox)
		:node(autoPlayerIntro)
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
