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
	
	if is_initialized and #self._simplified_path >= 3 and self.update ~= self._upd_nav_link and self.update ~= self._upd_nav_link_first_frame and self.update ~= self._upd_nav_link_blend_to_idle and self.update ~= self._upd_stop_anim_first_frame and self.update ~= self._upd_stop_anim and self.update ~= self._upd_walk_turn_first_frame and self.update ~= self._upd_walk_turn then
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

	if is_initialized and #s_path >= 3 and self.update ~= self._upd_nav_link and self.update ~= self._upd_nav_link_first_frame and self.update ~= self._upd_nav_link_blend_to_idle and self.update ~= self._upd_stop_anim_first_frame and self.update ~= self._upd_stop_anim and self.update ~= self._upd_walk_turn_first_frame and self.update ~= self._upd_walk_turn then
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
			debug_pause_unit(self._unit, "[CopActionWalk:_upd_wait_for_full_blend] idle redirect failed in", self._machine:segment_state(idstr_base), self._unit)

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

		if mvec3_dis(self._simplified_path[1], self._nav_point_pos(self._simplified_path[2])) > 400 and self._ext_base:lod_stage() == 1 then
			self._curve_path = self:_calculate_curved_path(self._simplified_path, 1, 1, self._common_data.fwd)
		else
			self._curve_path = {
				mvec3_cpy(self._simplified_path[1]),
				self._nav_point_pos(self._simplified_path[2])
			}
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

	if #self._simplified_path > 2 then
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
			if queued_actions.body_part == 1 then
				return true
			end
			
			if queued_actions[i].type == "walk" then
				if queued_actions[i].persistent then
					if mvec3_dis(self._nav_point_pos(queued_actions[i].nav_path[#queued_actions[i].nav_path]), self._nav_point_pos(self._simplified_path[#self._simplified_path])) > 500 then
						return true
					end
				else
					return true
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
		if self:_husk_needs_speedup() or self:_chk_falling_behind() then
			local lod = self._ext_base:lod_stage()
			local lod_multiplier = 1 + (Unit.occluded(self._unit) and 1 or CopActionWalk.lod_multipliers[lod] or 1)
			speed = speed * lod_multiplier
		elseif not managers.groupai:state():enemy_weapons_hot() then
			speed = speed * tweak_data.network.stealth_speed_boost
		end
	end

	return speed
end