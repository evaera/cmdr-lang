local Lexer = {}
Lexer.__index = Lexer

local KEYWORDS = {
	"if",
	"else",
	"elif",
	"fi",
	"func",
}

local function isKeyword(str)
	return table.find(KEYWORDS, str) ~= nil
end

local function isWhitespace(char)
	return char ~= "\n" and char:match("%s") ~= nil
end

local function isPunc(char)
	return string.find("(),;{}\n", char, 1, true) ~= nil
end

local function isOpChar(char)
	return string.find("+-(/%&|<>=", char, 1, true) ~= nil
end

local function isDigit(char)
	return char:match("%d") ~= nil
end

local function isId(char)
	return char:match("[%w_]")
end

function Lexer.new(stream)
	return setmetatable({
		stream = stream,
		_current_token = nil,
	}, Lexer)
end

function Lexer:_readWhile(callback)
	local buf = ""

	while self.stream:exhausted() == false and callback(self.stream:peek()) do
		buf = buf .. self.stream:next()
	end

	return buf
end

function Lexer:_readEscaped(ending)
	local escaped = false
	local buf = ""

	self.stream:next()

	while self.stream:exhausted() == false do
		local char = self.stream:next()

		if escaped then
			escaped = false
		elseif char == "\\" then
			escaped = true
		elseif char == ending then
			break
		end

		buf = buf .. char
	end

	return buf
end

function Lexer:_skipComment()
	self:_readWhile(function(char)
		return char ~= "\n"
	end)

	self.stream:next()
end

function Lexer:_readString()
	return {
		type = "str",
		value = self:_readEscaped('"'),
	}
end

function Lexer:_readVar()
	self.stream:next()

	local id = self:_readWhile(isId)

	return {
		type = "var",
		value = id,
	}
end

function Lexer:_readWord()
	return {
		type = "word",
		value = self:_readWhile(function(char)
			return isPunc(char) == false and
				char ~= '"' and
				isWhitespace(char) == false
		end)
	}
end

function Lexer:_readNumber()
	local decimal = false

	local number = self:_readWhile(function(char)
		if char == "." then
			if decimal then
				return false
			end

			decimal = true
			return true
		end

		return isDigit(char)
	end)

	return {
		type = "num",
		value = tonumber(number)
	}
end

function Lexer:_readNext()
	self:_readWhile(isWhitespace)

	if self.stream:exhausted() then
		return
	end

	local char = self.stream:peek()

	if char == "#" then
		self:_skipComment()
		return self:_readNext()
	end

	if char == '"' then
		return self:_readString()
	end

	if char == "$" then
		return self:_readVar()
	end

	if isDigit(char) then
		return self:_readNumber()
	end

	if isPunc(char) then
		return {
			type = "punc",
			value = self.stream:next(),
			col = self.stream.col,
			line = self.stream.line
		}
	end

	if isOpChar(char) then
		return {
			type = "op",
			value = self:_readWhile(isOpChar),
		}
	end

	return self:_readWord()
end

function Lexer:peek()
	self._current_token = self._current_token or self:_readNext()

	return self._current_token
end

function Lexer:next()
	local token = self._current_token or self:_readNext()
	self._current_token = nil
	return token
end

function Lexer:exhausted()
	return self:peek() == nil
end

return Lexer