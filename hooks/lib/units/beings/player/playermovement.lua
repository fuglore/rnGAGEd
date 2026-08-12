local cook_states = {
	carry = true,
	standard = true,
	mask_off = true,
	civilian = true,
	tased = true
}

function PlayerMovement:change_state(name)
	local exit_data = nil

	if self._current_state then
		exit_data = self._current_state:exit(self._state_data, name)
	end
	
	local cur_vel, jump_vel, last_step_pos, true_headbob, headbob_target, freefall_sound_instance, dash_t, dashing, peek_from_cover, fwd_ray, jump_t
	local t = managers.player:player_timer():time()
	local dt = managers.player:player_timer():delta_time()
	
	if self._current_state then
		if not cook_states[name] then
			self._unit:camera():set_shaker_parameter("headbob_run", "amplitude", 0)
			self._unit:camera():set_shaker_parameter("headbob_crouch", "amplitude", 0)
			self._unit:camera():set_shaker_parameter("headbob", "amplitude", 0)
			self._unit:camera():set_shaker_parameter("freefall", "amplitude", 0)
			
			if self._current_state._free_fall_sound then
				self._current_state._free_fall_sound:stop()
				self._current_state._free_fall_sound = nil
			end
		else
			if self._current_state._fwd_ray then
				fwd_ray = self._current_state._fwd_ray
			end
		
			if self._current_state._state_data.dashing then
				dash_t = self._current_state._state_data.dash_t
				dashing = self._current_state._state_data.dashing
			end
			
			if self._current_state.peek_from_cover then
				peek_from_cover = self._current_state.peek_from_cover
			end
		
			if self._current_state._free_fall_sound then
				freefall_sound_instance = self._current_state._free_fall_sound
			end
			
			if self._current_state._last_velocity_xy then
				cur_vel = mvector3.copy(self._current_state._last_velocity_xy)
			end
			
			if self._current_state._jump_vel_xy then
				jump_vel = mvector3.copy(self._current_state._jump_vel_xy)
			end
			
			if self._current_state._jump_t then
				jump_t = self._current_state._jump_t
			end
			
			if self._current_state._last_step_pos then
				last_step_pos = mvector3.copy(self._current_state._last_step_pos)
			end
			
			if self._current_state._true_headbob then
				true_headbob = self._current_state._true_headbob
				headbob_target = self._current_state._true_headbob_target
			end
		end
	end

	local new_state = self._states[name]
	self._current_state = new_state
	self._current_state_name = name
	self._state_enter_t = t

	self._current_state:enter(self._state_data, exit_data)
	
	if self._current_state then
		if not cook_states[name] then
			self._unit:camera():set_shaker_parameter("headbob_run", "amplitude", 0)
			self._unit:camera():set_shaker_parameter("headbob_crouch", "amplitude", 0)
			self._unit:camera():set_shaker_parameter("headbob", "amplitude", 0)
			self._unit:camera():set_shaker_parameter("freefall", "amplitude", 0)
		else
			if dashing then
				self._current_state._state_data.dashing = dashing
				self._current_state._state_data.dash_t = dash_t
			end
			
			if fwd_ray then
				self._current_state._fwd_ray = fwd_ray
			end
			
			if peek_from_cover then
				self._current_state.peek_from_cover = peek_from_cover
			end
		
			if freefall_sound_instance then
				self._current_state._free_fall_sound = freefall_sound_instance
			end
			
			if cur_vel then
				self._current_state._last_velocity_xy = cur_vel
			end
			
			if jump_vel then
				self._current_state._jump_vel_xy = jump_vel
			end
			
			if jump_t then
				self._current_state._jump_t = jump_t
			end
			
			if last_step_pos then
				self._current_state.last_step_pos = last_step_pos
			end
			
			if true_headbob then
				self._current_state._true_headbob = true_headbob
				self._current_state._true_headbob_target = headbob_target
			end
		end
	end
	
	if cook_states[name] then
		local input = self._current_state:_get_input(t, dt)
		
		self._current_state:_calculate_standard_variables(t, dt)
		self._current_state:_update_ground_ray()
		self._current_state:_update_foley(t, input)
		self._current_state:_update_movement(t, dt)
		self._current_state:_upd_nav_data()
	end
	
	self._unit:network():send("sync_player_movement_state", self._current_state_name, self._unit:character_damage():down_time(), self._unit:id())
end

function PlayerMovement:about_to_get_spooced(enemy_unit)
	if RNGAGED.settings.disable_balance_changes then
		return
	end
	
	local spooc_slow = {
		max_mul = 0.1,
		add_mul = 0,
		decay_time = 0.2,
		id = "spooc_fear",
		duration = 1,
		mul = 0.1,
		prevents_running = true
	}
	self._unit:character_damage():apply_slowdown(spooc_slow)
end


if RNGAGED.settings.disable_balance_changes then
	return
end

local old_update = PlayerMovement.update

function PlayerMovement:update(unit, t, dt)
	old_update(self, unit, t, dt)

--Hooks:PostHook(PlayerMovement, "update", "regunz_upd_moveacc", function(self, unit, t, dt)
	if self._current_state and self._unit:inventory() then
		local mov_state = self._current_state
		local equipped_weapon = self._unit:inventory():equipped_unit()

		if alive(equipped_weapon) and equipped_weapon:base() then
			local weapon_base = alive(equipped_weapon) and equipped_weapon:base()
			
			if mov_state._num_shocks then --player is being tased lmao
				local shock_debuff = weapon_base.regunz_movement_penalty or 0
				
				if math.random() > 0.5 then
					shock_debuff = shock_debuff + dt
				else
					shock_debuff = shock_debuff - dt
				end
				
				weapon_base.regunz_movement_penalty = math.clamp(shock_debuff, 0, 1)
			elseif mov_state._moving then
				local speed_tweak = mov_state._tweak_data.movement.speed
				local walk_speed = speed_tweak.STANDARD_MAX
				local cur_speed = mov_state._last_velocity_xy and mov_state._last_velocity_xy:length() or 0
				
				if mov_state:in_steelsight() then
					cur_speed = math.min(cur_speed, speed_tweak.STEELSIGHT_MAX)
				end

				local debuff_mul = math.clamp(cur_speed / walk_speed, 0, 1)
				
				weapon_base.regunz_movement_penalty = debuff_mul
			else
				weapon_base.regunz_movement_penalty = 0
			end
		end
	end
end

function PlayerMovement:on_SPOOCed(enemy_unit)
	local charging_melee = self._current_state.in_melee and self._current_state:in_melee()
	local in_melee = charging_melee or self._current_state._state_data.melee_expire_t

	if managers.player:has_category_upgrade("player", "counter_strike_spooc") and in_melee then
		local melee_entry = managers.blackmarket:equipped_melee_weapon()
		local auto_counter = tweak_data.blackmarket.melee_weapons[melee_entry].stats.auto_counter
		
		if auto_counter then
			if charging_melee then
				self._current_state:discharge_melee()
			end

			return "countered"
		end
	end

	if self._unit:character_damage()._god_mode or self._unit:character_damage():get_mission_blocker("invulnerable") then
		return
	end

	if self._current_state_name == "standard" or self._current_state_name == "carry" or self._current_state_name == "bleed_out" or self._current_state_name == "tased" or self._current_state_name == "bipod" then
		local state = "incapacitated"
		state = managers.modifiers:modify_value("PlayerMovement:OnSpooked", state)

		managers.player:set_player_state(state)
		managers.achievment:award(tweak_data.achievement.finally.award)
		
		local char_damage = self._unit:character_damage()

		if char_damage:get_real_health() >= 0 then
			char_damage:change_health(-2)
			
			if char_damage:get_real_health() <= 0 then
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
				
				return true
			end
		end

		return true
	end
end