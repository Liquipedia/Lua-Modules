package.path = "../../standard/?.lua;" .. package.path
local MathUtil = require('math_util')

print(MathUtil.sum({ 2, 3 }))
