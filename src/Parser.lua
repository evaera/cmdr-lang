local Parser = {}
Parser.__index = Parser

local OPERATOR_PRECEDENCE = {
	["="] = 1,
	["||"] = 2,
	["&&"] = 3,
	["<"] = 7,
	[">"] = 7,
	[">="] = 7,
	["<="] = 7,
	["=="] = 7,
	["!="] = 7,
	["+"] = 10,
	["-"] = 10,
	["*"] = 20,
	["/"] = 20,
	["%"] = 20,
}

function Parser.new(lexer)
	return setmetatable({
		lexer = lexer,
		_wordsAreStrings = false,
	}, Parser)
end

function Parser:_is(tokenType, value)
	local token = self.lexer:peek()

	return token and token.type == tokenType and (value == nil or token.value == value) and token
end

function Parser:_skip(tokenType, value)
	if self:_is(tokenType, value) then
		self.lexer:next()
	else
		local token = self.lexer:peek()
		error(("Expected %s, instead got %s %q"):format(
			value == nil and tokenType or ("%s %q"):format(tokenType, value),
			token.type,
			token.value
		))
	end
end

function Parser:_isLineSep()
	return self:_is("punc", ";") or self:_is("punc", "\n")
end

function Parser:_skipLineSep()
	if self:_isLineSep() then
		self.lexer:next()
	else
		local token = self.lexer:peek()
		error(("Expected line seperator, instead got %s %q"):format(
			token.type,
			token.value
		))
	end
end

function Parser:_eatLineSep()
	while self.lexer:exhausted() == false and self:_isLineSep() do
		self.lexer:next()
	end
end

function Parser:_unexpected(token)
	token = token or self.lexer:peek()

	error(("Unexpected token %s %q"):format(
		token.type,
		token.value
	))
end

function Parser:_sequence(start, stop, sep, callback)
	local nodes = {}
	local first = true

	self:_skip("punc", start)

	while self.lexer:exhausted() == false do
		if self:_is("punc", stop) then
			break
		end

		if first then
			first = false
		else
			self:_skip("punc", sep)
		end

		if self:_is("punc", stop) then
			break
		end

		table.insert(nodes, callback())
	end

	self:_skip("punc", stop)

	return nodes
end

function Parser:_maybeBinary(left, precedence)
	local token = self:_is("op")

	if token then
		local otherPrecedence = OPERATOR_PRECEDENCE[token.value]

		if otherPrecedence > precedence then
			self.lexer:next()

			return self:_maybeBinary({
				type = token.value == "=" and "assign" or "binary",
				operator = token.value,
				left = left,
				right = self:_maybeBinary(self:_parseAtom(), otherPrecedence)
			})
		end
	end

	return left
end

function Parser:_parseIf()
	self:_skip("word", "if")

	local condition = self:_parseExpression()

	local thenBranch = self:_parseBlock()

	local node = {
		type = "if",
		condition = condition,
		thenBranch = thenBranch,
	}

	if self:_is("word", "else") then
		self.lexer:next()

		node.elseBranch = self:_parseBlock()
	end

	return node
end

function Parser:_isCallToken()
	return (
		self:_is("word")
		or self:_is("")
	)
end

function Parser:_parseCall()
	local exprs = {}

	while self.lexer:exhausted() == false and not self:_isLineSep() do
		self._wordsAreStrings = true

		table.insert(
			exprs,
			self:_parseExpression()
		)

		self._wordsAreStrings = false
	end

	return {
		type = "call",
		func = table.remove(exprs, 1),
		args = exprs,
	}
end

function Parser:_parseAtom()
	if self:_is("punc", "(") then
		self.lexer:next()

		local expr = self:_parseExpression()

		self:_skip("punc", ")")

		return expr
	end

	if self:_is("punc", "{") then
		return self:_parseBlock()
	end

	if self:_is("word", "if") then
		return self:_parseIf()
	end

	if self:_is("word") then
		if self._wordsAreStrings then
			return {
				type = "str",
				value = self.lexer:next().value
			}
		end

		return self:_parseCall()
	end

	local token = self.lexer:next()

	if token.type == "var" or token.type == "num" or token.type == "str" then
		return token
	end

	self:_unexpected(token)
end

function Parser:_parseProgram(start, stop)
	local prog = {}

	if start then
		self:_skip("punc", start)
		self:_eatLineSep()
	end

	while self.lexer:exhausted() == false do
		if stop and self:_is("punc", stop) then
			break
		end

		table.insert(prog, self:_parseExpression())

		if stop and self:_is("punc", stop) then
			break
		end

		while self.lexer:exhausted() == false and self:_isLineSep() do
			self:_skipLineSep()
		end
	end

	if stop then
		self:_skip("punc", stop)
	end

	return prog
end

function Parser:_parseBlock()
	local prog = self:_parseProgram("{", "}")

	return {
		type = "prog",
		prog = prog,
	}
end

function Parser:_parseExpression()
	return self:_maybeBinary(self:_parseAtom(), 0)
end

function Parser:parse()
	return self:_parseProgram()
end

return Parser