TheFixesPreventer = TheFixesPreventer or {}
TheFixesPreventer.tank_remove_recoil_anim = true

local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_step = mvector3.step
local mvec3_cpy = mvector3.copy
local mvec3_set_l = mvector3.set_length
local mvec3_add = mvector3.add
local mvec3_dot = mvector3.dot
local mvec3_cross = mvector3.cross
local mvec3_rot = mvector3.rotate_with
local mvec3_rand_orth = mvector3.random_orthogonal
local mvec3_lerp = mvector3.lerp
local mrot_axis_angle = mrotation.set_axis_angle
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
local temp_vec3 = Vector3()
local temp_vec4 = Vector3()
local temp_rot1 = Rotation()
local bezier_curve = {
	0,
	0,
	1,
	1
}

function CopActionShoot:update(t)
	local vis_state = self._ext_base:lod_stage()

	vis_state = vis_state or 4

	if vis_state == 1 then
		-- Nothing
	elseif vis_state * 3 > self._skipped_frames then
		self._skipped_frames = self._skipped_frames + 1

		return
	else
		self._skipped_frames = 1
	end
	
	if not self._last_upd_t then
		self._last_upd_t = t - 0.016
	end
	
	local dt = t - self._last_upd_t
	
	self._last_upd_t = t

	if self._ext_anim.base_need_upd then
		self._ext_movement:upd_m_head_pos()
	end

	local shoot_from_pos = self._shoot_from_pos
	local ext_anim = self._ext_anim
	local target_vec, target_dis, autotarget, target_pos

	if self._attention then
		target_pos, target_vec, target_dis, autotarget = self:_get_target_pos(shoot_from_pos, self._attention, t)
		
		local tar_vec_flat = temp_vec2

		mvec3_set(tar_vec_flat, target_vec)
		mvec3_set_z(tar_vec_flat, 0)
		mvec3_norm(tar_vec_flat)

		local fwd = self._common_data.fwd
		local fwd_dot = mvec3_dot(fwd, tar_vec_flat)
		
		if fwd_dot <= 0.5 then
			local fwd_polar = fwd:to_polar()
			local error_spin = tar_vec_flat:to_polar_with_reference(fwd, math.UP).spin
			
			if error_spin > 0 then
				target_vec = fwd_polar:with_spin(fwd_polar.spin + 59.8):to_vector():with_z(target_vec.z)
			else
				target_vec = fwd_polar:with_spin(fwd_polar.spin - 59.8):to_vector():with_z(target_vec.z)
			end
		end
		
		if self._last_target_vec then
			local wanted_target_vec = temp_vec4
			
			if self._shooting_player and managers.player:get_current_state() and managers.player:get_current_state():is_dashing() then
				mvec3_step(wanted_target_vec, self._last_target_vec, target_vec, dt * 0.5)
			else
				mvec3_step(wanted_target_vec, self._last_target_vec, target_vec, dt * 5)
			end
			
			target_vec = wanted_target_vec
		end
		
		local new_target_pos = temp_vec3
		mvec3_set(new_target_pos, target_vec)
		mvec3_set_l(new_target_pos, target_dis)
		mvec3_add(new_target_pos, shoot_from_pos)
		target_pos = new_target_pos
		
		mvec3_set(tar_vec_flat, target_vec)
		mvec3_set_z(tar_vec_flat, 0)
		mvec3_norm(tar_vec_flat)

		fwd_dot = mvec3_dot(fwd, tar_vec_flat)
		
		self._last_target_vec = mvec3_cpy(target_vec)

		if self._turn_allowed then
			local active_actions = self._common_data.active_actions
			local queued_actions = self._common_data.queued_actions

			if (not active_actions[2] or active_actions[2]:type() == "idle") and (not queued_actions or not queued_actions[1] and not queued_actions[2]) and not self._ext_movement:chk_action_forbidden("walk") then
				local fwd_dot_flat = mvec3_dot(tar_vec_flat, fwd)

				if fwd_dot_flat < 0.96 then
					local spin = tar_vec_flat:to_polar_with_reference(fwd, math.UP).spin
					local new_action_data = {
						body_part = 2,
						type = "turn",
						angle = spin
					}

					self._ext_movement:action_request(new_action_data)
				end
			end
		elseif self._brain_ext and self._brain_ext.chk_upd_aim then
			self._brain_ext:chk_upd_aim()
		end

		target_vec = self:_upd_ik(target_vec, fwd_dot, t)
	end

	if self._shield_use_cooldown and target_vec and self._common_data.allow_fire and t > self._shield_use_cooldown and target_dis < self._shield_use_range then
		local new_cooldown = self._shield_base:request_use(t)

		if new_cooldown then
			self._shield_use_cooldown = new_cooldown
		end
	end

	if ext_anim.reload or ext_anim.equip or ext_anim.melee or ext_anim.equip then
		if ext_anim.reload and self._looped_expire_t and t > self._looped_expire_t then
			self._looped_expire_t = nil

			self._ext_movement:play_redirect("reload_looped_exit")
		end
	elseif self._weapon_base:clip_empty() then
		if self._autofiring then
			self._weapon_base:stop_autofire()
			self._ext_movement:play_redirect("up_idle")

			self._autofiring = nil
			self._autoshots_fired = nil
		end

		if not self._ext_anim.base_no_reload then
			CopActionReload._play_reload(self, t)
		end
	elseif self._autofiring then
		if not target_vec or not self._common_data.allow_fire then
			self._weapon_base:stop_autofire()

			self._shoot_t = t + 0.6
			self._autofiring = nil
			self._autoshots_fired = nil

			self._ext_movement:play_redirect("up_idle")
		else
			local spread = self._spread
			local falloff, i_range = self:_get_shoot_falloff(target_dis, self._falloff)
			local dmg_buff = self._unit:base():get_total_buff("base_damage")
			local dmg_mul = (1 + dmg_buff) * falloff.dmg_mul
			local new_target_pos = self._shoot_history and self:_get_unit_shoot_pos(t, target_pos, target_dis, self._w_usage_tweak, falloff, i_range, autotarget)

			if new_target_pos then
				target_pos = new_target_pos
			else
				spread = math.min(20, spread)
			end

			local spread_pos = temp_vec2

			mvec3_set(spread_pos, target_vec)
			mvec3_rand_orth(spread_pos)
			mvec3_set_l(spread_pos, spread)
			mvec3_add(spread_pos, target_pos)

			target_dis = mvec3_dir(target_vec, shoot_from_pos, spread_pos)

			local fired = self._weapon_base:trigger_held(shoot_from_pos, target_vec, dmg_mul, self._shooting_player, nil, nil, nil, self._attention.unit)

			if fired then
				if fired.hit_enemy and fired.hit_enemy.type == "death" and self._unit:unit_data().mission_element then
					self._unit:unit_data().mission_element:event("killshot", self._unit)
				end

				if vis_state == 1 and not ext_anim.base_no_recoil and (not ext_anim.recoil or ext_anim.recoil_single) then
					self._ext_movement:play_redirect("recoil_auto")
				end

				if not self._autofiring or self._autoshots_fired >= self._autofiring - 1 then
					self._autofiring = nil
					self._autoshots_fired = nil

					self._weapon_base:stop_autofire()
					self._ext_movement:play_redirect("up_idle")

					self._shoot_t = t + (self._common_data.is_suppressed and 1.5 or 1) * math.lerp(falloff.recoil[1], falloff.recoil[2], self:_pseudorandom())
				else
					self._autoshots_fired = self._autoshots_fired + 1
				end
			end
		end
	elseif target_vec and self._common_data.allow_fire and t > self._shoot_t and t > self._mod_enable_t then
		local shoot

		if autotarget or self._shooting_husk_player and t > self._next_vis_ray_t then
			if self._shooting_husk_player then
				self._next_vis_ray_t = t + 2
			end

			local fire_line = World:raycast("ray", shoot_from_pos, target_pos, "slot_mask", self._verif_slotmask, "ray_type", "ai_vision")

			if fire_line then
				if t - self._line_of_sight_t > 3 then
					local aim_delay_minmax = self._w_usage_tweak.aim_delay
					local lerp_dis = math.min(1, target_vec:length() / self._falloff[#self._falloff].r)
					local aim_delay = math.lerp(aim_delay_minmax[1], aim_delay_minmax[2], lerp_dis)

					aim_delay = aim_delay + self:_pseudorandom() * aim_delay * 0.3

					if self._common_data.is_suppressed then
						aim_delay = aim_delay * 1.5
					end

					self._shoot_t = t + aim_delay
				elseif fire_line.distance > 300 then
					shoot = true
				end
			else
				if t - self._line_of_sight_t > 1 and not self._last_vis_check_status then
					local shoot_hist = self._shoot_history
					local displacement = mvector3.distance(target_pos, shoot_hist.m_last_pos)
					local focus_delay = self._w_usage_tweak.focus_delay * math.min(1, displacement / self._w_usage_tweak.focus_dis)

					shoot_hist.focus_start_t = t
					shoot_hist.focus_delay = focus_delay
					shoot_hist.m_last_pos = mvec3_cpy(target_pos)
				end

				self._line_of_sight_t = t
				shoot = true
			end

			self._last_vis_check_status = shoot
		elseif self._shooting_husk_player then
			shoot = self._last_vis_check_status
		else
			shoot = true
		end

		if self._common_data.char_tweak.no_move_and_shoot and self._common_data.ext_anim and self._common_data.ext_anim.move then
			shoot = false
			self._shoot_t = t + (self._common_data.char_tweak.move_and_shoot_cooldown or 1)
		end

		if shoot then
			local melee

			if autotarget and not self._shield_unit and (not self._common_data.melee_countered_t or t - self._common_data.melee_countered_t > 15) and target_dis < 130 and self._w_usage_tweak.melee_speed and t > self._melee_timeout_t then
				melee = self:_chk_start_melee(false)
			end

			if not melee then
				local falloff, i_range = self:_get_shoot_falloff(target_dis, self._falloff)
				local dmg_buff = self._unit:base():get_total_buff("base_damage")
				local dmg_mul = (1 + dmg_buff) * falloff.dmg_mul
				local firemode

				if self._automatic_weap then
					firemode = falloff.mode and falloff.mode[1] or 1

					local random_mode = math.random()

					for i_mode, mode_chance in ipairs(falloff.mode) do
						if random_mode <= mode_chance then
							firemode = i_mode

							break
						end
					end
				else
					firemode = 1
				end

				if firemode > 1 then
					self._weapon_base:start_autofire(firemode < 4 and firemode)

					if self._w_usage_tweak.autofire_rounds then
						if firemode < 4 then
							self._autofiring = firemode
						elseif falloff.autofire_rounds then
							local diff = falloff.autofire_rounds[2] - falloff.autofire_rounds[1]

							self._autofiring = math.round(falloff.autofire_rounds[1] + math.random() * diff)
						else
							local diff = self._w_usage_tweak.autofire_rounds[2] - self._w_usage_tweak.autofire_rounds[1]

							self._autofiring = math.round(self._w_usage_tweak.autofire_rounds[1] + math.random() * diff)
						end
					else
						Application:stack_dump_error("autofire_rounds is missing from weapon usage tweak data!", self._weap_tweak.usage)
					end

					self._autoshots_fired = 0

					if vis_state == 1 and not ext_anim.base_no_recoil and (not ext_anim.recoil or ext_anim.recoil_single) then
						self._ext_movement:play_redirect("recoil_auto")
					end
				else
					local spread = self._spread
					local new_target_pos = self._shoot_history and self:_get_unit_shoot_pos(t, target_pos, target_dis, self._w_usage_tweak, falloff, i_range, autotarget)

					if new_target_pos then
						target_pos = new_target_pos
					else
						spread = math.min(20, spread)
					end

					local spread_pos = temp_vec2

					mvec3_set(spread_pos, target_vec)
					mvec3_rand_orth(spread_pos)
					mvec3_set_l(spread_pos, spread)
					mvec3_add(spread_pos, target_pos)

					target_dis = mvec3_dir(target_vec, shoot_from_pos, spread_pos)

					local fired = self._weapon_base:singleshot(shoot_from_pos, target_vec, dmg_mul, self._shooting_player, nil, nil, nil, self._attention.unit)

					if fired and fired.hit_enemy and fired.hit_enemy.type == "death" and self._unit:unit_data().mission_element then
						self._unit:unit_data().mission_element:event("killshot", self._unit)
					end

					if vis_state == 1 and not ext_anim.base_no_recoil and (not ext_anim.recoil or ext_anim.recoil_single) then
						self._ext_movement:play_redirect("recoil_single")
					end

					self._shoot_t = t + (self._common_data.is_suppressed and 1.5 or 1) * math.lerp(falloff.recoil[1], falloff.recoil[2], self:_pseudorandom())
				end
			end
		end
	end
end

function CopActionShoot:_get_unit_shoot_pos(t, pos, dis, w_tweak, falloff, i_range, shooting_local_player)
	local shoot_hist = self._shoot_history
	local focus_delay, focus_prog = nil

	if shoot_hist.focus_delay then
		focus_delay = (shooting_local_player and self._attention.unit:character_damage():focus_delay_mul() or 1) * shoot_hist.focus_delay
		focus_prog = focus_delay > 0 and (t - shoot_hist.focus_start_t) / focus_delay

		if not focus_prog or focus_prog >= 1 then
			shoot_hist.focus_delay = nil
			focus_prog = 1
		end
	else
		focus_prog = 1
	end

	local dis_lerp = nil
	local hit_chances = falloff.acc
	local hit_chance = nil

	if i_range == 1 then
		dis_lerp = dis / falloff.r
		hit_chance = math.lerp(hit_chances[1], hit_chances[2], focus_prog)
	else
		local prev_falloff = w_tweak.FALLOFF[i_range - 1]
		dis_lerp = math.min(1, (dis - prev_falloff.r) / (falloff.r - prev_falloff.r))
		local prev_range_hit_chance = math.lerp(prev_falloff.acc[1], prev_falloff.acc[2], focus_prog)
		hit_chance = math.lerp(prev_range_hit_chance, math.lerp(hit_chances[1], hit_chances[2], focus_prog), dis_lerp)
	end

	if self._common_data.is_suppressed or self._ext_anim.hurt then
		hit_chance = hit_chance * 0.5
	end

	if self._common_data.active_actions[2] and self._common_data.active_actions[2]:type() == "dodge" then
		hit_chance = hit_chance * self._common_data.active_actions[2]:accuracy_multiplier()
	end

	hit_chance = hit_chance * self._unit:character_damage():accuracy_multiplier()
	
	if self._ext_movement.in_smoke and not managers.groupai:state():is_unit_team_AI(self._unit) then
		local in_smoke, variant = self._ext_movement:in_smoke()
		
		if in_smoke then
			local smoke_tweak = tweak_data.projectiles[variant]
		
			hit_chance = hit_chance * smoke_tweak.accuracy_roll_chance
		end
	end
	
	hit_chance = hit_chance * 2

	if self._miss_first_player_shot and (shooting_local_player or self._attention and self._attention.unit and self._attention.unit:base() and self._attention.unit:base().is_husk_player) then
		self._miss_first_player_shot = nil
		self._ext_movement.missed_first_shot = true
		hit_chance = 0
	end

	if math.random() < hit_chance then
		mvec3_set(shoot_hist.m_last_pos, pos)
	else
		local enemy_vec = temp_vec2

		mvec3_set(enemy_vec, pos)
		mvec3_sub(enemy_vec, self._shoot_from_pos)

		local error_vec = Vector3()

		mvec3_cross(error_vec, enemy_vec, math.UP)
		mrot_axis_angle(temp_rot1, enemy_vec, math.random(360))
		mvec3_rot(error_vec, temp_rot1)

		local miss_min_dis = shooting_local_player and 31 or 200
		local error_vec_len = miss_min_dis + w_tweak.spread + w_tweak.miss_dis * (1 - focus_prog)

		mvec3_set_l(error_vec, error_vec_len)
		mvec3_add(error_vec, pos)
		mvec3_set(shoot_hist.m_last_pos, error_vec)

		return error_vec
	end
end

function CopActionShoot:_get_transition_target_pos(shoot_from_pos, attention, t)
	self._aim_transition = nil
	self._get_target_pos = nil

	return self:_get_target_pos(shoot_from_pos, attention)
end


if RNGAGED.settings.disable_balance_changes then
	return
end

function CopActionShoot:_get_shoot_falloff(target_dis, falloff)
	local first_falloff = falloff[1]
	local final_falloff = falloff[#falloff]
	local first_autofire = first_falloff.autofire_rounds
	local final_autofire = final_falloff.autofire_rounds
	
	local falloff_lerp = math.min(1, target_dis / final_falloff.r)
	
	local falloff_data = {
		recoil = {
			math.lerp(first_falloff.recoil[1], final_falloff.recoil[1], falloff_lerp),
			math.lerp(first_falloff.recoil[2], final_falloff.recoil[2], falloff_lerp)
		},
		acc = {
			math.lerp(first_falloff.acc[1], final_falloff.acc[1], falloff_lerp),
			math.lerp(first_falloff.acc[2], final_falloff.acc[2], falloff_lerp)
		},
		dmg_mul = math.lerp(first_falloff.dmg_mul, final_falloff.dmg_mul, falloff_lerp),
		mode = {
			math.lerp(first_falloff.mode[1], final_falloff.mode[1], falloff_lerp),
			math.lerp(first_falloff.mode[2], final_falloff.mode[2], falloff_lerp),
			math.lerp(first_falloff.mode[3], final_falloff.mode[3], falloff_lerp),
			math.lerp(first_falloff.mode[4], final_falloff.mode[4], falloff_lerp)
		},
		r = final_falloff.r
	}

	if first_autofire and final_autofire then
		falloff_data.autofire_rounds = {
			math.lerp(first_autofire[1], final_autofire[1], falloff_lerp),
			math.lerp(first_autofire[2], final_autofire[2], falloff_lerp),
		}
	end

	return falloff_data, 1
end