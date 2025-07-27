---
-- @Liquipedia
-- page=Module:Infobox/Person/Player/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local CharacterNames = Lua.import('Module:CharacterNames', {loadData = true})
local Class = Lua.import('Module:Class')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Team = Lua.import('Module:Team')
local TeamHistoryAuto = Lua.import('Module:TeamHistoryAuto')
local Template = Lua.import('Module:Template')

local Injector = Lua.import('Module:Widget/Injector')
local Player = Lua.import('Module:Infobox/Person')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell

local SIZE_HERO = '25x25px'

---@class NarakaInfoboxPlayer: Person
local CustomPlayer = Class.new(Player)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomPlayer.run(frame)
	local player = CustomPlayer(frame)
	player:setWidgetInjector(CustomInjector(player))

	player.args.history = TeamHistoryAuto.results{addlpdbdata = true}
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
		local heroIcons = Array.map(caller:getAllArgsForBase(args, 'hero'), function(hero, _)
			return CharacterIcon.Icon{character = CharacterNames[hero:lower()], size = SIZE_HERO}
		end)

		return {
			Cell{
				name = #heroIcons > 1 and 'Signature Heroes' or 'Signature Hero',
				content = {table.concat(heroIcons, '&nbsp;')},
			}
		}
	elseif id == 'region' then
		return {}
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
	for _, hero, heroIndex in Table.iter.pairsByPrefix(args, 'hero', {requireIndex = false}) do
		lpdbData.extradata['signatureHero' .. heroIndex] = CharacterNames[hero:lower()]
	end

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
			Template.safeExpand(mw.getCurrentFrame(), 'Upcoming and ongoing tournaments of', {team = teamPage})
	end
end

return CustomPlayer
