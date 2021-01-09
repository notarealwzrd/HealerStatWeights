local name, addon = ...;
local Queue = {};
local timeDelta = 0.33333; --within 1/3 of a second

--shallow table copy
local function copy(t) 
	local new_t = {};
	local mt = getmetatable(t);
	for k,v in pairs(t) do new_t[k] = v; end
	setmetatable(new_t,mt);
	return new_t;
end

function Queue.CreateHistoryQueue()
	local t = {
		Dirty=true
	};
	t.Enqueue = function(self,item)
		addon.hsw.db.global.front = addon.hsw.db.global.front+1;
		addon.hsw.db.global.history[addon.hsw.db.global.front] = copy(item);
		while ( self:Size() > addon.hsw.db.global.historySize ) do
			self:Dequeue()
		end
		self.Dirty = true;
	end
	t.Dequeue = function(self)
		if ( self:Size()>0 ) then
			addon.hsw.db.global.back = addon.hsw.db.global.back + 1;
			addon.hsw.db.global.history[addon.hsw.db.global.back] = nil;
		end
	end
	t.ClearDirty = function(self)
		self.Dirty = false;
	end
	t.GetDirty = function(self) 
		return self.Dirty;
	end
	t.Size = function(self)
		return addon.hsw.db.global.front - addon.hsw.db.global.back;
	end
	t.Get = function(self,i)
		if ( addon.hsw.db.global.history[addon.hsw.db.global.front-i] ) then
			return addon.hsw.db.global.history[addon.hsw.db.global.front-i];
		end
		return nil;
	end
	return t;
end



function Queue.CreateSpellQueue(fMasteryEffect)
	local t = {};
	t.getMasteryEffect = fMasteryEffect;
	t.front = 0;
	t.back = 0;
	t.Enqueue = function(self,count,data,...)
		count = count or 1;
		
		local masteryEffect = 0;
		if ( t.getMasteryEffect ) then
			masteryEffect = t.getMasteryEffect(...);
		end
		
		local eventData = {
			ts = GetTime(),
			data = data,
			ME = masteryEffect,
			CB = addon.ply_crtbonus,
			C = addon.ply_crt,
			SP = addon.ply_sp,
			H = addon.ply_hst,
			M = addon.ply_mst,
			V = addon.ply_vrs,
			L = addon.ply_lee
		};
		
		for i=1,count,1 do
			self.front = self.front+1;
			self[self.front] = copy(eventData);
		end
	end;
	t.Dequeue = function(self)
		if ( self:Size() > 0 ) then
			self.back = self.back + 1;
			local event = self[self.back];
			self[self.back] = nil;
			return event;
		end
	end;
	t.MatchHeal = function(self)
		local event = true;
		while ( self:Size() > 0 and event) do 
			event = self:Dequeue();
			if ( event ) then
				if ( math.abs(event.ts - GetTime()) <= timeDelta ) then -- within 1/3 of a second
					return event;
				end
			end
		end
		return nil;
	end
	t.Size = function(self)
		return self.front - self.back;
	end
	return t;
end

addon.Queue = Queue;