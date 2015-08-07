local os = require('os')
local command = arg[1]
local ok = false
local handler, result

if command then
	ok, handler = pcall(require, "levee.cmd." .. command)
end

if not ok then
	print("unkown sub-command")
	os.exit(1)
end

ok, result = pcall(handler, {unpack(arg,2)})
if not ok then
	print(result)
	os.exit(1)
end
