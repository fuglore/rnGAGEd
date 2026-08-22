local mvec3_add = mvector3.add
local mvec3_cpy = mvector3.copy
local mvec3_cross = mvector3.cross
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_set = mvector3.set
local math_cos = math.cos
local math_rad = math.rad
local math_random = math.random
local math_sin = math.sin

if not RNGAGED.settings.disable_balance_changes then

local mvec_to = Vector3()
local mvec_right = Vector3()
local mvec_up = Vector3()
local mvec_ax = Vector3()
local mvec_ay = Vector3()
local mvec_spread_direction = Vector3()

function ShotgunBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul)
	if self:gadget_overrides_weapon_functions() then
		return self:gadget_function_override("_fire_raycast", self, user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul)
	end

	local result = {}
	local all_hits = {}
	local hit_effects = {}
	local all_enemies_hit = {}
	local alert_rays = self._alert_events and {}
	local all_hits_lookup = {}
	local alert_rays_lookup = alert_rays and {}

	local function on_hit(ray_hits)
		for _, hit in ipairs(ray_hits) do
			local unit_key = hit.unit:key()
			local char_dmg_ext = hit.unit:character_damage()

			if not char_dmg_ext then
				local base_ext = hit.unit:base()

				if not hit.unit:in_slot(self.shield_mask) or not base_ext then
					all_hits[#all_hits + 1] = hit

					if alert_rays then
						alert_rays[#alert_rays + 1] = hit
					end
				elseif not all_hits_lookup[unit_key] then
					all_hits_lookup[unit_key] = #all_hits + 1
					all_hits[#all_hits + 1] = hit

					if alert_rays then
						alert_rays_lookup[unit_key] = #alert_rays + 1
						alert_rays[#alert_rays + 1] = hit
					end
				elseif base_ext and base_ext.chk_body_hit_priority and base_ext:chk_body_hit_priority(all_hits[all_hits_lookup[unit_key]].body, hit.body) then
					hit_effects[#hit_effects + 1] = all_hits[all_hits_lookup[unit_key]]
					all_hits[all_hits_lookup[unit_key]] = hit

					if alert_rays then
						alert_rays[alert_rays_lookup[unit_key]] = hit
					end
				else
					hit_effects[#hit_effects + 1] = hit
				end
			elseif not all_hits_lookup[unit_key] then
				all_hits_lookup[unit_key] = #all_hits + 1
				all_hits[#all_hits + 1] = hit

				if alert_rays then
					alert_rays_lookup[unit_key] = #alert_rays + 1
					alert_rays[#alert_rays + 1] = hit
				end
			elseif char_dmg_ext.chk_body_hit_priority and char_dmg_ext:chk_body_hit_priority(all_hits[all_hits_lookup[unit_key]].body, hit.body) then
				if not char_dmg_ext.is_head then
					hit_effects[#hit_effects + 1] = all_hits[all_hits_lookup[unit_key]]
				end

				all_hits[all_hits_lookup[unit_key]] = hit

				if alert_rays then
					alert_rays[alert_rays_lookup[unit_key]] = hit
				end
			elseif not char_dmg_ext.is_head then
				hit_effects[#hit_effects + 1] = hit
			end
		end
	end

	local ray_distance = self:weapon_range(user_unit)
	local can_autoaim = self._autoaim and self._autohit_data and true or false
	local autohit_data = self._autohit_data
	local spread_x, spread_y = self:_get_spread(user_unit)
	spread_y = spread_y or spread_x
	spread_mul = spread_mul or 1

	mvec3_cross(mvec_right, direction, math.UP)
	mvec3_norm(mvec_right)
	mvec3_cross(mvec_up, direction, mvec_right)
	mvec3_norm(mvec_up)

	for i = 1, self._rays do
		mvec3_set(mvec_ax, mvec_right)
		mvec3_set(mvec_ay, mvec_up)
		mvec3_set(mvec_spread_direction, direction)

		local theta = math_random() * 360

		mvec3_mul(mvec_ax, math_rad(math_sin(theta) * math_random() * spread_x * spread_mul))
		mvec3_mul(mvec_ay, math_rad(math_cos(theta) * math_random() * spread_y * spread_mul))
		mvec3_add(mvec_spread_direction, mvec_ax)
		mvec3_add(mvec_spread_direction, mvec_ay)
		mvec3_set(mvec_to, mvec_spread_direction)
		mvec3_mul(mvec_to, ray_distance)
		mvec3_add(mvec_to, from_pos)

		local ray_hits, hit_enemy, enemies_hit = self:_collect_hits(from_pos, mvec_to)

		if can_autoaim then
			can_autoaim = false
			local weight = 0.1

			if hit_enemy then
				self._autohit_current = autohit_data.INIT_RATIO
			else
				local auto_hit_candidate, enemies_to_suppress, force_hit = self:check_autoaim(from_pos, direction, nil, nil, nil, true)
				result.enemies_in_cone = enemies_to_suppress or false

				if auto_hit_candidate and self._autohit_current > autohit_data.MIN_RATIO then
					local autohit_chance = self._autohit_current

					if autohit_mul then
						autohit_chance = autohit_chance * autohit_mul
					end

					if math_random() < autohit_chance then
						mvec3_set(mvec_spread_direction, auto_hit_candidate.ray)
						mvec3_set(mvec_to, mvec_spread_direction)
						mvec3_mul(mvec_to, ray_distance)
						mvec3_add(mvec_to, from_pos)

						ray_hits, hit_enemy, enemies_hit = self:_collect_hits(from_pos, mvec_to)
					end
				end

				if hit_enemy then
					self._autohit_current = autohit_data.INIT_RATIO
				elseif auto_hit_candidate then
					self._autohit_current = math.min(autohit_data.MAX_RATIO, self._autohit_current + (autohit_data.MAX_RATIO - autohit_data.MIN_RATIO) * weight)
				end
			end
		end

		if hit_enemy then
			for u_key, enemy in pairs(enemies_hit) do
				all_enemies_hit[u_key] = enemy
			end
		end

		if ray_hits and next(ray_hits) then
			on_hit(ray_hits)

			result.hit_enemy = result.hit_enemy or ray_hits[#ray_hits].unit:character_damage() and true or false
		end
	end

	local function sort_f(a, b)
		return a.distance < b.distance
	end

	table.sort(all_hits, sort_f)
	table.sort(hit_effects, sort_f)

	if alert_rays then
		table.sort(alert_rays, sort_f)
	end

	local hit_count = 0
	local hit_anyone = false
	local cop_kill_count = 0
	local kill_data = {
		kills = 0,
		headshots = 0,
		civilian_kills = 0
	}
	local bullet_class = self:bullet_class()
	local damage = self:_get_current_damage(dmg_mul)
	local check_additional_achievements = self._ammo_data and self._ammo_data.check_additional_achievements

	for _, hit in ipairs(hit_effects) do
		bullet_class:on_collision_effects(hit, self._unit, user_unit, damage)
	end

	local hit_through_wall = false
	local hit_through_shield = false
	local is_civ_f = CopDamage.is_civilian

	for _, hit in ipairs(all_hits) do
		local dmg = self:get_damage_falloff(damage, hit, user_unit)

		if dmg > 0 then
			local hit_result = bullet_class:on_collision(hit, self._unit, user_unit, dmg)
			hit_result = managers.mutators:modify_value("ShotgunBase:_fire_raycast", hit_result)

			if check_additional_achievements then
				hit_through_wall = hit_through_wall or hit.unit:in_slot(self.wall_mask)
				hit_through_shield = hit_through_shield or hit.unit:in_slot(self.shield_mask) and alive(hit.unit:parent())
			end

			if hit_result then
				hit.damage_result = hit_result
				hit_anyone = true
				hit_count = hit_count + 1

				if hit_result.type == "death" then
					kill_data.kills = kill_data.kills + 1
					local unit_base = hit.unit:base()
					local unit_type = unit_base and unit_base._tweak_table
					local is_civilian = unit_type and is_civ_f(unit_type)

					if is_civilian then
						kill_data.civilian_kills = kill_data.civilian_kills + 1
					else
						cop_kill_count = cop_kill_count + 1
					end

					if check_additional_achievements then
						self:_check_kill_achievements(cop_kill_count, unit_base, unit_type, is_civilian, hit_through_wall, hit_through_shield)
					end
				end
			end
		end
	end

	if check_additional_achievements then
		self:_check_tango_achievements(cop_kill_count)
	end

	self:_check_one_shot_shotgun_achievements(kill_data)

	if result.enemies_in_cone == nil then
		result.enemies_in_cone = self._suppression and self:check_suppression(from_pos, direction, all_enemies_hit) or nil
	elseif all_enemies_hit and self._suppression then
		result.enemies_in_cone = result.enemies_in_cone or {}
		local all_enemies = managers.enemy:all_enemies()

		for u_key, enemy in pairs(all_enemies_hit) do
			if all_enemies[u_key] then
				result.enemies_in_cone[u_key] = {
					error_mul = 1,
					unit = enemy
				}
			end
		end
	end

	if alert_rays then
		result.rays = alert_rays
	end

	if self._autoaim then
		self._shot_fired_stats_table.hit = hit_anyone
		self._shot_fired_stats_table.hit_count = hit_count

		if not self._ammo_data or not self._ammo_data.ignore_statistic then
			managers.statistics:shot_fired(self._shot_fired_stats_table)
		end
	end

	return result
end

end

---------------------------------------------------------------------------------------------------------------------------

Hooks:PostHook(ShotgunBase, "_update_stats_values", "regunz_pellets_upgrade", function(self, disallow_replenish, ammo_data)
	if self._ammo_data and self._ammo_data.rays ~= nil then
		self._rays = self._ammo_data.rays
		
		if self._rays > 1 then
			self._rays = self._rays + managers.player:upgrade_value("shotgun", "extra_pellets", 0)
		end
	elseif self._rays > 1 then
		if self._ammo_data and self._ammo_data.rays_add then
			self._rays = self._rays + self._ammo_data.rays_add
		end
	
		self._rays = self._rays + managers.player:upgrade_value("shotgun", "extra_pellets", 0)
	end
end)

