---
-- @Liquipedia
-- wiki=rainbowsix
-- page=Module:Infobox/Character/Custom
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

local Array = require('Module:Array')
local Class = require('Module:Class')
local FnUtil = require('Module:FnUtil')
local Image = require('Module:Image')
local Logic = require('Module:Logic')
local Lua = require('Module:Lua')

local AgeCalculation = Lua.import('Module:AgeCalculation')
local CharacterIcon = Lua.import('Module:CharacterIcon')
local NameAliases = Lua.requireIfExists('Module:CharacterNames', {loadData = true})

local Injector = Lua.import('Module:Widget/Injector')
local Character = Lua.import('Module:Infobox/Character')

local Widgets = Lua.import('Module:Widget/All')
local HtmlWidgets = Lua.import('Module:Widget/Html/All')
local Cell = Widgets.Cell
local IconFa = Lua.import('Module:Widget/Image/Icon/Fontawesome')
local IconImageWidget = Lua.import('Module:Widget/Image/Icon/Image')
local Link = Lua.import('Module:Widget/Basic/Link')
local Title = Widgets.Title
local WidgetUtil = Lua.import('Module:Widget/Util')

local TEAM_ATTACK = HtmlWidgets.Fragment{
	children = {
		IconImageWidget{
			imageLight = 'R6S Para Bellum atk logo.png',
			link = '',
			size = '14px'
		},
		' Attack'
	}
}
local TEAM_DEFENSE = HtmlWidgets.Fragment{
	children = {
		IconImageWidget{
			imageLight = 'R6S Para Bellum def logo.png',
			link = '',
			size = '14px'
		},
		' Defense'
	}
}

---@param label string
---@return Widget
local function createPriceLabel(label)
	return HtmlWidgets.Sup{
		children = {
			HtmlWidgets.Span{
				classes = { 'elm-bg' },
				css = {
					['font-family'] = 'monospace',
					['font-weight'] = 'bold',
					padding = '0 1px'
				},
				children = { label }
			}
		}
	}
end
local STANDARD_EDITION_LABEL = createPriceLabel('SE')
local SEASON_PASS_LABEL = createPriceLabel('SP')

local OPERATOR_PRICES = {
	launch = {
		renown = 0,
		credit = 300
	},
	['36m'] = {
		renown = 10000,
		credit = 240
	},
	['24m'] = {
		renown = 15000,
		credit = 360
	},
	['12m'] = {
		renown = 20000,
		credit = 480
	},
	['0m'] = {
		renown = 25000,
		credit = 600
	}
}
OPERATOR_PRICES['36 months'] = OPERATOR_PRICES['36m']
OPERATOR_PRICES['24 months'] = OPERATOR_PRICES['24m']
OPERATOR_PRICES['12 months'] = OPERATOR_PRICES['12m']
OPERATOR_PRICES['0 months'] = OPERATOR_PRICES['0m']

---@class RainbowsixHeroInfobox: CharacterInfobox
local CustomCharacter = Class.new(Character)
local CustomInjector = Class.new(Injector)

---@param frame Frame
---@return Html
function CustomCharacter.run(frame)
	local character = CustomCharacter(frame)
	character:setWidgetInjector(CustomInjector(character))
	character.args.informationType = 'Operator'
	return character:createInfobox()
end

---@param id string
---@param widgets Widget[]
---@return Widget[]
function CustomInjector:parse(id, widgets)
	local args = self.caller.args
	if id == 'country' then
		local ageCalculationSuccess, age = pcall(AgeCalculation.run, {
			birthdate = args.birthdate,
			birthlocation = args.birthplace,
		})

		return ageCalculationSuccess and {
			Cell{name = 'Born', content = {age.birth}},
		} or {}
	elseif id == 'role' then
		return WidgetUtil.collect(
			Cell{
				name = 'Team',
				children = self.caller:_getTeam(args)
			},
			Cell{
				name = 'Operator Role',
				content = self.caller:getAllArgsForBase(args, 'function'),
				options = { makeLink = true }
			}
		)
	elseif id == 'class' then
		return {
			Cell{
				name = 'Team Rainbow',
				content = self.caller:_getTeamRainbow(args),
				options = { separator = ' ' }
			},
			Cell{
				name = 'Affiliation',
				content = { args.affiliation }
			}
		}
	elseif id == 'release' then
		if Logic.isEmpty(args.releasedate) then
			return {}
		end
		local patchData = mw.ext.LiquipediaDB.lpdb('datapoint', {
			conditions = '[[type::patch]] AND [[date::'.. args.releasedate ..']]',
		})[1]

		return {
			Cell{
				name = 'Release Date',
				content = WidgetUtil.collect(
					args.releasedate,
					Logic.isNotEmpty(patchData) and Link{
						link = patchData.pagename,
						children = patchData.name
					} or 'Launch'
				)
			}
		}
	elseif id == 'custom' then
		return WidgetUtil.collect(
			self.caller:_getAdditionalInfo(args)
		)
	end

	return widgets
end

---@return Widget[]
function CustomCharacter:_getTeam(args)
	local team = (args.team or ''):lower()
	if team == 'attack' or team == 'atk' then
		return { TEAM_ATTACK }
	elseif team == 'defense' or team == 'def' then
		return { TEAM_DEFENSE }
	elseif team == 'both' then
		return { TEAM_ATTACK, TEAM_DEFENSE }
	else
		return {}
	end
end

---@return (Widget|string)[]
function CustomCharacter:_getTeamRainbow(args)
	local teamRainbow = (args['team rainbow'] or ''):lower()
	if teamRainbow == 'wolfguard' then
		return self:_buildTeamRainbowWidgets('Wolfguard', true)
	elseif teamRainbow == 'nighthaven' then
		return self:_buildTeamRainbowWidgets('Nighthaven')
	elseif teamRainbow == 'ghosteyes' then
		return self:_buildTeamRainbowWidgets('Ghosteyes')
	elseif teamRainbow == 'redhammer' then
		return self:_buildTeamRainbowWidgets('Redhammer')
	elseif teamRainbow == 'viperstrike' then
		return self:_buildTeamRainbowWidgets('Viperstrike', true)
	else
		return {}
	end
end

---@param teamName string
---@param allmode boolean?
---@return (Widget|string)[]
function CustomCharacter:_buildTeamRainbowWidgets(teamName, allmode)
	return {
		IconImageWidget{
			imageLight = 'R6S Squad ' .. teamName .. ' ' .. (allmode and 'allmode' or 'lightmode') .. '.png',
			imageDark = 'R6S Squad ' .. teamName .. ' ' .. (allmode and 'allmode' or 'darkmode') .. '.png',
			link = teamName
		},
		teamName
	}
end

---@param args table<string, any>
---@return Widget[]
function CustomCharacter:_getAdditionalInfo(args)
	return WidgetUtil.collect(
		Logic.isNotEmpty(args.height) and Cell{
			name = 'Height',
			content = { args.height, 'm' },
			options = { separator = ' ' }
		} or nil,
		Logic.isNotEmpty(args.weight) and Cell{
			name = 'Height',
			content = { args.weight, 'kg' },
			options = { separator = ' ' }
		} or nil,
		Logic.isNotEmpty(args.voice) and Cell{
			name = 'Voiced by',
			content = { args.voice }
		} or nil,
		self:_getPriceCells(args.renownprice or args.creditprice),
		Cell{
			name = 'Has Elite Skin',
			content = WidgetUtil.collect(
				HtmlWidgets.Fragment{
					children = Logic.readBool(args.eliteskin) and {
						IconFa{ iconName = 'yes', color = 'forest-green-text' },
						' ',
						HtmlWidgets.I{
							css = {
								['padding-left'] = '2px',
								['vertical-align'] = '-1px'
							},
							children = { 'Yes' }
						}
					} or {
						IconFa{ iconName = 'no', color = 'cinnabar-text' },
						' ',
						HtmlWidgets.I{
							css = {
								['padding-left'] = '2px',
								['vertical-align'] = '-1px'
							},
							children = { 'No' }
						}
					}
				},
				Logic.isNotEmpty(args['eliteskin-date']) and HtmlWidgets.I{
					children = {
						HtmlWidgets.Small{
							children = { args['eliteskin-date'] }
						}
					}
				} or nil
			)
		},
		Cell{
			name = 'Availability',
			content = { args.availability }
		}
	)
end

---@param input string
---@return Widget[]|nil
function CustomCharacter:_getPriceCells(input)
	local lowerInput = input:lower()
	if (lowerInput == 'launch') then
		local lang = mw.getContentLanguage()
		return {
			Cell{
				name = 'Renown price',
				content = WidgetUtil.collect(
					'Free',
					Array.map({ 500, 1000, 1500, 2000 }, function (renownPrice)
						return HtmlWidgets.Fragment{
							children = {
								lang:formatNum(renownPrice),
								' ',
								STANDARD_EDITION_LABEL
							}
						}
					end),
					HtmlWidgets.Fragment{
						children = {
							'10% off ',
							SEASON_PASS_LABEL
						}
					}
				),
			},
			self:_getPriceCell('Renown', OPERATOR_PRICES.launch.credit)
		}
	elseif Logic.isNotEmpty(OPERATOR_PRICES[lowerInput]) then
		local priceData = OPERATOR_PRICES[lowerInput]
		return {
			self:_getPriceCell('Renown', priceData.renown),
			self:_getPriceCell('R6 Credit', priceData.credit)
		}
	end
	return nil
end

---@param currency string
---@param price integer
---@return Widget
function CustomCharacter:_getPriceCell(currency, price)
	local lang = mw.getContentLanguage()
	return Cell{
		name = currency .. ' price',
		content = {
			lang:formatNum(price),
			HtmlWidgets.Fragment{
				children = {
					lang:formatNum(price * 0.9),
					' ',
					SEASON_PASS_LABEL
				}
			}
		},
	}
end

---@param args table<string, any>
---@return Widget[]
function CustomCharacter:_getBaseStats(args)
	return WidgetUtil.collect(
		Title{ children = 'Base Stats' },
		Cell{
			name = 'Armor/Health',
			content = self:_getArmorContent((args.armor or ''):lower()),
			options = { separator = ' ' }
		},
		Cell{
			name = 'Speed',
			content = self:_getSpeedContent((args.speed or ''):lower()),
			options = { separator = ' ' }
		},
		Cell{
			name = 'Difficulty',
			content = self:_getArmorContent((args.difficulty or ''):lower()),
			options = { separator = ' ' }
		}
	)
end

---@param armor string
---@return (string|Widget)[]
function CustomCharacter:_getArmorContent(armor)
	local armorContent = FnUtil.curry(CustomCharacter._getStatContent, 'armor')
	local armorEq = FnUtil.curry(FnUtil.eq, armor)
	if Array.any({'1', 'light', 'low'}, armorEq) then
		return armorContent(1, 'Light (100 HP)')
	elseif Array.any({'2', 'medium'}, armorEq) then
		return armorContent(2, 'Medium (110 HP)')
	elseif Array.any({'3', 'slow', 'high'}, armorEq) then
		return armorContent(3, 'Heavy (125 HP)')
	end
	return {}
end

---@param speed string
---@return (string|Widget)[]
function CustomCharacter:_getSpeedContent(speed)
	local speedContent = FnUtil.curry(CustomCharacter._getStatContent, 'speed')
	local speedEq = FnUtil.curry(FnUtil.eq, speed)
	if Array.any({'1', 'slow', 'low'}, speedEq) then
		return speedContent(1, 'Light (100 HP)')
	elseif Array.any({'2', 'medium'}, speedEq) then
		return speedContent(2, 'Medium (110 HP)')
	elseif Array.any({'3', 'fast', 'high'}, speedEq) then
		return speedContent(3, 'Heavy (125 HP)')
	end
	return {}
end

---@param difficulty string
---@return (string|Widget)[]
function CustomCharacter:_getDifficultyContent(difficulty)
	local difficultyContent = FnUtil.curry(CustomCharacter._getStatContent, 'armor')
	local difficultyEq = FnUtil.curry(FnUtil.eq, difficulty)
	if Array.any({'1', 'easy', 'low'}, difficultyEq) then
		return difficultyContent(1, 'Easy')
	elseif Array.any({'2', 'normal', 'medium'}, difficultyEq) then
		return difficultyContent(2, 'Medium')
	elseif Array.any({'3', 'hard', 'difficult'}, difficultyEq) then
		return difficultyContent(3, 'Hard')
	end
	return {}
end

---@param type string
---@param value string|integer
---@param display string
---@return (string|Widget)[]
function CustomCharacter._getStatContent(type, value, display)
	return {
		Image.display('R6S operator-rating-' .. type .. '-' ..  value .. '.png', nil, { size = '40x20px', link = '' }),
		HtmlWidgets.I{
			css = {
				['padding-left'] = '2px',
				['vertical-align'] = '-1px'
			},
			children = { display }
		}
	}
end

---@param args table
---@return string[]
function CustomCharacter:getWikiCategories(args)
	local categories = {}
	local speedEq = FnUtil.curry(FnUtil.eq, args.speed)
	local difficultyEq = FnUtil.curry(FnUtil.eq, args.difficulty)

	Array.extendWith(categories, Array.map(self:getAllArgsForBase(args, 'function'), function (element)
		return element .. ' Operators'
	end))

	if Array.any({'1', 'slow', 'low'}, speedEq) then
		Array.appendWith(categories, '1 Speed Operators')
	elseif Array.any({'2', 'medium'}, speedEq) then
		Array.appendWith(categories, '2 Speed Operators')
	elseif Array.any({'3', 'fast', 'high'}, speedEq) then
		Array.appendWith(categories, '3 Speed Operators')
	end

	if Array.any({'1', 'easy', 'low'}, difficultyEq) then
		Array.appendWith(categories, '1 Difficulty Operators')
	elseif Array.any({'2', 'normal', 'medium'}, difficultyEq) then
		Array.appendWith(categories, '2 Difficulty Operators')
	elseif Array.any({'3', 'hard', 'difficult'}, difficultyEq) then
		Array.appendWith(categories, '3 Difficulty Operators')
	end

	return categories
end

---@param args table
---@return string?
function CustomCharacter:nameDisplay(args)
	return CharacterIcon.Icon{
		character = NameAliases[args.name:lower()],
		size = '50px'
	} .. ' ' .. args.name
end

return CustomCharacter
