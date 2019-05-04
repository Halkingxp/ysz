print "load CustomList.lua"

if	CustomList == nil then 
	CustomList = {
	first = 0, 
	last = 0,
	current = 0,
	iterator = 0,
	}
end

function CustomList:new ()
	--print("customlist:new is run")
	local tObj = {}
	Extends(tObj, self)
	return tObj
end

function CustomList:push ( value)
	--print("customlist:push is run")
    local last = self.last + 1
    self.last = last
    self[last] = value
	--print("跑马灯列表的长度 = "..self:length())
end

function CustomList:pop ()
	--print("customlist:pop is run")
    if self.first == self.last then 
		error("self is empty") 
		return nil
	end
	local first = self.first + 1
	self.first = first
    local value = self[first]
    self[first] = nil
	if self.current < self.first then
		self.current = self.first
	end
	--print(string.format("跑马灯列表的长度 = %d",self:length()))
    return value
end

function CustomList:length()
	--print("customlist:length is run")
	--print(#self)
	--print(self.last)
	return self.last - self.first;
end

function CustomList:Move()
	if self.current == self.last then
		return nil
	end
	
	self.current = self.current + 1
	return self[self.current]
end

function CustomList:IsMoveToEnd()
	if self.current == self.last then
		return true
	else
		return false
	end
end

function CustomList:IsCurrentAtFrist()
	if self.current == self.first then
		return true
	else
		return false
	end
end

function CustomList:InsertCurrent(value)
	if self.current == self.last then
		--直接插在队尾
		self:Push(value)
	else
		--将current后的元素后移一位，空出位子放入
		for index = self.last, self.current + 1, -1 do
			self[index + 1] = self[index] 
		end
		self[self.current + 1] = value
		self.last = self.last + 1
	end
end

----------------------迭代遍历用----------------------
function CustomList:InitIterator()
	self.iterator = self.first + 1
end

function CustomList:IsIteratortoEnd()
	if self.iterator == self.current + 1 then 
		return true
	else
		return false
	end
end

function CustomList:MoveNext()
	self.iterator = self.iterator + 1
end

function CustomList:GetIteratorNode()
	return self[self.iterator]
end

function CustomList:GetIteratorIndex()
	return self.iterator
end
