function PlayerSound:play_footstep(foot, material_name)
	if self._last_material ~= material_name then
		self._last_material = material_name
		local material_name = tweak_data.materials[material_name:key()]

		self._unit:sound_source(Idstring("root")):set_switch("materials", material_name or "no_material")
	end
	
	local running = self._unit:movement():running() or self._unit:movement():current_state()._last_velocity_xy and math.abs(self._unit:movement():current_state()._last_velocity_xy:length()) > 300

	self:_play(running and "footstep_run" or "footstep_walk")
end