--- Triple Comment to Enable our LLS Plugin
describe('match2', function()
	insulate('matchlist', function()
		local Json = require('Module:Json')

		before_each(function ()
			local dataSaved, dataSavedOpponent, dataSavedPlayer, dataSavedGame = {}, {}, {}, {}
			-- Mock the lpdb functions
			stub(mw.ext.LiquipediaDB, "lpdb_match2", function (objName, data)
				dataSaved = data
			end)
			stub(mw.ext.LiquipediaDB, "lpdb_match2opponent", function(objName, data)
				data.match2players = dataSavedPlayer
				dataSavedPlayer = {}
				table.insert(dataSavedOpponent, data)
				return objName
			end)
			stub(mw.ext.LiquipediaDB, "lpdb_match2player", function(objName, data)
				table.insert(dataSavedPlayer, data)
				return objName
			end)
			stub(mw.ext.LiquipediaDB, "lpdb_match2game", function(objName, data)
				table.insert(dataSavedGame, data)
				return objName
			end)
			stub(mw.ext.LiquipediaDB, "lpdb", function(tbl)
				if tbl == 'match2' then
					dataSaved.extradata = Json.parse(dataSaved.extradata)
					dataSaved.match2bracketdata = Json.parse(dataSaved.match2bracketdata)
					dataSaved.match2opponents = dataSavedOpponent
					dataSaved.match2games = dataSavedGame

					local ret = {dataSaved}
					dataSaved, dataSavedGame, dataSavedOpponent = {}, {}, {}
					return ret
				end
				return {}
			end)
		end)

		after_each(function ()
			-- Restore the original lpdb function
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_match2:revert()
			---@diagnostic disable-next-line: undefined-field
			mw.ext.LiquipediaDB.lpdb_match2opponent:revert()
			mw.ext.LiquipediaDB.lpdb_match2player:revert()
			mw.ext.LiquipediaDB.lpdb_match2game:revert()
		end)
		allwikis('smoketest', function(args, wikiName)
			local Info = require('Module:Info')
			if Info.config.match2.status == 0 then
				return
			end
			local MatchGroup = require('Module:MatchGroup')
			local Match = require('Module:Match')
			local props = require('Module:Table').deepCopy(args)
			props.input.M1 = Match.makeEncodedJson(props.input.matches[1])
			props.input.id = (wikiName .. '1234567890'):sub(1, 10)
			GoldenTest('match2_matchlist_smoke_' .. wikiName, tostring(MatchGroup.TemplateMatchlist(props.input)))

		end, {
			default = {
				input = {
					storeMatch1 = false, storePageVar = false,
					matches = {
						{
							date = '2022-01-05',
							comment = 'A Match Comment',
							opponent1 = Json.stringify{name = 'A', link='abc', score = 3, type = 'solo'},
							opponent2 = Json.stringify{name = 'B', score = 2, type = 'solo'},
						}
					},
				}
			}
		})
	end)
end)
