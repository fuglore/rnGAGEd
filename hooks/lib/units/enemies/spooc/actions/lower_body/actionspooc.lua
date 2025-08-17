function ActionSpooc:anim_clbk_melee_strike()
	if RNGAGED.settings.disable_balance_changes then
		return
	end

	if self._strike_unit and alive(self._strike_unit) and self._strike_unit:base().is_local_player and not self._downed_the_player then
		local char_damage = self._strike_unit:character_damage()

		if char_damage._incapacitated then
			if char_damage:get_real_health() <= 0 and not self._downed_the_player then
				self._downed_the_player = true
				char_damage._incapacitated = nil
				char_damage._hard_incapacitated = true

				if not char_damage._downed_paused_counter or char_damage._downed_paused_counter <= 0 then
					char_damage._revives = Application:digest_value(Application:digest_value(char_damage._revives, false) - 1, true)

					char_damage:_send_set_revives()

					managers.environment_controller:set_last_life(Application:digest_value(char_damage._revives, false) <= 1)

					if Application:digest_value(char_damage._revives, false) <= 0 then
						char_damage._down_time = 0
						char_damage._downed_timer = 0
						char_damage._downed_paused_counter = 0
					end

					if self._is_local and not self._was_interrupted then
						if Network:is_server() then
							self:_expire()
						else
							self._ext_network:send_to_host("action_spooc_stop", self._ext_movement:m_pos(), 1, self._action_id)
							self:_wait()
						end
					end
				end

				return
			else
				char_damage:change_health(-2)
				
				local target_vec = self._tmp_vec1

				mvector3.set(target_vec, self._common_data.pos)
				mvector3.subtract(target_vec, self._strike_unit:movement():m_head_pos())
				managers.hud:on_hit_direction(target_vec, HUDHitDirection.DAMAGE_TYPES.HEALTH)
				self._strike_unit:camera():play_shaker("player_bullet_damage", 1)
				self._strike_unit:sound():play("player_hit_permadamage")
				
				local vars = {
					"melee_hit",
					"melee_hit_var2"
				}

				self._strike_unit:camera():play_shaker(vars[math.random(#vars)], 0.25)
				
				if char_damage:get_real_health() <= 0 then
					self._downed_the_player = true
					char_damage._incapacitated = nil
					char_damage._hard_incapacitated = true
					
					char_damage._revives = Application:digest_value(Application:digest_value(char_damage._revives, false) - 1, true)

					char_damage:_send_set_revives()
					
					managers.environment_controller:set_last_life(Application:digest_value(char_damage._revives, false) <= 1)
					
					if Application:digest_value(char_damage._revives, false) <= 0 then
						char_damage._down_time = 0
						char_damage._downed_timer = 0
						char_damage._downed_paused_counter = 0
					end
					
					if self._is_local and not self._was_interrupted then
						if Network:is_server() then
							self:_expire()
						else
							self._ext_network:send_to_host("action_spooc_stop", self._ext_movement:m_pos(), 1, self._action_id)
							self:_wait()
						end
					end
					
					return
				end
			end
		end
	end
end

function ActionSpooc:_upd_flying_strike_first_frame(t)
	local target_pos = nil

	if self._is_local then
		target_pos = self._target_unit:movement():m_pos()

		self:_send_nav_point(target_pos)
	else
		target_pos = self._nav_path[#self._nav_path]
	end

	local my_pos = self._unit:movement():m_pos()
	local target_vec = self._tmp_vec1

	mvector3.set(target_vec, target_pos)
	mvector3.subtract(target_vec, my_pos)

	local target_dis = mvector3.length(target_vec)
	local redir_result = self._ext_movement:play_redirect("spooc_flying_strike")

	if not redir_result then
		debug_pause_unit(self._unit, "[ActionSpooc:_chk_start_flying_strike] failed redirect spooc_flying_strike in ", self._machine:segment_state(Idstring("base")), self._unit)

		return
	end

	self._ext_movement:spawn_wanted_items()

	local anim_travel_dis_xy = 470
	self._flying_strike_data = {
		start_pos = mvector3.copy(my_pos),
		start_rot = self._unit:rotation(),
		target_pos = mvector3.copy(target_pos),
		target_rot = Rotation(target_vec:with_z(0), math.UP),
		start_t = TimerManager:game():time(),
		travel_dis_scaling_xy = target_dis / anim_travel_dis_xy
	}
	local speed_mul = math.lerp(3, 1, math.min(1, self._flying_strike_data.travel_dis_scaling_xy))

	self._machine:set_speed(redir_result, speed_mul)

	if alive(self._target_unit) and self._target_unit:base().is_local_player then
		local enemy_vec = mvector3.copy(self._common_data.pos)

		mvector3.subtract(enemy_vec, self._target_unit:movement():m_pos())
		mvector3.set_z(enemy_vec, 0)
		mvector3.normalize(enemy_vec)
	end

	self:_set_updator("_upd_flying_strike")
end

function ActionSpooc:_upd_strike_first_frame(t)
	if self._is_local and self:_chk_target_invalid() then
		if Network:is_server() then
			self:_expire()
		else
			self:_wait()
		end

		return
	end

	local redir_result = self._ext_movement:play_redirect("spooc_strike")

	if redir_result then
		self._ext_movement:spawn_wanted_items()
	elseif self._is_local then
		if Network:is_server() then
			self:_expire()
		else
			self._ext_network:send_to_host("action_spooc_stop", self._ext_movement:m_pos(), 1, self._action_id)
			self:_wait()
		end

		return
	end

	if self._is_local then
		mvector3.set(self._last_sent_pos, self._common_data.pos)
		self._ext_network:send("action_spooc_strike", mvector3.copy(self._common_data.pos), self._action_id)

		self._nav_path[self._nav_index + 1] = mvector3.copy(self._common_data.pos)

		if self._target_unit:base().is_local_player then
			local enemy_vec = mvector3.copy(self._common_data.pos)

			mvector3.subtract(enemy_vec, self._target_unit:movement():m_pos())
			mvector3.set_z(enemy_vec, 0)
			mvector3.normalize(enemy_vec)
			self._target_unit:movement():about_to_get_spooced(self._unit)
			self._target_unit:camera():camera_unit():base():clbk_aim_assist({
				ray = enemy_vec
			})
		end
	end

	self._last_vel_z = 0

	self:_set_updator("_upd_striking")
end