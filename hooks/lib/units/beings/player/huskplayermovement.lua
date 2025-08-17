local mvec3_set = mvector3.set
local mvec3_sub = mvector3.subtract
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_div = mvector3.divide
local mvec3_norm = mvector3.normalize
local mvec3_len = mvector3.length
local mvec3_dot = mvector3.dot
local mvec3_set_z = mvector3.set_z
local mvec3_z = mvector3.z
local mvec3_set_len = mvector3.set_length
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
local tmp_rot1 = Rotation()
local tmp_rot2 = Rotation()
local tmp_rot3 = Rotation()

local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_z = mvector3.z
local mvec3_cpy = mvector3.copy
local mvec3_dist_sq = mvector3.distance_sq
local mvec3_lerp = mvector3.lerp
local mvec3_add = mvector3.add
local mvec3_sub = mvector3.subtract
local mvec3_mul = mvector3.multiply
local math_lerp = math.lerp
local math_random = math.random

local mrot_look = mrotation.set_look_at

local math_up = math.UP
local math_clamp = math.clamp
local math_point_on_line = math.point_on_line

local table_insert = table.insert
local table_remove = table.remove

local left_hand_str = Idstring("LeftHandMiddle2")
local right_hand_str = Idstring("RightHandMiddle2")

function HuskPlayerMovement:_update_air_time(t, dt)
	if self._in_air then
		self._check_air_time = 0
		self._air_time = self._air_time or 0
		self._air_time = self._air_time + dt

		if self._air_time > 0.5 then
			local on_ground = self:_chk_ground_ray(self._m_pos)

			if on_ground then
				self._in_air = false
				self._air_time = 0
			end
		end
	else
		self._air_time = 0
		
		self._check_air_time = self._check_air_time or 0
		self._check_air_time = self._check_air_time - dt
		
		if not self._check_air_time or self._check_air_time <= 0 then
			self._check_air_time = 1 / tweak_data.network.player_tick_rate
			
			local on_ground = self:_chk_ground_ray(self._m_pos)

			if not on_ground then
				if not self._bleedout then
					self:play_redirect("jump")
				end
				
				self._in_air = true
			end
		end
	end
end

function HuskPlayerMovement:_get_max_move_speed(run)
	local my_tweak = tweak_data.player.movement_state.standard
	local move_speed = nil

	if self._synced_max_speed then
		move_speed = self._synced_max_speed
	elseif self._pose_code == 2 then
		move_speed = my_tweak.movement.speed.CROUCHING_MAX * (self._unit:base():upgrade_value("player", "crouch_speed_multiplier") or 1)
	elseif run then
		move_speed = my_tweak.movement.speed.RUNNING_MAX * (self._unit:base():upgrade_value("player", "run_speed_multiplier") or 1)
	else
		move_speed = my_tweak.movement.speed.STANDARD_MAX * (self._unit:base():upgrade_value("player", "walk_speed_multiplier") or 1)
	end

	if self._in_air then
		local t = self._air_time or 0
		local air_speed = math.exp(t * self:gravity() / self:terminal_velocity())
		air_speed = air_speed * self:gravity()
		air_speed = math.abs(air_speed)
		move_speed = math.max(move_speed, air_speed)
		move_speed = math.min(move_speed, math.abs(self:terminal_velocity()))
	end

	local zipline = self._zipline and self._zipline.enabled and self._zipline.zipline_unit and self._zipline.zipline_unit:zipline()

	if zipline then
		local step = 100
		local t = math.clamp((self._zipline.t or 0) / zipline:total_time(), 0, 1)
		local speed = 1.1 * zipline:speed_at_time(t, 1 / step) / step
		move_speed = math.max(speed * zipline:speed(), move_speed)
	end

	local path_length = #self._movement_path - tweak_data.network.player_path_interpolation

	if path_length > 0 then
		local speed_boost = 1 + path_length / tweak_data.network.player_tick_rate
		move_speed = move_speed * math.clamp(speed_boost, 1, 3)
	end

	return move_speed
end

local cbt_stance_code = 3

function HuskPlayerMovement:_sync_look_direction(t, dt)
	self._smooth_look = self._smooth_look or {
		current = Vector3(),
		target = Vector3()
	}

	if self._sync_look_dir then
		mvec3_set(self._smooth_look.target, self._sync_look_dir)

		self._sync_look_dir = nil
	end

	local st = self._stance.owner_stance_code == cbt_stance_code and 20 or 15

	mvector3.step(self._smooth_look.current, self._smooth_look.current, self._smooth_look.target, dt * st)
	mvec3_norm(self._smooth_look.current)

	if self._smooth_look.current then
		local tar_look_dir = tmp_vec1

		mvec3_set(tar_look_dir, self._smooth_look.current)

		local wait_for_turn = nil
		local hips_fwd = tmp_vec2

		mrotation.y(self._m_rot, hips_fwd)

		local hips_err_spin = tar_look_dir:to_polar_with_reference(hips_fwd, math.UP).spin
		local max_spin = 90
		local min_spin = -90

		if max_spin < hips_err_spin or hips_err_spin < min_spin then
			wait_for_turn = true

			if max_spin < hips_err_spin then
				mvector3.rotate_with(tar_look_dir, Rotation(max_spin - hips_err_spin))
			else
				mvector3.rotate_with(tar_look_dir, Rotation(min_spin - hips_err_spin))
			end
		end

		local error_angle = tar_look_dir:angle(self._look_dir)
		local rot_speed_rel = math.pow(math.min(error_angle / 90, 1), 0.5)
		local rot_speed = math.lerp(40, 360, rot_speed_rel)
		rot_speed = rot_speed * (self._stance.owner_stance_code == cbt_stance_code and 10 or 5)
		local rot_amount = math.min(rot_speed * dt, error_angle)
		local error_axis = self._look_dir:cross(tar_look_dir)
		local rot_adj = Rotation(error_axis, rot_amount)
		self._look_dir = self._look_dir:rotate_with(rot_adj)
		local look_dir = self._look_dir

		if self._arm_animator:enabled() and self._arm_animator:is_facing_allowed() then
			look_dir = self._arm_animator:facing_dir()
		end

		self._look_modifier:set_target_y(look_dir)

		if rot_amount == error_angle and not wait_for_turn then
			-- Nothing
		end
	end
end