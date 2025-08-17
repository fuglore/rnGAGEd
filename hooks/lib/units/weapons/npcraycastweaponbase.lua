function NPCRaycastWeaponBase:_check_smoke_shot(user_unit, target_unit)
	return
end

local mvec_to = Vector3()
local mvec_spread = Vector3()
local mvec3_cpy = mvector3.copy
local mvec3_set = mvector3.set
local mvec3_spread = mvector3.spread

function NPCRaycastWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, spread_mul, autohit_mul, suppr_mul, target_unit)
	local result = {}
	local hit_unit = nil

	mvector3.set(mvec_to, direction)
	mvector3.multiply(mvec_to, 20000)
	mvector3.add(mvec_to, from_pos)

	local damage = self._damage * (dmg_mul or 1)
	local bullet_slotmask = self._bullet_slotmask
	local col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", bullet_slotmask, "ignore_unit", self._setup.ignore_units)
	local player_hit, player_ray_data = nil
	
	local bingus = not RNGAGED.settings.disable_enemy_projectiles
	
	if bingus then
		--if shoot_player and self._hit_player then
			--player_hit, player_ray_data = self:damage_player(col_ray, from_pos, direction, result)
		--end

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
			user_unit = user_unit,
			damage = damage,
			shoot_player = shoot_player and self._hit_player
		}
		impact_info.armor_piercing = self._unit:base():weapon_tweak_data().armor_piercing or nil
		
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
					weapon_unit = self._unit,
					user_unit = user_unit,
					damage = damage,
					shoot_player = impact_info.shoot_player,
					armor_piercing = impact_info.armor_piercing,
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

	local char_hit = nil

	if not player_hit and col_ray then
		char_hit = self._unit:base():bullet_class():on_collision(col_ray, self._unit, user_unit, damage, self._fires_blanks)
	end

	if not shoot_player and (not col_ray or col_ray.unit ~= target_unit) and target_unit and target_unit:character_damage() and target_unit:character_damage().build_suppression then
		target_unit:character_damage():build_suppression(tweak_data.weapon[self._name_id].suppression)
	end

	if not col_ray or col_ray.distance > 600 or result.guaranteed_miss then
		local num_rays = (tweak_data.weapon[self._name_id] or {}).rays or 1

		for i = 1, num_rays do
			mvector3.set(mvec_spread, direction)

			if i > 1 then
				mvector3.spread(mvec_spread, self:_get_spread(user_unit))
			end

			self:_spawn_trail_effect(mvec_spread, col_ray)
		end
	end

	result.hit_enemy = char_hit

	if self._alert_events then
		result.rays = {
			col_ray
		}
	end

	--self:_cleanup_smoke_shot()

	return result
end
