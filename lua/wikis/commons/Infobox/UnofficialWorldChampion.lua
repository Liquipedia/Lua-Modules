---
-- @Liquipedia
-- page=Module:Infobox/UnofficialWorldChampion
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Lua = require('Module:Lua')

local Array = Lua.import('Module:Array')
local Class = Lua.import('Module:Class')
local Info = Lua.import('Module:Info', {loadData = true})
local Json = Lua.import('Module:Json')
local Logic = Lua.import('Module:Logic')
local MatchTicker = Lua.import('Module:MatchTicker')
local Namespace = Lua.import('Module:Namespace')
local String = Lua.import('Module:StringUtils')
local Table = Lua.import('Module:Table')
local Variables = Lua.import('Module:Variables')

local Opponent = Lua.import('Module:Opponent/Custom')
local OpponentDisplay = Lua.import('Module:OpponentDisplay/Custom')

local BasicInfobox = Lua.import('Module:Infobox/Basic')

local Widgets = Lua.import('Module:Widget/All')
local Cell = Widgets.Cell
local Header = Widgets.Header
local Title = Widgets.Title
local Center = Widgets.Center
local Customizable = Widgets.Customizable
local Builder = Widgets.Builder
local Breakdown = Widgets.Breakdown
local WidgetUtil = Lua.import('Module:Widget/Util')

---@class UnofficialWorldChampionInfobox: BasicInfobox
local UnofficialWorldChampion = Class.new(BasicInfobox)

---@param frame Frame
---@return Html
function UnofficialWorldChampion.run(frame)
	local unofficialWorldChampion = UnofficialWorldChampion(frame)
	return unofficialWorldChampion:createInfobox()
end

---@return string
function UnofficialWorldChampion:createInfobox()
	local args = self.args

	args.currentChampOpponent = Opponent.readOpponentArgs(
		Json.parseIfString(args['current champion'])
	)

	self:top(self:_createUpcomingMatches())

	local widgets = {
		Header{
			name = 'Unofficial World Champion',
			image = args.image,
			imageDark = args.imagedark or args.imagedarkmode,
			size = args.imagesize,
		},
		Center{children = {args.caption}},
		Title{children = 'Current Champion'},
		Center{
			children = {
				OpponentDisplay.InlineOpponent{
					opponent = args.currentChampOpponent
				}
			},
			classes = { 'infobox-size-20', 'infobox-bold' }
		},
		Builder{
			builder = function()
				if not String.isEmpty(args['gained date']) then
					return {
						Title{children = 'Title Gained'},
						Cell{
							name = args['gained date'],
							options = { separator = ' ' },
							children = WidgetUtil.collect(
								String.nilIfEmpty(args['gained against result']),
								'vs',
								OpponentDisplay.InlineOpponent{
									opponent = self:_parseOpponentArg('gained against'),
									teamStyle = 'short'
								}
							)
						},
					}
				end
			end
		},
		Title{children = 'Most Defences'},
		Cell{
			name = (args['most defences no'] or '?') .. ' Matches',
			children = {
				OpponentDisplay.InlineOpponent{
					opponent = self:_parseOpponentArg('most defences')
				}
			},
		},
		Customizable{id = 'defences', children = {
				Builder{
					builder = function()
						return Array.map(
							self:getAllArgsForBase(args, 'most defences against '),
							function (value) return Breakdown{children = {value}} end
						)
					end
				},
			}
		},
		Title{children = 'Longest Consecutive Time as Champion'},
		Cell{
			name = (args['longest consecutive no'] or '?') .. ' days',
			children = WidgetUtil.collect(
				OpponentDisplay.InlineOpponent{
					opponent = self:_parseOpponentArg('longest consecutive')
				},
				String.nilIfEmpty(args['longest consecutive desc'])
			),
		},
		Title{children = 'Longest Total Time as Champion'},
		Cell{
			name = (args['longest total no'] or '?') .. ' days',
			children = {
				OpponentDisplay.InlineOpponent{
					opponent = self:_parseOpponentArg('longest total')
				}
			},
		},
		Title{children = 'Most Times Held'},
		Builder{
			builder = function()
				local opponents = {}
				for defenseTeamKey, _ in Table.iter.pairsByPrefix(args, 'most times held', {requireIndex = false}) do
					Array.appendWith(opponents,
						self:_parseOpponentArg(defenseTeamKey)
					)
				end
				return Cell{
					name = (args['most times held no'] or '?') .. ' times',
					children = WidgetUtil.collect(
						Array.map(opponents, function (opponent)
							return OpponentDisplay.InlineOpponent{ opponent = opponent }
						end),
						String.nilIfEmpty(args['most times held desc'])
					),
				}
			end
		},
		Customizable{
			id = 'regionaldistribution',
			children = String.isNotEmpty(args.region1) and WidgetUtil.collect(
				Title{children = 'Regional distribution'},
				self:_parseRegionalDistribution()
			) or {}
		},
		Customizable{id = 'custom', children = {}},
		Center{children = {args.footnotes}},
	}

	self:setLpdbData(args)
	return self:build(widgets, 'UnofficialWorldChampion')
end

---@private
---@param key string
---@return standardOpponent
function UnofficialWorldChampion:_parseOpponentArg(key)
	return Opponent.readOpponentArgs(
		Json.parseIfString(self.args[key]) or Opponent.tbd()
	)
end

---@private
---@return Widget[]
function UnofficialWorldChampion:_parseRegionalDistribution()
	local args = self.args
	local widgets = {}

	for regionKey, region in Table.iter.pairsByPrefix(args, 'region') do
		Array.appendWith(widgets,
			Cell{
				name = (args[regionKey .. ' no'] or '') .. ' champions',
				children = {region}
			},
			Breakdown{children = {args[regionKey .. ' champions']}}
		)
	end
	return widgets
end

---@private
---@return Widget?
function UnofficialWorldChampion:_createUpcomingMatches()
	if not self:shouldStore(self.args) then
		return nil
	end

	if Info.config.match2.status == 0 then
		return nil
	end

	local currentChampion = self.args.currentChampOpponent

	if not currentChampion or currentChampion.type ~= Opponent.team then
		return nil
	end

	if Opponent.isTbd(currentChampion) or Opponent.isEmpty(currentChampion) or Opponent.isBye(currentChampion) then
		return nil
	end

	local result = Logic.tryCatch(
		function()
			local matchTicker = MatchTicker{
				team = currentChampion.template,
				limit = 5,
				upcoming = true,
				ongoing = true,
				hideTournament = false,
				entityStyle = true,
			}
			matchTicker:query()
			return matchTicker
		end,
		function()
			return nil
		end
	)

	if not result or not result.matches or #result.matches == 0 then
		return nil
	end

	local EntityDisplay = Lua.import('Module:MatchTicker/DisplayComponents/Entity')
	return EntityDisplay.Container{
		config = result.config,
		matches = result.matches,
	}:create()
end

---@param args table
---@return boolean
function UnofficialWorldChampion:shouldStore(args)
	return Namespace.isMain() and
		not Logic.readBool(Variables.varDefault('disable_LPDB_storage'))
end

---@param args table
function UnofficialWorldChampion:setLpdbData(args)
end

return UnofficialWorldChampion
