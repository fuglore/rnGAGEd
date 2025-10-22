local mvec_to = Vector3()
local mvec_spread = Vector3()
local mvec3_cpy = mvector3.copy
local mvec3_set = mvector3.set
local mvec3_spread = mvector3.spread

local tmp_rot1 = Rotation()

function SentryGunWeapon:_apply_dmg_mul(damage, col_ray, from_pos)
	local damage_out = damage * self._current_damage_mul

	if tweak_data.weapon[self._name_id].DAMAGE_MUL_RANGE then
		local ray_dis = col_ray.distance or mvector3.distance(from_pos, col_ray.position)
		local ranges = tweak_data.weapon[self._name_id].DAMAGE_MUL_RANGE
		local i_range = nil

		for test_i_range, range_data in ipairs(ranges) do
			if ray_dis <= range_data[1] or test_i_range == #ranges then
				i_range = test_i_range

				break
			end
		end

		damage_out = damage_out * ranges[i_range][2]
	end

	return damage_out
end

local mvec_to = Vector3()

function SentryGunWeapon:_fire_raycast(from_pos, direction, shoot_player, target_unit)
	local result = {}
	local hit_unit, col_ray = nil

	mvector3.set(mvec_to, direction)
	mvector3.multiply(mvec_to, tweak_data.weapon[self._name_id].FIRE_RANGE)
	mvector3.add(mvec_to, from_pos)

	self._from = from_pos
	self._to = mvec_to

	if not self._setup.ignore_units then
		return
	end

	if self._use_armor_piercing then
		local col_rays = World:raycast_all("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units)
		col_ray = col_rays[1]

		if col_ray and col_ray.unit:in_slot(8) and alive(col_ray.unit:parent()) then
			col_ray = col_rays[2] or col_ray
		end
	else
		col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units)
	end

	local player_hit, player_ray_data = nil
	
	local bingus = not RNGAGED.settings.disable_enemy_projectiles and self._projectile_bullets
	
	if bingus then
		local ray_data = col_ray or player_ray_data
			
		if not ray_data then
			ray_data = {
				from_pos = mvec3_cpy(from_pos),
				ray = direction,
				normal = -direction
			}
		elseif not ray_data.from_pos then
			ray_data.from_pos = mvec3_cpy(from_pos)
		end
		
		local impact_info = {
			col_ray = ray_data,
			weapon_unit = self._unit,
			user_unit = self._unit,
			damage = damage,
			shoot_player = shoot_player,
			turret = true
		}
		impact_info.armor_piercing = self._use_armor_piercing
		
		managers.game_play_central:add_dynamic_npc_bullet(impact_info)
		
		local num_rays = (tweak_data.weapon[self._name_id] or {}).rays or 1
		
		if num_rays > 1 then
			for i = 1, num_rays - 1 do
				local new_ray = {
					from_pos = ray_data.from_pos,
					ray = Vector3()
				}
			
				mvec3_set(mvec_spread, direction)
				mvec3_spread(mvec_spread, self:_get_spread(user_unit))
				mvec3_set(new_ray.ray, mvec_spread)
				new_ray.normal = -new_ray.ray
				
				local imp_info_rays = {
					col_ray = new_ray,
					weapon_unit = self._unit:weapon(),
					user_unit = self._unit,
					damage = damage,
					shoot_player = impact_info.shoot_player,
					armor_piercing = impact_info.armor_piercing,
					turret = true
				}
				
				managers.game_play_central:add_dynamic_npc_bullet(imp_info_rays)
			end
		end
		
		if self._alert_events then
			result.rays = {
				col_ray
			}
		end
		
		return result
	end
	

	if shoot_player then
		player_hit, player_ray_data = RaycastWeaponBase.damage_player(self, col_ray, from_pos, direction)

		if player_hit then
			local damage = self:_apply_dmg_mul(self._damage, col_ray or player_ray_data, from_pos)

			InstantBulletBase:on_hit_player(col_ray or player_ray_data, self._unit, self._unit, damage)
		end
	end

	if not player_hit and col_ray then
		local damage = self:_apply_dmg_mul(self._damage, col_ray, from_pos)
		hit_unit = InstantBulletBase:on_collision(col_ray, self._unit, self._unit, damage, self._fires_blanks)
	end

	if not shoot_player and (not col_ray or col_ray.unit ~= target_unit) and target_unit and target_unit:character_damage() and target_unit:character_damage().build_suppression then
		target_unit:character_damage():build_suppression(self._suppression)
	end

	if not col_ray or col_ray.distance > 600 then
		self:_spawn_trail_effect(direction, col_ray)
	end

	result.hit_enemy = hit_unit

	if self._alert_events then
		result.rays = {
			col_ray
		}
	end

	return result
end

function SentryGunWeapon:on_team_set(team_data)
	self._foe_teams = team_data.foes
	
	if not self._projectile_bullets then
		self._projectile_bullets = team_data.foes[tweak_data.levels:get_default_team_ID("player")] and true or nil
	end
end