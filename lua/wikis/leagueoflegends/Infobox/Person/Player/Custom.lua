---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local MatchTicker = require('Module:MatchTicker/Custom')
local Page = require('Module:Page')
local PlayerIntroduction = require('Module:PlayerIntroduction/Custom')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local UpcomingTournaments = Lua.import('Module:Widget/Infobox/UpcomingTournaments')

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	local args = player.args
	player:setWidgetInjector(CustomInjector(player))

	args.history = String.nilIfEmpty(args.history) or TeamHistoryAuto.results{
		hiderole = true,
		iconModule = 'Module:PositionIcon/data',
		addlpdbdata = true,
	}
	args.autoTeam = true

	local builtInfobox = player:createInfobox()

	local autoPlayerIntro = ''
	if Logic.readBool((args.autoPI or ''):lower()) then
		autoPlayerIntro = PlayerIntroduction.run{
			player = player.pagename,
			team = args.team,
			name = args.romanized_name or args.name,
			first_name = args.first_name,
			last_name = args.last_name,
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
			convert_role = true,
			show_role = true,
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

	if id == 'status' then
		local status = args.status
		if String.isNotEmpty(status) then
			status = mw.getContentLanguage():ucfirst(status)
		end

		return {
			Cell{name = 'Status', content = {Page.makeInternalLink({onlyIfExists = true},
						status) or status}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{
			name = 'Retired',
			content = {args.retired}
		})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args)
	lpdbData.extradata.signatureChampion1 = args.champion1 or args.champion
	lpdbData.extradata.signatureChampion2 = args.champion2
	lpdbData.extradata.signatureChampion3 = args.champion3
	lpdbData.extradata.signatureChampion4 = args.champion4
	lpdbData.extradata.signatureChampion5 = args.champion5

	lpdbData.region = Template.safeExpand(mw.getCurrentFrame(), 'Player region', {args.country})

	if String.isNotEmpty(args.team2) then
		lpdbData.extradata.team2 = mw.ext.TeamTemplate.raw(args.team2).page
	end

	return lpdbData
end

---@return Widget?
function CustomPlayer:createBottomContent()
	if self:shouldStoreData(self.args) and String.isNotEmpty(self.args.team) then
		local teamPage = Team.page(mw.getCurrentFrame(),self.args.team)
		return HtmlWidgets.Fragment{
			children = {
				MatchTicker.participant{team = teamPage},
				UpcomingTournaments{name = teamPage}
			}
		}
	end
end

return CustomPlayer
