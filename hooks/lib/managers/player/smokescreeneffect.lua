function SmokeScreenEffect:update(t, dt)
	if self._timer then
		self._timer = self._timer - dt

		if self._timer <= 2 then
			World:effect_manager():fade_kill(self._effect)

			if not self._sound_killed then
				self._sound_source:post_event("lung_loop_end")
				managers.enemy:add_delayed_clbk("SmokeScreenEffect", callback(ProjectileBase, ProjectileBase, "_dispose_of_sound", {
					sound_source = self._sound_source
				}), TimerManager:game():time() + 4)

				self._sound_killed = true
			end
		end

		if self._timer <= 0 then
			self._timer = nil
		end
	end
	
	if not self._upd_t or self._upd_t <= 0 then
		self._unit_list = {}
		local nearby_units = World:find_units_quick("sphere", self._position, self._radius, managers.slot:get_mask("persons"))

		for _, unit in ipairs(nearby_units) do
			self._unit_list[unit:key()] = true
		end
		
		self._upd_t = 0.5
	else
		self._upd_t = self._upd_t - dt
	end
end