local ffi = require("ffi")
local C = ffi.C

local Buffer = require("levee.buffer")
local sys = require("levee.sys")


--
-- Read
--
local R_mt = {}
R_mt.__index = R_mt


function R_mt:reader()
	for ev in self.r_ev do
		if ev < -1 then
			self.hub:unregister(self.no, true)
			self.recver:close()
			return
		end

		while true do
			local n = C.read(self.no, self.buf:tail())
			if n == 0 then
				self:close()
				return
			end
			-- read until EAGAIN
			if n < 0 then break end
			self.buf:bump(n)
			-- we didn't receive a full read so wait for more data
			if self.buf:available() > 0 then break end
		end

		self.recver:send(self.buf)
	end
end


function R_mt:recv()
	if self.buf.len > 0 then
		return self.buf
	end
	return self.recver:recv()
end


R_mt.__call = R_mt.recv


function R_mt:close()
	self.recver:close()
	self.hub:unregister(self.no, true)
end


local function R_init(self)
	self.buf = Buffer(4096)
	self.recver = self.hub:pipe()
	self.hub:spawn(self.reader, self)
end


--
-- Write
--
local W_mt = {}
W_mt.__index = W_mt


function W_mt:write(buf, len)
	sys.os.write(self.no, buf, len)
end


function W_mt:writev(iov, n)
	C.writev(self.no, iov, n)
end


function W_mt:close()
	self.hub:unregister(self.no, false, true)
end


--
-- Read / Write
--
local RW_mt = {}
RW_mt.__index = RW_mt

RW_mt.reader = R_mt.reader
RW_mt.__call = R_mt.__call
RW_mt.recv = R_mt.recv
RW_mt.write = W_mt.write
RW_mt.writev = W_mt.writev


function RW_mt:close()
	self.recver:close()
	self.hub:unregister(self.no, true, true)
end


--
-- IO module interface
--
local IO_mt = {}
IO_mt.__index = IO_mt


function IO_mt:r(no)
	local m = setmetatable({hub = self.hub, no = no}, R_mt)
	m.r_ev = self.hub:register(no, true)
	R_init(m)
	return m
end


function IO_mt:w(no)
	local m = setmetatable({hub = self.hub, no = no}, W_mt)
	local _
	_, m.w_ev = self.hub:register(no, false, true)
	return m
end


function IO_mt:rw(no)
	local m = setmetatable({hub = self.hub, no = no}, RW_mt)
	m.r_ev, m.w_ev = self.hub:register(no, true, true)
	R_init(m)
	return m
end


function IO_mt:pipe()
	local r, w = sys.os.pipe()
	sys.os.nonblock(r)
	sys.os.nonblock(w)
	return self:r(r), self:w(w)
end


return function(hub)
	return setmetatable({hub = hub}, IO_mt)
end
