---
-- @Liquipedia
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local BrawlerWinLoss = Lua.import('Module:BrawlerWinLoss')
local BrawlerPickBan = Lua.import('Module:BrawlerPickBan')
local Class = Lua.import('Module:Class')
local Flags = Lua.import('Module:Flags')
local Math = Lua.import('Module:MathUtil')
local Table = Lua.import('Module:Table')

local Character = Lua.import('Module:Infobox/Character')
local Injector = Lua.import('Module:Widget/Injector')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Title = Widgets.Title

---@class BrawlStarsChampionInfobox: CharacterInfobox
---@operator call(Frame): BrawlStarsChampionInfobox
local CustomCharacter = Class.new(Character)

---@class BrawlStarsChampionInfoboxWidgetInjector: WidgetInjector
---@operator call(BrawlStarsChampionInfobox): BrawlStarsChampionInfoboxWidgetInjector
---@field caller BrawlStarsChampionInfobox
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Renderable
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Brawler'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'role' then
		return {
			Cell{name = 'Rarity', children = {args.rarity}},
		}
	elseif id == 'custom' then
		Array.appendWith(widgets, self.caller:_getTypeCells())
		widgets = self.caller:_getEsportsStats(widgets)
	end

	return widgets
end

---@return Widget[]
function CustomCharacter:_getTypeCells()
	local args = self.args
	return {
		Cell{name = 'Voice Actor(s)', children = self:_getVoiceActors()},
		Cell{name = 'Price', children = {args.price}},
		Cell{name = 'Health', children = {args.hp}},
		Cell{name = 'Movespeed', children = {args.movespeed}},
		Title{children = 'Weapon & Super'},
		Cell{name = 'Primary Weapon', children = {args.attack}},
		Cell{name = 'Super Ability', children = {args.super}},
		Title{children = 'Abilities'},
		Cell{name = 'Traits', children = {args.trait}},
		Cell{name = 'Gadgets', children = {args.gadget}},
		Cell{name = 'Star Powers', children = {args.star}},
		Cell{name = 'Hypercharge', children = {args.hypercharge}},
		Cell{name = 'Buffies', children = {args.buffies}}
	}
end

---@param widgets Widget[]
---@return Widget[]
function CustomCharacter:_getEsportsStats(widgets)
	local args = self.args
	local wins, loses = BrawlerWinLoss.run(args.name)
	if wins + loses == 0 then return widgets end

	local winPercentage = Math.formatPercentage(wins / (wins + loses), 2)
	local picks, bans, totalGames = BrawlerPickBan.run(args.name)
	local pickPercentage = totalGames > 0 and Math.formatPercentage(picks / totalGames, 2) or 0
	local banPercentage = totalGames > 0 and Math.formatPercentage(bans / totalGames, 2) or 0

	return Array.append(widgets,
		Title{children = '<abbr title="Last 365 days">Esports Statistics</abbr>'},
		Cell{name = 'Win Rate', children = {wins .. 'W : ' .. loses .. 'L (' .. winPercentage .. ')'}},
		Cell{name = 'Pick Rate', children = {picks .. ' (' .. pickPercentage .. ')'}},
		Cell{name = 'Ban Rate', children = {bans .. ' (' .. banPercentage .. ')'}}
	)
end

---@return string[]
function CustomCharacter:_getVoiceActors()
	local args = self.args
	local voiceActors = {}
	for voiceActorKey, voiceActor in Table.iter.pairsByPrefix(args, 'voice', {requireIndex = false}) do
		local flag = args[voiceActorKey .. 'flag']
		if flag then
			voiceActor = Flags.Icon{flag = flag} .. ' ' .. voiceActor
		end
		table.insert(voiceActors, voiceActor)
	end
	return voiceActors
end

---@param args table
---@return string[]
function CustomCharacter:getRoles(args)
	return {
		args.class
	}
end

---@param lpdbData table
---@param args table
---@return table
function CustomCharacter:addToLpdb(lpdbData, args)
	lpdbData.extradata = {
		rarity = args.rarity,
		price = args.price
	}
	return lpdbData
end

return CustomCharacter
