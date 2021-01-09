local name, addon = ...;
local ids = {};



--[[----------------------------------------------------------------------------
	Segment Manager: 
	
	Contains queue of most-recent Segments, as well as a "Total" Segment.
------------------------------------------------------------------------------]]
local SegmentManager = {
	segments = {},
	front=0, --front of queue
	back=0, --back of queue
	Total = addon.Segment.Create("Total");
};



--[[----------------------------------------------------------------------------
	ResetTotalSegment - Resets the "Total" segment
------------------------------------------------------------------------------]]
function SegmentManager:ResetTotalSegment() --reset the total segment
	self.Total = addon.Segment.Create("Total");
	self.Total.startTime = -1;
end



--[[----------------------------------------------------------------------------
	ResetAllSegments - Resets the "Total" segment & Removes all other segments
------------------------------------------------------------------------------]]
function SegmentManager:ResetAllSegments()
	if ( not addon.inCombat ) then
		self:ResetTotalSegment();
		while (self:Size() > 0) do
			self:Dequeue()
		end
	end
end



--[[----------------------------------------------------------------------------
	Enqueue - Create & add a new segment to the front of the queue
------------------------------------------------------------------------------]]
function SegmentManager:Enqueue(id)
	self.front = self.front + 1;
	self.segments[self.front] = addon.Segment.Create(id or "Unknown");
	
	if ( id ) then
		self:SetCurrentId(id or "Unknown",true);
	end
	
	if ( SegmentManager:Size() > addon.hsw.db.global.maxSegments ) then
		self:Dequeue();
	end	
end



--[[----------------------------------------------------------------------------
	Dequeue - Remove the segment at back of the queue
------------------------------------------------------------------------------]]
function SegmentManager:Dequeue()
	if ( self:Size() > 0 ) then
		self.back = self.back + 1;
		self.segments[self.back] = nil;
	end
end



--[[----------------------------------------------------------------------------
	Size - Return the size of the queue (number of segments)
------------------------------------------------------------------------------]]
function SegmentManager:Size()
	return self.front - self.back;
end



--[[----------------------------------------------------------------------------
	Get - Get ith most-recent segment, or the "Total" segment. 0-based.
------------------------------------------------------------------------------]]
function SegmentManager:Get(i)
	if ( i == "Total" ) then
		return self.Total;
	end
	
	if ( tonumber(i) and self.segments[self.front - i] ) then
		return self.segments[self.front-i];
	end
	
	return nil;
end



--[[----------------------------------------------------------------------------
	SetId - Update the name of the current segment & instance info
------------------------------------------------------------------------------]]
function SegmentManager:SetCurrentId(newId,isBossFight)
	if ( newId and newId ~= "Unknown" and newId ~= "Total" and not self.segments[self.front].nameSet ) then
		self.segments[self.front]:SetupInstanceInfo(isBossFight);
		ids[newId] = ( ids[newId] or 0 ) + 1;
		if ( ids[newId] > 1 ) then
			self.segments[self.front].id = newId .. "(" .. tostring(ids[newId]) .. ")";
		else
			self.segments[self.front].id = newId;
		end
		self.segments[self.front].nameSet = true;
	end
end



addon.SegmentManager = SegmentManager;