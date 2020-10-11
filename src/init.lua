local HttpService = game:GetService("HttpService")

local InputStream = require(script.InputStream)
local Lexer = require(script.Lexer)
local Parser = require(script.Parser)

local program = [[
cmd string_arg string_arg rest string arg

$variable = 5

cmd string $variable here; cmd 1234

cmd string {expr}

# cmd list,example
# cmd "li,st",example
# cmd (list, example)

if 1 == 2 {

}

]]

--[[
	elif 3 == 4{

} else {

}

while 1 == 2 {
	# do stuff
}

func die
	victim player Victim The reason we're here
	param2 string Reason The reason you did it
{
	kill $victim
	message $reason
}
]]

local stream = InputStream.new(program)
local lexer = Lexer.new(stream)
local parser = Parser.new(lexer)

print(HttpService:JSONEncode(parser:parse()))

return {}