local InputStream = {}
InputStream.__index = InputStream

function InputStream.new(input)
	return setmetatable({
		input = input,
		pos = 1,
		line = 1,
		col = 1
	}, InputStream)
end

function InputStream:next()
	local char = self.input:sub(self.pos, self.pos)

	self.pos = self.pos + 1

	if char == "\n" then
		self.line = self.line + 1
		self.col = 1
	else
		self.col = self.col + 1
	end

	return char
end

function InputStream:peek()
	return self.input:sub(self.pos, self.pos)
end

function InputStream:exhausted()
	return self:peek() == ""
end

function InputStream:error(text)
	error(string.format("%s at %d:%d", text, self.line, self.col))
end

return InputStream