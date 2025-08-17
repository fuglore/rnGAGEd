Ladder.MOVER_NORMAL_OFFSET = 50

local mvec1 = Vector3()

function Ladder:init(unit)
	self._unit = unit

	unit:set_extension_update_enabled(Idstring("ladder"), Ladder.DEBUG)

	Ladder.debug_brush_1 = Ladder.debug_brush_1 or Draw:brush(Color.white:with_alpha(0.5))
	Ladder.debug_brush_2 = Ladder.debug_brush_2 or Draw:brush(Color.red)
	self.normal_axis = self.normal_axis or "y"
	self.up_axis = self.up_axis or "z"
	self._offset = self._offset or 0

	self:set_enabled(true)

	self._climb_on_top_offset = 80
	self._normal_target_offset = self._normal_target_offset or 40

	self:set_config()
	table.insert(Ladder.ladders, self._unit)
end