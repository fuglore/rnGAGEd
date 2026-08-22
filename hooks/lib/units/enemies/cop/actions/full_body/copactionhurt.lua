local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_set_l = mvector3.set_length
local mvec3_sub = mvector3.subtract
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_dot = mvector3.dot
local mvec3_cross = mvector3.cross
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_rand_orth = mvector3.random_orthogonal
local mvec3_dis = mvector3.distance
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()

function CopActionHurt:_upd_hurt(t)
	if self._shooting_hurt and not alive(self._weapon_unit) then
		self._shooting_hurt = false
		self._weapon_unit = false
	end

	local dt = TimerManager:game():delta_time()

	if self._ext_anim.hurt or self._ext_anim.death then
		if self._shooting_hurt then
			local weap_unit = self._weapon_unit
			local weap_unit_base = weap_unit:base()
			local shoot_from_pos = weap_unit:position()
			local shoot_fwd = weap_unit:rotation():y()

			weap_unit_base:trigger_held(shoot_from_pos, shoot_fwd, 1, true)

			if weap_unit_base.clip_empty and weap_unit_base:clip_empty() then
				self._shooting_hurt = false

				weap_unit_base:stop_autofire()
			end
		end

		self._last_pos = self:_get_pos_clamped_to_graph(true)

		CopActionWalk._set_new_pos(self, dt)

		local new_rot = self._unit:get_animation_delta_rotation()
		new_rot = self._common_data.rot * new_rot

		mrotation.set_yaw_pitch_roll(new_rot, new_rot:yaw(), 0, 0)

		if self._ext_anim.death then
			local rel_prog = math.clamp(self._machine:segment_relative_time(Idstring("base")), 0, 1)

			if self._floor_normal == nil then
				self._floor_normal = Vector3(0, 0, 1)
			end

			local normal = math.lerp(math.UP, self._floor_normal, rel_prog)
			local fwd = new_rot:y()

			mvec3_cross(tmp_vec1, fwd, normal)
			mvec3_cross(fwd, normal, tmp_vec1)

			new_rot = Rotation(fwd, normal)
		end

		self._ext_movement:set_rotation(new_rot)
	else
		if self._shooting_hurt then
			self._shooting_hurt = false

			self._weapon_unit:base():stop_autofire()
		end

		if self._hurt_type == "death" then
			self._died = true
		else
			self._expired = true
		end
	end
end

function CopActionHurt:clbk_shooting_hurt()
	self._delayed_shooting_hurt_clbk_id = nil

	if not alive(self._weapon_unit) then
		return
	end

	local fire_obj = self._weapon_unit:base().fire_object and self._weapon_unit:base():fire_object()

	if fire_obj then
		local position = fire_obj:position()
		local rotation = fire_obj:rotation():y()
		self._weapon_unit:base():singleshot(position, rotation, 1, true, nil, nil, nil, nil)
	end
end