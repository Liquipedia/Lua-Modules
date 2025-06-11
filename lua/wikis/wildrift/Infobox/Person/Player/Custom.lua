---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local ChampionNames = mw.loadData('Module:ChampionNames')
local CharacterIcon = require('Module:CharacterIcon')
local Lua = require('Module:Lua')
local Page = require('Module:Page')
local String = require('Module:StringUtils')
local Team = require('Module:Team')
local TeamHistoryAuto = require('Module:TeamHistoryAuto')
local Template = require('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = require('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_CHAMPION = '25x25px'

local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	if String.isEmpty(player.args.history) then
		player.args.history = TeamHistoryAuto.results{addlpdbdata = true}
	end
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
		-- Signature Champion
		local championIcons = Array.map(caller:getAllArgsForBase(args, 'champion'), function(champion)
			return CharacterIcon.Icon{character = ChampionNames[champion:lower()], size = SIZE_CHAMPION}
		end)
		return {Cell{
			name = #championIcons > 1 and 'Signature Champions' or 'Signature Champions',
			content = {table.concat(championIcons, '&nbsp;')},
		}}
	elseif id == 'status' then
		local status = args.status and mw.getContentLanguage():ucfirst(args.status) or nil

		return {
			Cell{name = 'Status', content = {Page.makeInternalLink({onlyIfExists = true}, status) or status}},
		}
	elseif id == 'history' then
		table.insert(widgets, Cell{name = 'Retired', content = {args.retired}})
	end
	return widgets
end

---@param lpdbData table
---@param args table
---@param personType string
---@return table
function CustomPlayer:adjustLPDB(lpdbData, args, personType)
	for index, champion in ipairs(self:getAllArgsForBase(args, 'champion')) do
		lpdbData.extradata['signatureChampion' .. index] = ChampionNames[champion:lower()]
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
		local teamPage = Team.page(mw.getCurrentFrame(), self.args.team)
		return
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing matches of', {team = teamPage}) ..
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
end

return CustomPlayer
