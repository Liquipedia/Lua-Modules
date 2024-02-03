---
-- @Liquipedia
-- wiki=leagueoflegends
-- page=Module:ChampionMatchTable/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Arguments = require('Module:Arguments')
local ChampionIcon = require('Module:ChampionIcon')
local Class = require('Module:Class')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')
local Table = require('Module:Table')

local ChampionMatchTable = Lua.import('Module:ChampionMatchTable')

local Condition = require('Module:Condition')
local ConditionTree = Condition.Tree
local ConditionNode = Condition.Node
local Comparator = Condition.Comparator
local BooleanOperator = Condition.BooleanOperator
local ColumnName = Condition.ColumnName

local MAX_NUMBER_OF_OPPONENTS = 2
local MAX_NUMBER_OF_PLAYERS = 5
local CHAMPION_NOT_FOUND = 0

---@class CustomChampionMatchTable: ChampionMatchTable
local CustomChampionMatchTable = Class.new(ChampionMatchTable)

---@param record GameRecord
---@return integer
function CustomChampionMatchTable:findWhoPickedChampion(record)
	for oppIndex = 1, MAX_NUMBER_OF_OPPONENTS do
		for _, champion in Table.iter.pairsByPrefix(record.extradata, 'team' .. oppIndex .. 'champion') do
			if champion == self.champion then
				return oppIndex
			end
		end
	end

	return CHAMPION_NOT_FOUND
end

---@return ConditionTree?
function CustomChampionMatchTable:buildChampionConditions()
	local championConditions = ConditionTree(BooleanOperator.any)
	local champion = self.champion
	for oppIndex = 1, MAX_NUMBER_OF_OPPONENTS do
		for pIndex = 1, MAX_NUMBER_OF_PLAYERS do
			championConditions:add(ConditionNode(
				ColumnName('team' .. oppIndex .. 'champion' .. pIndex, 'extradata'),
				Comparator.eq,
				champion)
			)
		end
	end

	return championConditions
end

---@param opponent match2opponent
---@param oppIndex number
---@param game GameRecord
---@param flipped boolean?
---@return Html
function CustomChampionMatchTable:buildOpponentCell(opponent, oppIndex, game, flipped)
	local teamSide = game.extradata['team' .. oppIndex .. 'side']
	local championWrapper = mw.html.create('div')
		:addClass(Logic.isNotEmpty(teamSide) and 'brkts-popup-side-color-' .. teamSide or nil)
		:css('display', 'flex')

	for _, champion in Table.iter.pairsByPrefix(game.extradata, 'team' .. oppIndex .. 'champion') do
		championWrapper:node(ChampionIcon._getImage{champion, date = game.date, size = '26x26px'})
	end

	local wrapper = mw.html.create('div')
		:css('display', 'flex')
		:css('flex-direction', flipped and 'row-reverse' or nil)

	wrapper:node(championWrapper)
	wrapper:node(self:getOpponentDiplay(opponent, flipped))

	return mw.html.create('td')
		:node(wrapper)
end

---@param game GameRecord
---@return Html
function CustomChampionMatchTable:buildScoreCell(game)
	return mw.html.create('td')
		:wikitext(game.winner == game.pickedBy and "'''1''' : 0" or "0 : '''1'''")
end

---@return Html
function CustomChampionMatchTable.run(frame)
	local championMatches = CustomChampionMatchTable(Arguments.getArgs(frame))
	championMatches:readConfig()
	championMatches:query()
	return championMatches:build()
end

return CustomChampionMatchTable
