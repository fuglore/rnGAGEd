local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
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
local rope_vec1 = Vector3()
local rope_vec2 = Vector3()

function CopActionTase:update(t)
	if self._expired then
		return
	end

	local shoot_from_pos = self._ext_movement:m_head_pos()
	local target_dis = nil
	local target_vec = temp_vec1
	local target_pos
	
	if self._tasing_player then
		target_pos = self._attention.unit:movement():m_head_pos()
	else
		target_pos = temp_vec2
		self._attention.unit:character_damage():shoot_pos_mid(target_pos)
	end

	target_dis = mvector3.direction(target_vec, shoot_from_pos, target_pos)
	local target_vec_flat = target_vec:with_z(0)

	mvector3.normalize(target_vec_flat)

	local fwd_dot = mvector3.dot(self._common_data.fwd, target_vec_flat)

	if fwd_dot > 0.5 then
		if not self._modifier_on then
			self._modifier_on = true

			self._machine:force_modifier(self._modifier_name)

			self._mod_enable_t = t + 0.5
		end

		self._modifier:set_target_y(target_vec)
		mvec3_set(self._common_data.look_vec, target_vec)
	else
		if self._modifier_on then
			self._modifier_on = nil

			self._machine:allow_modifier(self._modifier_name)
		end

		if self._turn_allowed and not self._ext_anim.walk and not self._ext_anim.turn and not self._ext_movement:chk_action_forbidden("walk") then
			local spin = target_vec:to_polar_with_reference(self._common_data.fwd, math.UP).spin
			local abs_spin = math.abs(spin)

			if abs_spin > 27 then
				local new_action_data = {
					type = "turn",
					body_part = 2,
					angle = spin
				}

				self._ext_movement:action_request(new_action_data)
			end
		end

		target_vec = nil
	end

	if not self._ext_anim.reload then
		if self._ext_anim.equip then
			-- Nothing
		elseif self._discharging then
			if not self._tase_hit_effect then
				self._tase_hit_effect = World:effect_manager():spawn({
					force_synch = true,
					effect = Idstring("effects/payday2/particles/character/taser_hittarget"),
					position = shoot_from_pos,
					normal = math.UP
				})
			end
			
			local vis_ray = self._unit:raycast("ray", shoot_from_pos, target_pos, "slot_mask", self._line_of_fire_slotmask, "sphere_cast_radius", self._w_usage_tweak.tase_sphere_cast_radius, "ignore_unit", self._tasing_local_unit, "report")

			if not self._tasing_local_unit:movement():tased() or vis_ray then
				if self._tase_hit_effect then
					World:effect_manager():fade_kill(self._tase_hit_effect)
				end

				if Network:is_server() then
					self._expired = true
				else
					self._tasing_local_unit:movement():on_tase_ended()
					self._attention.unit:movement():on_targetted_for_attack(false, self._unit)

					self._discharging = nil
					self._tasing_player = nil
					self._tasing_local_unit = nil
					self.update = self._upd_empty
				end
			elseif not self._rope then
				CopActionTase._wire_brush = CopActionTase._wire_brush or Draw:brush(Color(0.12, 0.12, 0.12):with_alpha(1))
				
				local weapon_unit = self._ext_inventory:equipped_unit()
				self._weapon_unit = weapon_unit
				
				if self._weapon_unit then
					self._weapon_base = weapon_unit:base()
					local obj_fire_pos = self._weapon_base._obj_fire:position()
					self._rope = {
						reached = nil,
						dis_t = math.clamp(target_dis / self._w_usage_tweak.tase_distance, 0.05, 0.2),
						reach_t = t + math.clamp(target_dis / self._w_usage_tweak.tase_distance, 0.05, 0.2),
						from = obj_fire_pos:with_z(obj_fire_pos.z - 2)
					}
				end
			end
			
			if self._rope then
				local brush = CopActionTase._wire_brush
				local obj_fire_pos = self._weapon_base._obj_fire:position()
				self._rope.from = obj_fire_pos:with_z(obj_fire_pos.z - 2)
	
				if self._rope.reached then
					local rope_pos
					
					if self._tasing_player then
						rope_pos = target_pos:with_z(target_pos.z - 10)
					else
						rope_pos = target_pos:with_z(target_pos.z - 20)
					end
					
					if self._tase_hit_effect then
						World:effect_manager():move(self._tase_hit_effect, rope_pos)
					end
					
					local side_1 = rope_vec1
					local side_2 = rope_vec2
					mvec3_set(side_1, rope_pos)
					mvec3_set(side_2, rope_pos)
					
					if self._tasing_player then
						mvec3_add(side_1, self._attention.unit:movement():m_head_rot():z() * -30)
						mvec3_add(side_1, self._attention.unit:movement():m_head_rot():x() * 10)
						mvec3_add(side_2, self._attention.unit:movement():m_head_rot():z() * -30)
						mvec3_add(side_2, self._attention.unit:movement():m_head_rot():x() * -10)
					else
						mvec3_add(side_1, self._attention.unit:movement():m_right() * 10)
						mvec3_add(side_2, self._attention.unit:movement():m_right() * -10)
					end

					brush:cylinder(self._rope.from, side_1, 0.1)
					brush:sphere(side_1, 0.25)
					brush:cylinder(self._rope.from, side_2, 0.1)
					brush:sphere(side_2, 0.25)
				else
					if self._rope.reach_t < t then
						self._rope.reached = true
					end
					
					local t_left = self._rope.reach_t - t 
					local dis_t = self._rope.dis_t
					local lerp = 1 - math.clamp(t_left / dis_t, 0, 1)
					local rope_pos
					
					if self._tasing_player then
						rope_pos = target_pos:with_z(target_pos.z - 10)
					else
						rope_pos = target_pos:with_z(target_pos.z - 20)
					end
					
					local at1 = rope_vec1
					local at2 = rope_vec2
					mvec3_set(at1, rope_pos)
					mvec3_set(at2, rope_pos)
					
					if self._tasing_player then
						mvec3_add(at1, self._attention.unit:movement():m_head_rot():z() * -5)
						mvec3_add(at1, self._attention.unit:movement():m_head_rot():x() * 5)
						mvec3_add(at2, self._attention.unit:movement():m_head_rot():z() * -5)
						mvec3_add(at2, self._attention.unit:movement():m_head_rot():x() * -5)
					else
						mvec3_add(at1, self._attention.unit:movement():m_right() * 10)
						mvec3_add(at2, self._attention.unit:movement():m_right() * -10)
					end
					
					
					mvec3_lerp(at1, self._rope.from, at1, lerp)
					mvec3_lerp(at2, self._rope.from, at2, lerp)
					
					if self._tase_hit_effect then
						World:effect_manager():move(self._tase_hit_effect, at1)
					end
					
					brush:cylinder(self._rope.from, at1, 0.1)
					brush:sphere(at1, 0.25)
					brush:cylinder(self._rope.from, at2, 0.1)
					brush:sphere(at2, 0.25)
				end
			end
		elseif self._shoot_t and target_vec and self._common_data.allow_fire and self._shoot_t < t and self._mod_enable_t < t then
			if self._tase_effect then
				World:effect_manager():fade_kill(self._tase_effect)
			end

			self._tase_effect = World:effect_manager():spawn({
				force_synch = true,
				effect = Idstring("effects/payday2/particles/character/taser_thread"),
				parent = self._ext_inventory:equipped_unit():get_object(Idstring("fire"))
			})

			if self._tasing_local_unit and mvector3.distance(shoot_from_pos, target_pos) < self._w_usage_tweak.tase_distance then
				local record = managers.groupai:state():criminal_record(self._tasing_local_unit:key())

				if not record or record.status or self._tasing_local_unit:movement():chk_action_forbidden("hurt") or self._tasing_local_unit:movement():zipline_unit() then
					if Network:is_server() then
						self._expired = true
					end
				else
					local vis_ray = self._unit:raycast("ray", shoot_from_pos, target_pos, "slot_mask", self._line_of_fire_slotmask, "sphere_cast_radius", self._w_usage_tweak.tase_sphere_cast_radius, "ignore_unit", self._tasing_local_unit, "report")

					if not vis_ray then
						self._common_data.ext_network:send("action_tase_event", 3)

						local attack_data = {
							attacker_unit = self._unit
						}

						self._attention.unit:character_damage():damage_tase(attack_data)
						CopDamage._notify_listeners("on_criminal_tased", self._unit, self._attention.unit)

						self._discharging = true
						self._tasered_sound = self._unit:sound():play("tasered_3rd", nil)

						if self._unit:base():lod_stage() == 1 then
							self._ext_movement:play_redirect("recoil_single")
						end

						self._shoot_t = nil
					end
				end
			elseif not self._tasing_local_unit then
				self._tasered_sound = self._unit:sound():play("tasered_3rd", nil)

				if self._unit:base():lod_stage() == 1 then
					self._ext_movement:play_redirect("recoil_single")
				end

				self._shoot_t = nil
			end
		end
	end
end

function CopActionTase:on_exit()
	if self._tase_effect then
		World:effect_manager():fade_kill(self._tase_effect)
	end
	
	if self._tase_hit_effect then
		World:effect_manager():fade_kill(self._tase_hit_effect)
	end

	if self._discharging then
		self._tasing_local_unit:movement():on_tase_ended()
	end

	if Network:is_server() then
		self._ext_movement:set_stance_by_code(2)
	end

	if self._modifier_on then
		self._machine:allow_modifier(self._modifier_name)
	end

	if Network:is_server() then
		self._unit:network():send("action_tase_event", 2)

		if self._expired then
			self._ext_movement:action_request({
				body_part = 3,
				type = "idle"
			})
		end
	end

	if self._tasered_sound then
		self._tasered_sound:stop()
		self._unit:sound():play("tasered_3rd_stop", nil)
	end

	if self._tasing_local_unit and self._tasing_player then
		self._attention.unit:movement():on_targetted_for_attack(false, self._unit)
	end

	if self._malfunction_clbk_id then
		managers.enemy:remove_delayed_clbk(self._malfunction_clbk_id)

		self._malfunction_clbk_id = nil
	end
end

function CopActionTase:on_destroy()
	if self._tase_effect then
		World:effect_manager():fade_kill(self._tase_effect)
	end
	
	if self._tase_hit_effect then
		World:effect_manager():fade_kill(self._tase_hit_effect)
	end

	if self._malfunction_clbk_id then
		managers.enemy:remove_delayed_clbk(self._malfunction_clbk_id)

		self._malfunction_clbk_id = nil
	end
end