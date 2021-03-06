local FIFO = {}
FIFO.__index = FIFO


function FIFO:push(v)
	self.tail = self.tail + 1
	self[self.tail] = v
end


function FIFO:pop()
	local head, tail = self.head, self.tail
	if head > tail then error("empty") end
	local v = self[head]
	self[head] = nil
	if head == tail then
		self.head = 1
		self.tail = 0
	else
		self.head = head + 1
	end
	return v
end


function FIFO:peek()
	local head, tail = self.head, self.tail
	if head > tail then error("empty") end
	return self[head]
end


function FIFO:remove(n)
	local head, tail = self.head, self.tail
	if n > #self then error("range") end
	for i=head,head+n-1 do
		self[i] = nil
	end
	head = head + n
	if head > tail then
		self.head = 1
		self.tail = 0
	else
		self.head = head
	end
end


function FIFO:iter()
	local i = 0
	return function()
		local n = self.head + i
		i = i + 1
		if n <= self.tail then
			return self[n]
		end
	end
end


function FIFO:popiter()
	return function()
		if #self > 0 then
			return self:pop()
		end
	end
end


function FIFO:peekiter()
	local first = true
	return function()
		if first then
			first = false
		else
			self:pop()
		end
		if #self > 0 then
			return self:peek()
		end
	end
end


function FIFO:__len()
	return self.tail - self.head + 1
end


return function()
	return setmetatable({head = 1, tail = 0}, FIFO)
end
