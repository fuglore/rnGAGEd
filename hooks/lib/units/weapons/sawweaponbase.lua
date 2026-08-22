if RNGAGED.settings.disable_balance_changes then
	return
end

local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_dot = mvector3.dot
local mvec3_sub = mvector3.subtract
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_set_l = mvector3.set_length
local mvec3_len = mvector3.length
local math_clamp = math.clamp
local math_lerp = math.lerp
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()

local mvec_to = Vector3()
local mvec_spread_direction = Vector3()

Hooks:PostHook(SawWeaponBase, "init", "regunz_saw_skill", function(self, unit)
	self._weapon_dmg_resist = managers.player:has_category_upgrade("saw", "grant_dmg_resist")
	
	if self._saw_through_shields then
		self._use_armor_piercing = true
	end
end)

local function ray_table_contains(table, unit)
	for i, hit in pairs(table) do
		if hit.unit == unit then
			return true
		end
	end

	return false
end

local function ray_copy(table, ray)
	for i, hit in pairs(table) do
		if hit.unit == ray.unit then
			hit.body = ray.body
			hit.distance = ray.distance

			mvector3.set(hit.hit_position, ray.hit_position)
			mvector3.set(hit.normal, ray.normal)
			mvector3.set(hit.position, ray.position)
			mvector3.set(hit.ray, ray.ray)
		end
	end
end

function SawWeaponBase:fire(from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit)
	if self:get_ammo_remaining_in_clip() == 0 then
		return
	end

	local user_unit = self._setup.user_unit
	local ray_res, hit_something = self:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit)

	if hit_something then
		self:_start_sawing_effect()

		local ammo_usage = 2

		if ray_res.hit_enemy then
			if managers.player:has_category_upgrade("saw", "enemy_slicer") then
				ammo_usage = managers.player:upgrade_value("saw", "enemy_slicer", 16)
			else
				ammo_usage = 16
			end
		end

		if managers.player:has_category_upgrade("saw", "consume_no_ammo_chance") then
			local roll = math.rand(1)
			local chance = managers.player:upgrade_value("saw", "consume_no_ammo_chance", 0)

			if roll < chance then
				ammo_usage = 0
			end
		end

		if managers.player:has_active_temporary_property("bullet_storm") then
			ammo_usage = 0
		end

		ammo_usage = math.min(ammo_usage, self:get_ammo_remaining_in_clip())

		self:set_ammo_remaining_in_clip(math.max(self:get_ammo_remaining_in_clip() - ammo_usage, 0))
		self:set_ammo_total(math.max(self:get_ammo_total() - ammo_usage, 0))
		self:_check_ammo_total(user_unit)
	else
		self:_stop_sawing_effect()
	end

	if self._alert_events and ray_res.rays then
		if hit_something then
			self._alert_size = self._hit_alert_size
		else
			self._alert_size = self._no_hit_alert_size
		end

		self._current_stats.alert_size = self._alert_size

		self:_check_alert(ray_res.rays, from_pos, direction, user_unit)
	end

	return ray_res
end

function SawWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul)
	local result = {}
	local hit_unit = nil

	mvector3.set(mvec_spread_direction, direction)
	mvector3.set(mvec_to, mvec_spread_direction)
	mvector3.multiply(mvec_to, 220)
	mvector3.add(mvec_to, from_pos)

	local damage = self:_get_current_damage(dmg_mul)
	local valid_hit = false
	local col_ray = nil

	if self._saw_through_shields then
		local hits = {}
		col_ray = World:raycast_all("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units, "ray_type", "body bullet lock")

		for i, hit in ipairs(col_ray) do
			local is_shield = hit.unit:in_slot(8) and alive(hit.unit:parent())
			local is_enemy = hit.unit:character_damage() ~= nil

			if not ray_table_contains(hits, hit.unit) then
				table.insert(hits, hit)
			elseif hit.unit:character_damage() and hit.unit:character_damage().is_head and hit.unit:character_damage():is_head(hit.body) then
				ray_copy(hits, hit)
			end
		end

		for i, hit in pairs(hits) do
			hit_unit = SawHit:on_collision(hit, self._unit, user_unit, damage, direction)
		end

		valid_hit = #col_ray > 0
	else
		col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units, "ray_type", "body bullet lock")

		if col_ray then
			hit_unit = SawHit:on_collision(col_ray, self._unit, user_unit, damage, direction)
			valid_hit = true
		end
	end

	result.hit_enemy = hit_unit

	if self._alert_events then
		result.rays = {
			col_ray
		}
	end

	if col_ray then
		managers.statistics:shot_fired({
			hit = true,
			weapon_unit = self._unit
		})
	end

	return result, valid_hit
end

function SawHit:on_collision(col_ray, weapon_unit, user_unit, damage)
	local hit_unit = col_ray.unit
	local base_ext = hit_unit:base()
	local result = InstantBulletBase.on_collision(self, col_ray, weapon_unit, user_unit, damage)

	if hit_unit:damage() and col_ray.body:extension() and col_ray.body:extension().damage then
		local damage = weapon_unit:base():_get_current_damage(1)
		damage = damage * 0.35
		damage = math.clamp(damage * managers.player:upgrade_value("saw", "lock_damage_multiplier", 1), 0, 200)

		col_ray.body:extension().damage:damage_lock(user_unit, col_ray.normal, col_ray.position, col_ray.direction, damage)

		if hit_unit:id() ~= -1 then
			managers.network:session():send_to_peers_synched("sync_body_damage_lock", col_ray.body, damage)
		end
	end

	return result
end
