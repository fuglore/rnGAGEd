local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_dot = mvector3.dot
local mvec3_sub = mvector3.subtract
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_set_l = mvector3.set_length
local mvec3_len = mvector3.length
local mvec3_len_sq = mvector3.length_sq
local math_clamp = math.clamp
local math_lerp = math.lerp
local math_acos = math.acos
local math_pow = math.pow
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_rot1 = Rotation()

local do_impact_orig = InstantBulletBase.give_impact_damage

if not RNGAGED.settings.disable_balance_changes then

function RaycastWeaponBase:can_shield_knock()
	return self._shield_knock and managers.player:temporary_upgrade_value("temporary", "overkill_damage_multiplier", 1) > 1
end

function RaycastWeaponBase:chk_shield_knock(hit_unit, col_ray, weapon_unit, user_unit, damage)
	if not self:can_shield_knock() or not hit_unit:in_slot(self.shield_mask) then
		return false
	end

	local enemy_unit = hit_unit:parent()
	local char_dmg_ext = alive(enemy_unit) and enemy_unit:character_damage()

	if not char_dmg_ext or not char_dmg_ext.force_hurt then
		return false
	end

	if char_dmg_ext.is_immune_to_shield_knockback and char_dmg_ext:is_immune_to_shield_knockback() then
		return false
	end

	self._shield_knock_add = self._shield_knock_add or 0

	local dmg_ratio = math.min(damage, self.SHIELD_MIN_KNOCK_BACK)
	dmg_ratio = dmg_ratio / self.SHIELD_MIN_KNOCK_BACK	
	local rand = math.random() * dmg_ratio
	local knockback_chance = self.SHIELD_KNOCK_BACK_CHANCE - self._shield_knock_add

	if knockback_chance < rand then
		local damage_info = {
			damage = 0,
			type = "shield_knock",
			variant = "melee",
			col_ray = col_ray,
			result = {
				variant = "melee",
				type = "shield_knock"
			}
		}

		char_dmg_ext:force_hurt(damage_info)
		
		self._shield_knock_add = 0

		return true
	else
		
		self._shield_knock_add = self._shield_knock_add + 0.1 * dmg_ratio
	end

	return false
end

end

function InstantBulletBase:give_impact_damage(col_ray, weapon_unit, user_unit, damage, armor_piercing, shield_knock, knock_down, stagger, variant)
	if weapon_unit and weapon_unit:base() and weapon_unit:base()._hurt_dmg_increase and user_unit == managers.player:player_unit() then
		if col_ray.unit:anim_data() and col_ray.unit:anim_data().hurt then
			damage = damage * weapon_unit:base()._hurt_dmg_increase
		end
	end
	
	return do_impact_orig(self, col_ray, weapon_unit, user_unit, damage, armor_piercing, shield_knock, knock_down, stagger, variant)
end

function RaycastWeaponBase:_get_anim_start_offset(anim)
	if anim ~= "reload" and anim ~= "reload_not_empty" and anim ~= "reload_empty" then
		return false
	end
	
	if self:use_shotgun_reload() then
		return
	end

	local player_unit = managers.player:player_unit()
	
	if not player_unit then
		return false
	end

	local is_player = self._setup.user_unit == managers.player:player_unit()
	
	if not is_player then
		return false
	end
	
	local current_state = player_unit:movement()._current_state
	
	if not current_state then
		return false
	end

	return self._last_saved_reload_prog
end

Hooks:PostHook(RaycastWeaponBase, "start_reload", "regunz_clean_up_weaponlib_compatibility", function(self)
	if not self._last_saved_reload_prog then
		return
	end

	local player_unit = managers.player:player_unit()
	
	if not player_unit or self._setup.user_unit ~= player_unit then
		return
	end
	
	local current_state = player_unit:movement()._current_state
	
	if not current_state then
		return
	end

	if current_state._state_data.reload_expire_t then
		current_state._state_data.reload_expire_t = current_state._state_data.reload_expire_t - self._last_saved_reload_prog
	end

	if current_state._state_data.reload_steelsight_expire_t then
		current_state._state_data.reload_steelsight_expire_t = current_state._state_data.reload_steelsight_expire_t - self._last_saved_reload_prog
	end
end)

local mvec_to = Vector3()
local mvec_right_ax = Vector3()
local mvec_up_ay = Vector3()
local mvec_ax = Vector3()
local mvec_ay = Vector3()
local mvec_spread_direction = Vector3()

function RaycastWeaponBase:check_autoaim(from_pos, direction, max_dist, use_aim_assist, autohit_override_data, check_suppression)
	local autohit = autohit_override_data or use_aim_assist and self._aim_assist_data or self._autohit_data

	if not autohit then
		return nil, {}
	end

	local autohit_near_angle = autohit.near_angle
	local autohit_far_angle = autohit.far_angle
	local autohit_far_dis = autohit.far_dis
	local closest_error, closest_ray = nil
	local tar_vec = tmp_vec1
	local ignore_units = self._setup.ignore_units
	local slotmask = self._bullet_slotmask
	local in_steel_sight = nil
	local user_unit = self._setup.user_unit
	local current_state = user_unit:movement() and user_unit:movement()._current_state

	if current_state then
		in_steel_sight = current_state:in_steelsight()
		
		if self.regunz_zoom_mul and in_steel_sight then
			autohit_near_angle = autohit_near_angle * self.regunz_zoom_mul
			autohit_far_angle = autohit_far_angle * self.regunz_zoom_mul
		end
	end

	local suppression_near_angle, suppression_far_angle, suppression_far_dis, suppression_enemies = nil

	if check_suppression and self._suppression and self._suppression_data then
		suppression_near_angle = self._suppression_data.near_angle
		suppression_far_angle = self._suppression_data.far_angle
		suppression_far_dis = self._suppression_data.far_dis
		suppression_enemies = {}
	end

	local enemy, mov_ext, chk_pos, error_angle, tar_aim_dot, tar_vec_len, autohit_min_angle, suppression_min_angle, vis_ray = nil
	local tar_vec = tmp_vec1
	local in_slot_func = Unit.in_slot
	local world = World
	local raycast_f = World.raycast
	local force_hit

	for u_key, enemy_data in pairs(managers.enemy:all_enemies()) do
		enemy = enemy_data.unit
		mov_ext = enemy:movement()

		if enemy:base():lod_stage() and not in_slot_func(enemy, 16) then
			local from_m_com, already_normalized = nil

			if suppression_enemies and not mov_ext:cool() then
				from_m_com = true
				chk_pos = mov_ext:m_com()

				mvec3_set(tar_vec, chk_pos)
				mvec3_sub(tar_vec, from_pos)

				tar_aim_dot = mvec3_dot(direction, tar_vec)

				if tar_aim_dot > 0 then
					already_normalized = true
					tar_vec_len = mvec3_norm(tar_vec)
					error_angle = math_acos(mvec3_dot(direction, tar_vec))
					suppression_min_angle = math_lerp(suppression_near_angle, suppression_far_angle, tar_vec_len / autohit_far_dis)

					if error_angle < suppression_min_angle then
						suppression_enemies[u_key] = {
							unit = enemy,
							error_mul = 1 - error_angle / suppression_min_angle
						}
					end
				end
			end

			if in_steel_sight or not from_m_com then
				chk_pos = in_steel_sight and mov_ext:m_head_pos() or mov_ext:m_com()

				mvec3_set(tar_vec, chk_pos)
				mvec3_sub(tar_vec, from_pos)

				tar_aim_dot = mvec3_dot(direction, tar_vec)
			end

			if tar_aim_dot > 0 and (not max_dist or tar_aim_dot < max_dist) then
				if not in_steel_sight and from_m_com and already_normalized then
					tar_vec_len = math_clamp(tar_vec_len, 1, autohit_far_dis)
				else
					tar_vec_len = math_clamp(mvec3_norm(tar_vec), 1, autohit_far_dis)
					error_angle = math_acos(mvec3_dot(direction, tar_vec))
				end

				autohit_min_angle = math_lerp(autohit_near_angle, autohit_far_angle, tar_vec_len / autohit_far_dis)
				local autohit_force_angle = autohit_min_angle / 2

				if error_angle < autohit_min_angle then
					local percent_error = error_angle / autohit_min_angle

					if not closest_error or closest_error > error_angle / autohit_min_angle then
						tar_vec_len = tar_vec_len + 100

						mvec3_mul(tar_vec, tar_vec_len)
						mvec3_add(tar_vec, from_pos)
						
						if not closest_error or error_angle < closest_error then
							vis_ray = raycast_f(world, "ray", from_pos, tar_vec, "slot_mask", slotmask, "ignore_unit", ignore_units)

							if vis_ray and vis_ray.unit:key() == u_key then
								closest_error = error_angle
								closest_ray = vis_ray

								mvec3_set(tmp_vec1, chk_pos)
								mvec3_sub(tmp_vec1, from_pos)

								local d = mvec3_dot(direction, tmp_vec1)

								mvec3_set(tmp_vec1, direction)
								mvec3_mul(tmp_vec1, d)
								mvec3_add(tmp_vec1, from_pos)
								mvec3_sub(tmp_vec1, chk_pos)

								closest_ray.distance_to_aim_line = mvec3_len(tmp_vec1)
								
								force_hit = closest_error < autohit_force_angle
							end
						end
					end
				end
			end
		end
	end

	return closest_ray, suppression_enemies and next(suppression_enemies) and suppression_enemies or nil, force_hit
end

function RaycastWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul)
	if self:gadget_overrides_weapon_functions() then
		return self:gadget_function_override("_fire_raycast", self, user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul)
	end

	local result = {}
	local ray_distance = self:weapon_range()
	local spread_x, spread_y = self:_get_spread(user_unit)
	spread_y = spread_y or spread_x
	spread_mul = spread_mul or 1

	mvector3.cross(mvec_right_ax, direction, math.UP)
	mvec3_norm(mvec_right_ax)
	mvector3.cross(mvec_up_ay, direction, mvec_right_ax)
	mvec3_norm(mvec_up_ay)
	mvec3_set(mvec_spread_direction, direction)

	local theta = math.random() * 360

	mvec3_mul(mvec_right_ax, math.rad(math.sin(theta) * math.random() * spread_x * spread_mul))
	mvec3_mul(mvec_up_ay, math.rad(math.cos(theta) * math.random() * spread_y * spread_mul))
	mvec3_add(mvec_spread_direction, mvec_right_ax)
	mvec3_add(mvec_spread_direction, mvec_up_ay)
	mvec3_set(mvec_to, mvec_spread_direction)
	mvec3_mul(mvec_to, ray_distance)
	mvec3_add(mvec_to, from_pos)

	local ray_hits, hit_enemy, enemies_hit = self:_collect_hits(from_pos, mvec_to)

	if self._autoaim and self._autohit_data then
		local weight = 0.1

		if hit_enemy then
			self._autohit_current = (self._autohit_current + weight) / (1 + weight)
		else
			local auto_hit_candidate, enemies_to_suppress, force_hit = self:check_autoaim(from_pos, direction, nil, nil, nil, true)
			result.enemies_in_cone = enemies_to_suppress or false

			if auto_hit_candidate then
				local autohit_chance = self:get_current_autohit_chance_for_roll()

				if autohit_mul then
					autohit_chance = autohit_chance * autohit_mul
				end

				if force_hit or math.random() < autohit_chance then
					self._autohit_current = (self._autohit_current + weight) / (1 + weight)

					mvec3_set(mvec_spread_direction, auto_hit_candidate.ray)
					mvec3_set(mvec_to, mvec_spread_direction)
					mvec3_mul(mvec_to, ray_distance)
					mvec3_add(mvec_to, from_pos)

					ray_hits, hit_enemy, enemies_hit = self:_collect_hits(from_pos, mvec_to)
				end
			end

			if hit_enemy then
				self._autohit_current = (self._autohit_current + weight) / (1 + weight)
			elseif auto_hit_candidate then
				self._autohit_current = self._autohit_current / (1 + weight)
			end
		end
	end

	local hit_count = 0
	local hit_anyone = false
	local cop_kill_count = 0
	local hit_through_wall = false
	local hit_through_shield = false
	local is_civ_f = CopDamage.is_civilian
	local damage = self:_get_current_damage(dmg_mul)

	for _, hit in ipairs(ray_hits) do
		local dmg = self:get_damage_falloff(damage, hit, user_unit)

		if dmg > 0 then
			local hit_result = self:bullet_class():on_collision(hit, self._unit, user_unit, dmg)
			hit_through_wall = hit_through_wall or hit.unit:in_slot(self.wall_mask)
			hit_through_shield = hit_through_shield or hit.unit:in_slot(self.shield_mask) and alive(hit.unit:parent())

			if hit_result then
				hit.damage_result = hit_result
				hit_anyone = true
				hit_count = hit_count + 1

				if hit_result.type == "death" then
					local unit_base = hit.unit:base()
					local unit_type = unit_base and unit_base._tweak_table
					local is_civilian = unit_type and is_civ_f(unit_type)

					if not is_civilian then
						cop_kill_count = cop_kill_count + 1
					end

					self:_check_kill_achievements(cop_kill_count, unit_base, unit_type, is_civilian, hit_through_wall, hit_through_shield)
				end
			end
		end
	end

	self:_check_tango_achievements(cop_kill_count)

	result.hit_enemy = hit_anyone

	if self._autoaim then
		self._shot_fired_stats_table.hit = hit_anyone
		self._shot_fired_stats_table.hit_count = hit_count

		if not self._ammo_data or not self._ammo_data.ignore_statistic then
			managers.statistics:shot_fired(self._shot_fired_stats_table)
		end
	end

	local furthest_hit = ray_hits[#ray_hits]

	if (not furthest_hit or furthest_hit.distance > 600) and alive(self._obj_fire) then
		self._obj_fire:m_position(self._trail_effect_table.position)
		mvec3_set(self._trail_effect_table.normal, mvec_spread_direction)

		local trail = World:effect_manager():spawn(self._trail_effect_table)

		if furthest_hit then
			World:effect_manager():set_remaining_lifetime(trail, math_clamp((furthest_hit.distance - 600) / 10000, 0, furthest_hit.distance))
		end
	end

	if result.enemies_in_cone == nil then
		result.enemies_in_cone = self._suppression and self:check_suppression(from_pos, direction, enemies_hit) or nil
	elseif enemies_hit and self._suppression then
		result.enemies_in_cone = result.enemies_in_cone or {}
		local all_enemies = managers.enemy:all_enemies()

		for u_key, enemy in pairs(enemies_hit) do
			if all_enemies[u_key] then
				result.enemies_in_cone[u_key] = {
					error_mul = 1,
					unit = enemy
				}
			end
		end
	end

	if self._alert_events then
		result.rays = ray_hits
	end

	return result
end