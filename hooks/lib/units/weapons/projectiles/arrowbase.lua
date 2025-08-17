local mvec1 = Vector3()
local mvec2 = Vector3()
local mrot1 = Rotation()
local ids_pickup = Idstring("pickup")

local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vel = Vector3()

local world_g = World

local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local mvec3_angle = mvector3.angle
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_step = mvector3.step
local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_norm = mvector3.normalize

local math_lerp = math.lerp
local ids_pickup = Idstring("pickup")

local tmp_vel = Vector3()

function ArrowBase:_setup_from_tweak_data(arrow_entry)
	local arrow_entry = self._tweak_projectile_entry or "west_arrow"
	local tweak_entry = tweak_data.projectiles[arrow_entry]
	self._use_armor_piercing = tweak_entry.armor_piercing
	self._damage_class_string = tweak_entry.bullet_class or "InstantBulletBase"
	self._damage_class = CoreSerialize.string_to_classtable(self._damage_class_string)
	self._mass_look_up_modifier = tweak_entry.mass_look_up_modifier
	self._damage = tweak_entry.damage or 1
	self._slot_mask = managers.slot:get_mask("arrow_impact_targets")
end

function ArrowBase:has_armor_piercing()
	return self._use_armor_piercing
end

function ArrowBase:update(unit, t, dt)
	if self._drop_in_sync_data then
		self._drop_in_sync_data.f = self._drop_in_sync_data.f - 1

		if self._drop_in_sync_data.f < 0 then
			local parent_unit = self._drop_in_sync_data.parent_unit

			if alive(parent_unit) then
				local state = self._drop_in_sync_data.state
				local parent_body = parent_unit:body(state.sync_attach_data.parent_body_index)
				local parent_obj = parent_body:root_object()

				self:sync_attach_to_unit(false, parent_unit, parent_body, parent_obj, state.sync_attach_data.local_pos, state.sync_attach_data.dir, true)
			end

			self._drop_in_sync_data = nil
		end
	end

	if not self._is_pickup and not RNGAGED.settings.disable_balance_changes then
		local autohit_dir = self:_calculate_autohit_direction()

		if autohit_dir then
			local body = self._unit:body(0)

			mvec3_set(tmp_vel, body:velocity())

			local speed = mvector3.normalize(tmp_vel)

			mvec3_step(tmp_vel, tmp_vel, autohit_dir, dt * 0.5)
			
			local rot = Rotation(tmp_vel, math.UP)
			
			body:set_rotation(rot)
			
			body:set_velocity(tmp_vel * speed)
		end
	end

	ArrowBase.super.update(self, unit, t, dt)

	if self._draw_debug_cone then
		local tip = unit:position()
		local base = tip + unit:rotation():y() * -35

		Application:draw_cone(tip, base, 3, 0, 0, 1)
	end
end

local tmp_vec1 = Vector3()

function ArrowBase:_calculate_autohit_direction()
	local enemies = managers.enemy:all_enemies()
	local m_unit = self._unit
	local pos = m_unit:position()
	local dir = m_unit:rotation():y()
	local closest_ang, closest_pos = nil
	local max_angle = 30
	
	local obstruction_mask = managers.slot:get_mask("world_geometry", "vehicles", "enemy_shield_check")

	for u_key, enemy_data in pairs(enemies) do
		local enemy = enemy_data.unit
		
		if not enemy:in_slot(16) and enemy:get_object(Idstring("Head")) then
			local com = enemy:get_object(Idstring("Head")):position()
			mvec3_dir(tmp_vec1, pos, com)
			mvec3_set_z(tmp_vec1, 0)

			local angle = mvec3_angle(dir, tmp_vec1)
			
			if angle < max_angle then
				local obstructed = m_unit:raycast("ray", pos, com, "slot_mask", obstruction_mask, "report")
				
				if not obstructed then
					if not closest_ang or angle < closest_ang then
						closest_ang = angle
						closest_pos = com
					end
				end
			end
		end
	end

	if closest_pos then
		mvector3.direction(tmp_vec1, pos, closest_pos)

		return tmp_vec1
	end
end