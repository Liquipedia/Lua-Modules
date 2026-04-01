---
-- @Liquipedia
-- page=Module:BracketAlias
--
-- Please see https://github.com/Liquipedia/Lua-Modules to contribute
--

--[[
Alias List for Brackets (for the Generator Special:RunQuery)
please keep the keys (the entries inside the [] brackets) all lower case
If you need custom Aliases for your wiki copy this module over and append it there
]]--

return {
	--section with appended "Bracket"
	--SE
	['2sebracket'] = '2',
	['4sebracket'] = '4',
	['6sebracket'] = '4L2DS',
	['8sebracket'] = '8',
	['12sebracket'] = '8L4DSS',
	['16sebracket'] = '16',
	['24sebracket'] = '16L8DSSS',
	['32sebracket'] = '32',
	['64sebracket'] = '64',
	--DE
	['4debracket'] = '4U2L1D',
	['8debracket'] = '8U4L2DSL1D',
	['16debracket'] = '16U8L4DSL2DSL1D',
	['32debracket'] = '32U16L8DSL4DSL2DSL1D',
	--qual_SE
	['1qual-2sebracket'] = '2-1Q',
	['1qual-4sebracket'] = '4-1Q',
	['1qual-8sebracket'] = '8-1Q',
	['1qual-16sebracket'] = '16-1Q',
	['1qual-32sebracket'] = '32-1Q',
	['2qual-4sebracket'] = '4-2Q',
	['2qual-8sebracket'] = '8-2Q',
	['2qual-16sebracket'] = '16-2Q',
	['3qual-6sebracket'] = '4-2Q-2-1Q',
	['3qual-8sebracket'] = '8-2Q-U-2-1Q',
	['3qual-16sebracket'] = '16-2Q-U-2-1Q',
	['4qual-8sebracket'] = '8-4Q',
	['4qual-16sebracket'] = '16-4Q',
	['4qual-32sebracket'] = '32-4Q',
	['6qual-12sebracket'] = '8-4Q-4-2Q',
	['8qual-16sebracket'] = '16-8Q',
	['8qual-32sebracket'] = '32-8Q',
	['8qual-64sebracket'] = '64-8Q',
	['16qual-32sebracket'] = '32-16Q',
	['16qual-64sebracket'] = '64-16Q',
	--qual_DE
	['1qual-4debracket'] = '4U2L1D-1Q',
	['1qual-8debracket'] = '8U4L2DSL1D-1Q',
	['2qual-4debracket'] = '4-1Q-U-2L1D-1Q',
	['2qual-8debracket'] = '8-1Q-U-4L2DSL1D-1Q',
	['2qual-16debracket'] = '16-1Q-U-8L4DSL2DSL1D-1Q',
	['3qual-16debracket'] = '16-2Q-U-8L4DSL2DS-1Q',
	['3qual-4debracket'] = '4-2Q-U-2-1Q',
	['3qual-8debracket'] = '8-2Q-U-4L2DS-1Q',
	['4qual-8debracket'] = '8-2Q-U-4L2D-2Q',
	['4qual-16debracket'] = '16-2Q-U-8L4DSL2D-2Q',
	['4qual-32debracket'] = '32-2Q-U-16L8DSL4DSL2D-2Q',
	['6qual-8debracket'] = '8-4Q-U-4-2Q',
	['6qual-16debracket'] = '16-4Q-U-8L4DS-2Q',
	['6qual-64debracket'] = '64-4Q-U-32L16DSL8DSL4DS-2Q',
	['8qual-8debracket'] = '8-4Q-U-8-4Q',
	['8qual-16debracket'] = '16-4Q-U-8L4D-4Q',
	['8qual-32debracket'] = '32-4Q-U-16L8DSL4D-4Q',
	['8qual-64debracket'] = '64-4Q-U-32L16DSL8DSL4D-4Q',
	['16qual-32debracket'] = '32-8Q-U-16L8D-8Q',

	--section WITHOUT appended "Bracket"
	--SE
	['2se'] = '2',
	['4se'] = '4',
	['6se'] = '4L2DS',
	['8se'] = '8',
	['12se'] = '8L4DSS',
	['16se'] = '16',
	['24se'] = '16L8DSSS',
	['32se'] = '32',
	['64se'] = '64',
	--DE
	['4de'] = '4U2L1D',
	['8de'] = '8U4L2DSL1D',
	['16de'] = '16U8L4DSL2DSL1D',
	['32de'] = '32U16L8DSL4DSL2DSL1D',
	--qual_SE
	['1qual-2se'] = '2-1Q',
	['1qual-4se'] = '4-1Q',
	['1qual-8se'] = '8-1Q',
	['1qual-16se'] = '16-1Q',
	['1qual-32se'] = '32-1Q',
	['2qual-4se'] = '4-2Q',
	['2qual-8se'] = '8-2Q',
	['2qual-16se'] = '16-2Q',
	['3qual-6se'] = '4-2Q-2-1Q',
	['3qual-8se'] = '8-2Q-U-2-1Q',
	['3qual-16se'] = '16-2Q-U-2-1Q',
	['4qual-8se'] = '8-4Q',
	['4qual-16se'] = '16-4Q',
	['4qual-32se'] = '32-4Q',
	['6qual-12se'] = '8-4Q-4-2Q',
	['8qual-16se'] = '16-8Q',
	['8qual-32se'] = '32-8Q',
	['8qual-64se'] = '64-8Q',
	['16qual-32se'] = '32-16Q',
	['16qual-64se'] = '64-16Q',
	--qual_DE
	['1qual-4de'] = '4U2L1D-1Q',
	['1qual-8de'] = '8U4L2DSL1D-1Q',
	['2qual-4de'] = '4-1Q-U-2L1D-1Q',
	['2qual-8de'] = '8-1Q-U-4L2DSL1D-1Q',
	['2qual-16de'] = '16-1Q-U-8L4DSL2DSL1D-1Q',
	['3qual-16de'] = '16-2Q-U-8L4DSL2DS-1Q',
	['3qual-4de'] = '4-2Q-U-2-1Q',
	['3qual-8de'] = '8-2Q-U-4L2DS-1Q',
	['4qual-8de'] = '8-2Q-U-4L2D-2Q',
	['4qual-16de'] = '16-2Q-U-8L4DSL2D-2Q',
	['4qual-32de'] = '32-2Q-U-16L8DSL4DSL2D-2Q',
	['6qual-8de'] = '8-4Q-U-4-2Q',
	['6qual-16de'] = '16-4Q-U-8L4DS-2Q',
	['6qual-64de'] = '64-4Q-U-32L16DSL8DSL4DS-2Q',
	['8qual-8de'] = '8-4Q-U-8-4Q',
	['8qual-16de'] = '16-4Q-U-8L4D-4Q',
	['8qual-32de'] = '32-4Q-U-16L8DSL4D-4Q',
	['8qual-64de'] = '64-4Q-U-32L16DSL8DSL4D-4Q',
	['16qual-32de'] = '32-8Q-U-16L8D-8Q',
}
