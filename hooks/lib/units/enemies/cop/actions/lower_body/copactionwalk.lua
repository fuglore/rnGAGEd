local mvec3_set = mvector3.set
local mvec3_z = mvector3.z
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_lerp = mvector3.lerp
local mvec3_cpy = mvector3.copy
local mvec3_set_l = mvector3.set_length
local mvec3_dot = mvector3.dot
local mvec3_cross = mvector3.cross
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_len = mvector3.length
local mvec3_rot = mvector3.rotate_with
local mrot_lookat = mrotation.set_look_at
local mrot_slerp = mrotation.slerp
local math_abs = math.abs
local math_max = math.max
local math_min = math.min
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
local tmp_vec4 = Vector3()
local temp_rot1 = Rotation()
local idstr_base = Idstring("base")

CopActionWalk._NO_RUN_STOP = true

local bingus = true

function CopActionWalk:_chk_start_anim(next_pos)
	if self._was_interrupted or self._haste ~= "run" or self._common_data.char_tweak.no_run_start or bingus then
		return
	end

	local lod_stage = self._ext_base:lod_stage()

	if not lod_stage or lod_stage > 2 then
		return
	end

	local can_turn_and_fire = true
	local path_dir = next_pos - self._common_data.pos

	mvec3_set_z(path_dir, 0)

	local path_len = mvec3_norm(path_dir)
	local path_angle = path_dir:to_polar_with_reference(self._common_data.fwd, math.UP).spin

	if self._attention_pos then
		local target_vec = nil
		target_vec = self._attention_pos - self._common_data.pos
		local target_vec_flat = target_vec:with_z(0)

		mvec3_norm(target_vec_flat)

		local fwd_dot = mvec3_dot(path_dir, target_vec_flat)

		if fwd_dot < 0.7 then
			can_turn_and_fire = nil
		end
	end

	if math_abs(path_angle) > 135 then
		if can_turn_and_fire then
			local pose = self._ext_anim.pose or self._fallback_pose
			local spline_data = self._anim_movement[pose].run_start_turn_bwd
			local ds = spline_data.ds

			if ds:length() < path_len - 100 then
				if path_angle > 0 then
					path_angle = path_angle - 360
				end

				self._start_run_turn = {
					self._common_data.rot:yaw(),
					path_angle,
					"bwd"
				}
			end
		end
	elseif path_angle < -65 then
		if can_turn_and_fire then
			local pose = self._ext_anim.pose or self._fallback_pose
			local spline_data = self._anim_movement[pose].run_start_turn_r
			local ds = spline_data.ds

			if ds:length() < path_len - 100 then
				self._start_run_turn = {
					self._common_data.rot:yaw(),
					path_angle,
					"r"
				}
			end
		end
	elseif path_angle > 65 and can_turn_and_fire then
		local pose = self._ext_anim.pose or self._fallback_pose
		local spline_data = self._anim_movement[pose].run_start_turn_l
		local ds = spline_data.ds

		if ds:length() < path_len - 100 then
			self._start_run_turn = {
				self._common_data.rot:yaw(),
				path_angle,
				"l"
			}
		end
	end

	self._start_run = true
	self._root_blend_disabled = true

	self._ext_movement:set_root_blend(false)

	if not self._start_run_turn then
		local right_dot = mvec3_dot(path_dir, self._common_data.right)
		local fwd_dot = mvec3_dot(path_dir, self._common_data.fwd)
		local wanted_walk_dir = nil

		if math_abs(right_dot) < math_abs(fwd_dot) then
			self._start_run_straight = fwd_dot > 0 and "fwd" or "bwd"
		else
			self._start_run_straight = right_dot > 0 and "r" or "l"
		end
	end
end

function CopActionWalk:on_attention(attention)
	if attention then
		self._attention = attention

		if attention.handler then
			if self._common_data.stance.name ~= "ntl" then
				if AIAttentionObject.REACT_AIM <= attention.reaction then
					self._attention_pos = attention.handler:get_attention_m_pos()
				else
					self._attention_pos = false
				end
			elseif AIAttentionObject.REACT_SURPRISED <= attention.reaction then
				self._attention_pos = attention.handler:get_attention_m_pos()
			else
				self._attention_pos = false
			end
		elseif self._common_data.stance.name ~= "ntl" then
			if attention.unit then
				self._attention_pos = attention.unit:movement():m_pos()
			elseif attention.pos then
				self._attention_pos = attention.pos
			end
		end
	else
		self._attention_pos = false
	end
end

function CopActionWalk:update(t)
	local dt = nil
	local vis_state = self._ext_base:lod_stage()
	vis_state = vis_state or 4

	if vis_state == 1 then
		dt = t - self._last_upd_t
		self._last_upd_t = TimerManager:game():time()
	elseif self._skipped_frames < vis_state then
		self._skipped_frames = self._skipped_frames + 1

		return
	else
		self._skipped_frames = 1
		dt = t - self._last_upd_t
		self._last_upd_t = TimerManager:game():time()
	end

	if self._ik_update then
		self._ik_update(t)
	end

	local pos_new = nil

	if self._end_of_path and (not self._ext_anim.act or not self._ext_anim.walk) then
		if self._next_is_nav_link then
			self:_set_updator("_upd_nav_link_first_frame")
			self:update(t)

			return
		elseif self._persistent then
			self:_set_updator("_upd_wait")
		else
			self._expired = true

			if self._end_rot then
				self._ext_movement:set_rotation(self._end_rot)
			end
		end
	else
		self:_nav_chk_walk(t, dt, vis_state)
	end

	local move_dir = tmp_vec3

	mvec3_set(move_dir, self._last_pos)
	mvec3_sub(move_dir, self._common_data.pos)
	mvec3_set_z(move_dir, 0)

	if self._cur_vel < 0.1 or self._ext_anim.act and self._ext_anim.walk then
		move_dir = nil
	end

	local anim_data = self._ext_anim

	if move_dir and not self._expired then
		local face_fwd = tmp_vec1
		local wanted_walk_dir = nil
		local move_dir_norm = move_dir:normalized()

		if self._no_strafe or self._walk_turn then
			wanted_walk_dir = "fwd"
		else
			if self._curve_path_end_rot and mvector3.distance_sq(self._last_pos, self._footstep_pos) < 19600 then
				mvec3_set(face_fwd, self._common_data.fwd)
			elseif self._attention_pos then
				mvec3_set(face_fwd, self._attention_pos)
				mvec3_sub(face_fwd, self._common_data.pos)
			elseif self._footstep_pos then
				mvec3_set(face_fwd, self._footstep_pos)
				mvec3_sub(face_fwd, self._common_data.pos)
			else
				mvec3_set(face_fwd, self._common_data.fwd)
			end

			mvec3_set_z(face_fwd, 0)
			mvec3_norm(face_fwd)

			local face_right = tmp_vec2

			mvec3_cross(face_right, face_fwd, math.UP)
			mvec3_norm(face_right)

			local right_dot = mvec3_dot(move_dir_norm, face_right)
			local fwd_dot = mvec3_dot(move_dir_norm, face_fwd)

			if math_abs(right_dot) < math_abs(fwd_dot) then
				if (anim_data.move_l and right_dot < 0 or anim_data.move_r and right_dot > 0) and math_abs(fwd_dot) < 0.73 then
					wanted_walk_dir = anim_data.move_side
				elseif fwd_dot > 0 then
					wanted_walk_dir = "fwd"
				else
					wanted_walk_dir = "bwd"
				end
			elseif (anim_data.move_fwd and fwd_dot > 0 or anim_data.move_bwd and fwd_dot < 0) and math_abs(right_dot) < 0.73 then
				wanted_walk_dir = anim_data.move_side
			elseif right_dot > 0 then
				wanted_walk_dir = "r"
			else
				wanted_walk_dir = "l"
			end
		end

		local rot_new = nil

		if self._curve_path_end_rot then
			local dis_lerp = 1 - math.min(1, mvec3_dis(self._last_pos, self._footstep_pos) / 140)
			rot_new = temp_rot1

			mrot_slerp(rot_new, self._curve_path_end_rot, self._nav_link_rot or self._end_rot, dis_lerp)
		else
			local wanted_u_fwd = tmp_vec1

			mvec3_set(wanted_u_fwd, move_dir_norm)
			mvec3_rot(wanted_u_fwd, self._walk_side_rot[wanted_walk_dir])
			mrot_lookat(temp_rot1, wanted_u_fwd, math.UP)

			rot_new = temp_rot1
			
			local mul = self._common_data.ext_inventory:shield_unit() and 0.5 or 0.75
			
			mrot_slerp(rot_new, self._common_data.rot, rot_new, math.min(1, dt * 5 * mul))
		end

		self._ext_movement:set_rotation(rot_new)

		if self._chk_stop_dis and not self._was_interrupted and not self._common_data.char_tweak.no_run_stop then
			local end_dis = mvec3_dis(self._nav_point_pos(self._simplified_path[#self._simplified_path]), self._last_pos)

			if end_dis < self._chk_stop_dis then
				local stop_anim_fwd = not self._nav_link_rot and self._end_rot and self._end_rot:y() or move_dir_norm:rotate_with(self._walk_side_rot[wanted_walk_dir])
				local fwd_dot = mvec3_dot(stop_anim_fwd, move_dir_norm)
				local move_dir_r_norm = tmp_vec3

				mvec3_cross(move_dir_r_norm, move_dir_norm, math.UP)

				local fwd_dot = mvec3_dot(stop_anim_fwd, move_dir_norm)
				local r_dot = mvec3_dot(stop_anim_fwd, move_dir_r_norm)
				local stop_anim_side = nil

				if math.abs(r_dot) < math.abs(fwd_dot) then
					if fwd_dot > 0 then
						stop_anim_side = "fwd"
					else
						stop_anim_side = "bwd"
					end
				elseif r_dot > 0 then
					stop_anim_side = "l"
				else
					stop_anim_side = "r"
				end

				local stop_pose = nil
				stop_pose = (not self._action_desc.end_pose or self._action_desc.end_pose) and (self._ext_anim.pose or self._fallback_pose)

				if stop_pose ~= self._ext_anim.pose then
					local pose_redir_res = self._ext_movement:play_redirect(stop_pose)

					if not pose_redir_res then
						--debug_pause_unit(self._unit, "STOP POSE FAIL!!!", self._unit, stop_pose)
					end
				end

				local stop_dis = self._anim_movement[stop_pose]["run_stop_" .. stop_anim_side]

				if stop_dis and end_dis < stop_dis then
					self._stop_anim_side = stop_anim_side
					self._stop_anim_fwd = stop_anim_fwd
					self._stop_dis = stop_dis

					self:_set_updator("_upd_stop_anim_first_frame")
				end
			end
		elseif self._walk_turn and not self._chk_stop_dis then
			local end_dis = mvec3_dis(self._curve_path[self._curve_path_index + 1], self._last_pos)

			if end_dis < 45 then
				self:_set_updator("_upd_walk_turn_first_frame")
			end
		end

		local pose = self._stance.values[4] > 0 and "wounded" or self._ext_anim.pose or self._fallback_pose
		local real_velocity = self._cur_vel
		local variant = self._haste

		if variant == "run" and not self._no_walk then
			if self._ext_anim.sprint then
				if real_velocity > 480 and self._ext_anim.pose == "stand" then
					variant = "sprint"
				elseif real_velocity > 250 then
					variant = "run"
				else
					variant = "walk"
				end
			elseif self._ext_anim.run then
				if not self._walk_anim_velocities[pose] then
					--debug_pause_unit(self._unit, "No walk anim velocities for pose:", pose, inspect(self._walk_anim_velocities), self._unit)
				elseif not self._walk_anim_velocities[pose][self._stance.name] then
					--debug_pause_unit(self._unit, "No walk anim velocities for (pose, stance name):", pose, self._stance.name, inspect(self._walk_anim_velocities), inspect(self._walk_anim_velocities[pose]), self._unit)
				elseif real_velocity > 530 and self._walk_anim_velocities[pose] and self._walk_anim_velocities[pose][self._stance.name] and self._walk_anim_velocities[pose][self._stance.name].sprint and self._ext_anim.pose == "stand" then
					variant = "sprint"
				elseif real_velocity > 250 then
					variant = "run"
				else
					variant = "walk"
				end
			elseif real_velocity > 530 and self._walk_anim_velocities[pose][self._stance.name].sprint and self._ext_anim.pose == "stand" then
				variant = "sprint"
			elseif real_velocity > 300 then
				variant = "run"
			else
				variant = "walk"
			end
		end

		if not safe_get_value(self._walk_anim_velocities, pose, self._stance.name, variant, wanted_walk_dir) then
			--debug_pause("Boom...", self._common_data.unit, "pose", pose, "stance", self._stance.name, "variant", variant, "wanted_walk_dir", wanted_walk_dir, self._machine:segment_state(Idstring("base")))

			if not safe_get_value(self._walk_anim_velocities, pose, self._stance.name) and self._stance.name == "ntl" then
				self._stance.name = "cbt"
			end

			while not safe_get_value(self._walk_anim_velocities, pose, self._stance.name, variant) do
				if variant == "sprint" then
					variant = "run"
				end

				if variant == "run" then
					variant = "walk"
				end
			end

			if not safe_get_value(self._walk_anim_velocities, pose, self._stance.name, variant, wanted_walk_dir) then
				return
			end
		end

		self:_adjust_move_anim(wanted_walk_dir, variant)

		local anim_walk_speed = self._walk_anim_velocities[pose][self._stance.name][variant][wanted_walk_dir]
		local wanted_walk_anim_speed = real_velocity / anim_walk_speed

		self:_adjust_walk_anim_speed(dt, wanted_walk_anim_speed)
	end

	self:_set_new_pos(dt)
end

function CopActionWalk:_nav_chk_walk(t, dt, vis_state)
	local s_path = self._simplified_path
	local c_path = self._curve_path
	local c_index = self._curve_path_index
	local vel = nil

	if self._ext_anim.act and self._ext_anim.walk then
		local new_anim_pos = self._unit:get_animation_delta_position()
		local anim_displacement = mvector3.length(new_anim_pos)
		vel = anim_displacement / dt

		if vel == 0 then
			return
		end
	else
		vel = self:_get_current_max_walk_speed(self._ext_anim.move_side or "fwd")
	end

	local walk_dis = vel * dt
	local footstep_length = 200
	local nav_advanced = nil
	local cur_pos = self._common_data.pos
	local new_pos, new_c_index, complete, upd_footstep, reservation_failed = nil

	while not self._end_of_curved_path do
		new_pos, new_c_index, complete = self._walk_spline(c_path, self._last_pos, c_index, walk_dis + footstep_length, self:_husk_needs_speedup())
		upd_footstep = true

		if complete then
			if #s_path == 2 then
				self._end_of_curved_path = true

				if self._end_rot and not self._persistent then
					self._curve_path_end_rot = Rotation(mrotation.yaw(self._common_data.rot), 0, 0)
				end

				nav_advanced = true

				break
			elseif self._next_is_nav_link then
				self._end_of_curved_path = true
				self._nav_link_rot = Rotation(self._next_is_nav_link.element:value("rotation"), 0, 0)
				self._curve_path_end_rot = Rotation(mrotation.yaw(self._common_data.rot), 0, 0)

				break
			else
				self:_advance_simplified_path()

				local next_pos = self._nav_point_pos(s_path[2])
				
				if not self._sync then --we have points ahead of our current one, can we shorten that?
					if self:_husk_needs_speedup() then
						local end_of_path = self._nav_point_pos(self._simplified_path[#self._simplified_path])
						self._simplified_path = {
							mvec3_cpy(end_of_path),
							mvec3_cpy(end_of_path)
						}
						
						s_path = self._simplified_path
							
						next_pos = self._nav_point_pos(s_path[2])
					elseif #s_path > 2  then
						local ray_params = {
							tracker_from = self._common_data.nav_tracker,
							pos_to = self._nav_point_pos(self._simplified_path[#self._simplified_path])
						}
						
						if not managers.navigation:raycast(ray_params) then
							self._simplified_path = {
								mvec3_cpy(self._common_data.pos),
								self._simplified_path[#self._simplified_path]
							}
							
							s_path = self._simplified_path
							
							next_pos = self._nav_point_pos(s_path[2])
						end
					end
				elseif self._sync and not self._action_desc.path_simplified and not self._next_is_nav_link and s_path[3] and not self:_reserve_nav_pos(next_pos, self._nav_point_pos(s_path[3]), self._nav_point_pos(c_path[#c_path]), vel) then
					-- Nothing
				end

				if not s_path[1].x then
					--debug_pause_unit(self._unit, "[CopActionWalk:_nav_chk_walk] missed nav_link", self._unit, inspect(s_path))

					s_path[1] = self._nav_point_pos(s_path[1])
				end

				local dis_sq = mvec3_dis_sq(s_path[1], next_pos)
				local new_c_path = nil

				if dis_sq > 490000 and not self._action_desc.path_simplified and self._ext_base:lod_stage() == 1 then
					new_c_path = self:_calculate_curved_path(s_path, 1, 1)
				else
					new_c_path = {
						s_path[1],
						next_pos
					}
				end

				local i = #c_path - 1

				while c_index <= i do
					table.insert(new_c_path, 1, c_path[i])

					i = i - 1
				end

				self._curve_path = new_c_path
				self._curve_path_index = 1
				c_path = self._curve_path
				c_index = 1

				if self._sync then
					self:_send_nav_point(next_pos)
				end

				nav_advanced = true
			end
		else
			break
		end
	end

	if upd_footstep then
		self._footstep_pos = new_pos:with_z(cur_pos.z)
	end

	local wants_walk_turn = nil

	if not reservation_failed then
		local wanted_vel = nil

		if self._turn_vel and vis_state == 1 then
			mvec3_set(tmp_vec1, c_path[c_index + 1])
			mvec3_set_z(tmp_vec1, mvec3_z(cur_pos))

			local dis = mvec3_dis_sq(tmp_vec1, cur_pos)

			if dis < 4900 then
				wanted_vel = math.lerp(self._turn_vel, vel, dis / 4900)
			end
		end

		wanted_vel = wanted_vel or vel

		if self._start_run then
			local delta_pos = self._common_data.unit:get_animation_delta_position()
			walk_dis = mvec3_len(delta_pos)
			self._cur_vel = walk_dis / dt
			self._cur_vel = math_min(self:_get_current_max_walk_speed(self._ext_anim.move_side or "fwd"), math_max(walk_dis / dt, self._start_max_vel))

			if self._cur_vel < self._start_max_vel then
				self._cur_vel = self._start_max_vel
				walk_dis = self._cur_vel * dt
			else
				self._start_max_vel = self._cur_vel
			end
		else
			local c_vel = self._cur_vel

			if c_vel ~= wanted_vel then
				local adj = vel * (c_vel < wanted_vel and 1.5 or 4) * dt
				c_vel = math.step(c_vel, wanted_vel, adj)
				self._cur_vel = c_vel
			end

			walk_dis = c_vel * dt
		end

		new_pos, new_c_index, complete = self._walk_spline(c_path, self._last_pos, c_index, walk_dis)

		if complete then
			if self._next_is_nav_link then
				self._end_of_path = true

				if self._sync then
					if alive(self._next_is_nav_link.c_class) then
						local delay = self._next_is_nav_link.element:nav_link_delay()

						if delay > 0 then
							self._next_is_nav_link.c_class:set_delay_time(t + delay)
						end
					else
						--debug_pause_unit(self._unit, "dead nav_link", self._unit)
					end
				end
			elseif #s_path == 2 then
				self._end_of_path = true
			end
		elseif new_c_index ~= self._curve_path_index or nav_advanced then
			local future_pos = c_path[new_c_index + 2]
			local next_pos = c_path[new_c_index + 1]
			local back_pos = c_path[new_c_index]
			local cur_vec = tmp_vec2

			mvec3_set(cur_vec, next_pos)
			mvec3_sub(cur_vec, back_pos)
			mvec3_set_z(cur_vec, 0)

			if future_pos then
				mvec3_norm(cur_vec)

				local next_vec = tmp_vec1

				mvec3_set(next_vec, future_pos)
				mvec3_sub(next_vec, next_pos)
				mvec3_set_z(next_vec, 0)

				local future_dis_flat = mvec3_norm(next_vec)
				local turn_dot = mvec3_dot(cur_vec, next_vec)

				if self._haste ~= "run" and turn_dot > -0.7 and turn_dot < 0.7 and not self._attention_pos and future_dis_flat > 80 and self._common_data.stance.name == "ntl" and mvec3_dot(self._common_data.fwd, cur_vec) > 0.97 then
					self._walk_turn = true
				else
					turn_dot = turn_dot * turn_dot
					local dot_lerp = math_max(0, turn_dot)
					local turn_vel = math.lerp(math.min(vel, 100), self:_get_current_max_walk_speed(self._ext_anim.move_side or "fwd"), dot_lerp)
					self._turn_vel = turn_vel
					self._walk_turn = nil
				end
			else
				if vis_state < 3 and self._end_of_curved_path and self._ext_anim.run and not self._was_interrupted and not self._NO_RUN_STOP and not self._no_walk and mvec3_dis(c_path[new_c_index + 1], new_pos) >= 210 then
					self._chk_stop_dis = 210
				elseif self._chk_stop_dis then
					self._chk_stop_dis = nil
				end

				self._walk_turn = nil
			end
		end

		self._curve_path_index = new_c_index
		self._last_pos = mvec3_cpy(new_pos)
	end
end

function CopActionWalk:append_nav_point(nav_point)
	if not nav_point.x then
		function nav_point.element.value(element, name)
			return element[name]
		end

		function nav_point.element.nav_link_wants_align_pos(element)
			return element.from_idle
		end
	end

	local is_initialized = self._init_called

	if not is_initialized then
		self._simplified_path = self._simplified_path or {}
	end

	table.insert(self._simplified_path, nav_point)
	
	--on appending, make sure we can't shorten the path somehow.
	
	if is_initialized and self.update ~= self._upd_nav_link and self.update ~= self._upd_nav_link_first_frame and self.update ~= self._upd_nav_link_blend_to_idle and self.update ~= self._upd_stop_anim_first_frame and self.update ~= self._upd_stop_anim and self.update ~= self._upd_walk_turn_first_frame and self.update ~= self._upd_walk_turn then
		if self:_husk_needs_speedup() then
			self._next_is_nav_link = nil
			self._end_of_curved_path = nil
			self._end_of_path = nil
			self._walk_turn = nil
			self._curve_path_index = 1
			self._curve_path = {
				self._nav_point_pos(nav_point),
				self._nav_point_pos(nav_point)
			}
			self._simplified_path = {
				self._nav_point_pos(nav_point),
				self._nav_point_pos(nav_point)
			}
		else
			local ray_params = {
				tracker_from = self._common_data.nav_tracker,
				pos_to = self._nav_point_pos(nav_point)
			}
			
			if not managers.navigation:raycast(ray_params) then
				self._next_is_nav_link = nil
				self._end_of_curved_path = nil
				self._end_of_path = nil
				self._walk_turn = nil
				self._curve_path_index = 1
				self._curve_path = {
					mvec3_cpy(self._common_data.pos),
					self._nav_point_pos(nav_point)
				}
				self._simplified_path = {
					mvec3_cpy(self._common_data.pos),
					nav_point
				}
			end
		end
	end

	if is_initialized and #self._simplified_path == 2 and not nav_point.x then
		self._next_is_nav_link = nav_point
	end

	if is_initialized then
		if self.update == self._upd_wait or self.update == self._upd_start_anim_first_frame or self.update == self._upd_start_anim then
			self._end_of_curved_path = nil
			self._end_of_path = nil
		elseif not self._next_is_nav_link then
			self._end_of_curved_path = nil
		end
	end
end

function CopActionWalk:stop()
	local is_initialized = self._init_called

	if not is_initialized then
		self._simplified_path = self._simplified_path or {}
	end

	local s_path = self._simplified_path

	if s_path[#s_path] and not s_path[#s_path].x then
		s_path[#s_path] = self._nav_point_pos(s_path[#s_path])
	end

	local pos = s_path[#s_path]
	self._persistent = false

	if is_initialized then
		if self.update == self._upd_wait or self.update == self._upd_start_anim_first_frame or self.update == self._upd_start_anim then
			self._end_of_curved_path = nil
			self._end_of_path = nil
		elseif not self._next_is_nav_link then
			self._end_of_curved_path = nil
		end
	end
	
	--do we have already have an action queued ahead of us? we should probably teleport into position.
	if is_initialized and self.update ~= self._upd_nav_link and self.update ~= self._upd_nav_link_first_frame and self.update ~= self._upd_nav_link_blend_to_idle and self.update ~= self._upd_stop_anim_first_frame and self.update ~= self._upd_stop_anim and self.update ~= self._upd_walk_turn_first_frame and self.update ~= self._upd_walk_turn then
		if self:_husk_needs_speedup() then
			self._next_is_nav_link = nil
			self._end_of_curved_path = nil
			self._end_of_path = nil
			self._walk_turn = nil
			self._curve_path_index = 1
			local stop_pos = mvec3_cpy(pos)
			self._curve_path = {
				mvec3_cpy(stop_pos),
				stop_pos
			}
			self._simplified_path = {
				mvec3_cpy(stop_pos),
				stop_pos
			}
		end
	end
end

function CopActionWalk:_upd_wait_for_full_blend(t)
	if self._ext_anim.needs_idle and not self._ext_anim.to_idle then
		local res = self._ext_movement:play_redirect("exit")
		res = res or self._ext_movement:play_redirect("idle")

		if not res then
			--debug_pause_unit(self._unit, "[CopActionWalk:_upd_wait_for_full_blend] idle redirect failed in", self._machine:segment_state(idstr_base), self._unit)

			return
		end

		self._ext_movement:spawn_wanted_items()
	end

	if not self._ext_anim.to_idle and self._ext_anim.idle_full_blend then
		self._waiting_full_blend = nil

		if self:_init() then
			self._ext_movement:drop_held_items()

			if self.update == self._upd_wait_for_full_blend then
				self:_set_updator(nil)
			end
		else
			if self._sync then
				--self._ext_network:send("action_walk_nav_point", mvec3_cpy(self._ext_movement:m_pos()))
				self._ext_movement:action_request({
					body_part = 2,
					type = "idle"
				})
			end

			return
		end
	else
		self._unit:m_rotation(temp_rot1)
		self._unit:m_position(tmp_vec1)
		self._ext_movement:set_m_rot(temp_rot1)
		self._ext_movement:set_m_pos(tmp_vec1)
	end
end

function CopActionWalk:_upd_nav_link(t)
	if self._ext_anim.act and not self._ext_anim.walk then
		self._last_pos = self._unit:position()

		self._unit:m_rotation(temp_rot1)
		self._ext_movement:set_m_rot(temp_rot1)
		self._ext_movement:set_m_pos(self._last_pos)
	elseif self._simplified_path[2] then
		self._common_data.unit:set_driving("script")

		self._changed_driving = nil
		self._simplified_path[1] = mvec3_cpy(self._common_data.pos)
		
		local needs_curve_path = true

		if self._sync then
			local ray_params = {
				tracker_from = self._common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._simplified_path[2])
			}
			local res = managers.navigation:raycast(ray_params)

			if res then
				local end_pos = self._nav_link.c_class:end_position()

				table.insert(self._simplified_path, 2, end_pos)

				self._next_is_nav_link = nil
			end

			--self:_send_nav_point(self._simplified_path[2])

			if self._nav_link.element:nav_link_delay() > 0 then
				self._nav_link.c_class:set_delay_time(0)
			end
	
		--attempt to simplify the path for clients if they have fallen behind and have finished doing the nav link, 
		--as well as teleport if there is an action already queued
		elseif self:_husk_needs_speedup() then 
			self._next_is_nav_link = nil
			self._end_of_curved_path = nil
			self._end_of_path = nil
			self._walk_turn = nil
			self._curve_path_index = 1
			
			self._curve_path = {
				self._nav_point_pos(self._simplified_path[#self._simplified_path]),
				self._nav_point_pos(self._simplified_path[#self._simplified_path])
			}
			
			self._simplified_path = {
				self._nav_point_pos(self._simplified_path[#self._simplified_path]),
				self._nav_point_pos(self._simplified_path[#self._simplified_path])
			}
			
			needs_curve_path = nil
		elseif #self._simplified_path > 2 then 
			local ray_params = {
				tracker_from = self._common_data.nav_tracker,
				pos_to = self._nav_point_pos(self._simplified_path[#self._simplified_path])
			}
			
			if not managers.navigation:raycast(ray_params) then
				self._simplified_path = {
					mvec3_cpy(self._common_data.pos),
					self._simplified_path[#self._simplified_path]
				}
			end
		end
		
		if needs_curve_path then
			if mvec3_dis(self._simplified_path[1], self._nav_point_pos(self._simplified_path[2])) > 400 and self._ext_base:lod_stage() == 1 then
				self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1, self._common_data.fwd)
			else
				self._curve_path = {
					mvec3_cpy(self._simplified_path[1]),
					self._nav_point_pos(self._simplified_path[2])
				}
			end
		end

		self._curve_path_index = 1

		if self._nav_link_invul_on then
			self._nav_link_invul_on = nil

			self._common_data.ext_damage:set_invulnerable(false)
		end

		self._nav_link = nil
		self._cur_vel = 0
		self._last_vel_z = 0

		self:_set_blocks(self._old_blocks)

		self._old_blocks = nil

		self:_set_updator(nil)
		self:_chk_correct_pose()
		self:update(t)
	elseif not self._persistent then
		self._simplified_path[1] = mvec3_cpy(self._common_data.pos)

		self._common_data.unit:set_driving("script")

		self._changed_driving = nil
		self._end_of_curved_path = true

		if self._nav_link_invul_on then
			self._nav_link_invul_on = nil

			self._common_data.ext_damage:set_invulnerable(false)
		end

		if self._sync and self._nav_link.element:nav_link_delay() > 0 then
			self._nav_link.c_class:set_delay_time(0)
		end

		self._nav_link = nil
		self._cur_vel = 0
		self._last_vel_z = 0

		self:_set_blocks(self._old_blocks)

		self._old_blocks = nil

		self:_chk_correct_pose()

		self._expired = true

		if self._end_rot then
			self._ext_movement:set_rotation(self._end_rot)
		end
	end
end

function CopActionWalk:_chk_falling_behind()
	if not self._persistent then
		return true
	end

	if #self._simplified_path > 2 then --check how much distance there is in the path that is left, are we falling behind?
		local sz_path = #self._simplified_path
		local prev_pos = self._common_data.pos
		local i = 2
		local dis_error_total = 0

		while i <= sz_path do
			local next_pos = self._nav_point_pos(self._simplified_path[i])
			dis_error_total = dis_error_total + mvec3_dis_sq(prev_pos, next_pos)
			prev_pos = next_pos
			i = i + 1
		end

		if dis_error_total > 90000 then
			return true
		end
	end
end

function CopActionWalk:_husk_needs_speedup()
	if Network:is_server() or Global.game_settings.single_player then
		return
	end

	if self._was_interrupted then
		return true
	end
	
	if self._ext_movement._queued_actions and next(self._ext_movement._queued_actions) then
		local queued_actions = self._ext_movement._queued_actions
		for i = #queued_actions, 1, -1 do
			if queued_actions[i].type == "act" and queued_actions[i].body_part ~= 3 and not queued_actions[i].host_expired then
				return true
			end
			
			if queued_actions[i].type == "walk" then
				local queued_nav_path = queued_actions[i].nav_path
				local too_far, dis_error_total
				
				if queued_nav_path then
					local prev_pos = self._common_data.pos
					local i = 1
					local dis_error_total = 0

					while i <= #queued_nav_path do
						local next_pos
						local nav_point = queued_nav_path[i]
						
						if nav_point.x then
							next_pos = nav_point
						elseif nav_point.element then
							next_pos = nav_point.element.position
						end
						
						if next_pos then
							dis_error_total = dis_error_total + mvec3_dis_sq(prev_pos, next_pos)
							
							if dis_error_total > 90000 then
								return true
							end
						end
						
						i = i + 1
					end
				end
			end
		end
	end
end

function CopActionWalk:_get_current_max_walk_speed(move_dir)
	move_dir = self._move_dir_convert[move_dir] or move_dir
	local pose = self._ext_anim.pose or self._fallback_pose
	local speed = self._common_data.char_tweak.move_speed[pose][self._haste][self._stance.name][move_dir]
	local speed_modifier = self._ext_movement:speed_modifier()

	if speed_modifier then
		speed = speed * speed_modifier
	end

	local is_host = Network:is_server() or Global.game_settings.single_player

	if not is_host then
		if self:_husk_needs_speedup() or self:_chk_falling_behind() then --speed up enemies if they have too many nav points ahead
			local lod = self._ext_base:lod_stage()
			local lod_multiplier = 1 + (Unit.occluded(self._unit) and 1 or CopActionWalk.lod_multipliers[lod] or 1)
			speed = speed * lod_multiplier
		elseif not managers.groupai:state():enemy_weapons_hot() then
			speed = speed * tweak_data.network.stealth_speed_boost
		end
	end

	return speed
end

function CopActionWalk._walk_spline(path, pos, index, walk_dis, desynced)
	while true do
		if desynced then
			return path[#path], #path, true
		end
	
		mvec3_set(tmp_vec1, path[index + 1])
		mvec3_sub(tmp_vec1, path[index])
		mvec3_set_z(tmp_vec1, 0)

		local dis = mvec3_norm(tmp_vec1)

		mvec3_set(tmp_vec2, pos)
		mvec3_sub(tmp_vec2, path[index])
		mvec3_set_z(tmp_vec2, 0)

		local my_dis = mvec3_dot(tmp_vec2, tmp_vec1)

		if dis == 0 or dis <= my_dis + walk_dis and walk_dis >= 0 then
			if index == #path - 1 then
				return path[index + 1], index, true
			else
				index = index + 1
			end
		elseif my_dis + walk_dis < 0 and walk_dis < 0 then
			if index == 1 then
				return path[index], index
			else
				index = index - 1
			end
		else
			local return_vec = Vector3()

			mvec3_lerp(return_vec, path[index], path[index + 1], (walk_dis + my_dis) / dis)

			return return_vec, index
		end
	end
end

function CopActionWalk:_upd_wait(t)
	local dt = t - self._last_upd_t
	self._last_upd_t = TimerManager:game():time()

	if self._ext_anim.move then
		self:_stop_walk()
	end

	if not self._sync and not self._simplified_path[2] and (not self._end_of_curved_path or not self._persistent) then
		table.insert(self._simplified_path, mvec3_cpy(self._simplified_path[1]))
	end
	
	if not self._ext_anim.move and self._attention_pos then
		local face_fwd = tmp_vec1
		
		mvec3_set(face_fwd, self._attention_pos)
		mvec3_sub(face_fwd, self._common_data.pos)
		
		mrot_lookat(temp_rot1, face_fwd, math.UP)

		rot_new = temp_rot1

		mrot_slerp(rot_new, self._common_data.rot, rot_new, math.min(1, dt * 5))
		
		self._ext_movement:set_rotation(rot_new)
	end

	if not self._end_of_curved_path or not self._persistent then
		self._curve_path_index = 1

		if not self._simplified_path[2].x then
			self._next_is_nav_link = self._simplified_path[2]
		end

		self:_chk_start_anim(self._nav_point_pos(self._simplified_path[2]))

		if self._start_run then
			self:_set_updator("_upd_start_anim_first_frame")
		else
			self:_set_updator(nil)
		end

		self._curve_path = {
			self._nav_point_pos(self._simplified_path[1]),
			self._nav_point_pos(self._simplified_path[2])
		}
		self._cur_vel = 0
	end
end

function CopActionWalk:on_exit()
	if self._expired and self._end_rot then
		self._ext_movement:set_rotation(self._end_rot)
	end

	if self._root_blend_disabled then
		self._ext_movement:set_root_blend(true)
	end

	if self._changed_driving then
		self._common_data.unit:set_driving("script")

		self._changed_driving = nil
	end

	if self._expired and self._common_data.ext_anim.move then
		self:_stop_walk()
	end

	self:_set_ik_modifier_state(false)
	self._ext_movement:drop_held_items()

	if self._sync then
		if not self._expired then
			self._ext_network:send("action_walk_nav_point", mvec3_cpy(self._ext_movement:m_pos()))
		end

		self._ext_network:send("action_walk_stop")
	else
		self._ext_movement:set_m_host_stop_pos(self._ext_movement:m_pos())
	end

	if self._nav_link_invul_on then
		self._nav_link_invul_on = nil

		self._common_data.ext_damage:set_invulnerable(false)
	end

	if Network:is_server() then
		self._unit:brain():rem_pos_rsrv("move_dest")
	end
end