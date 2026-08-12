function NPCRaycastWeaponBase:_check_smoke_shot(user_unit, target_unit)
	return
end


local bingus = RNGAGED.settings.disable_enemy_projectiles

if not bingus then

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
	
	local falloff
	
	if not RNGAGED.settings.disable_balance_changes then
		falloff = user_unit:base():char_tweak().weapon[self:weapon_tweak_data().usage].FALLOFF
	end
	
	local impact_info = {
		col_ray = ray_data,
		weapon_unit = self._unit,
		user_unit = user_unit,
		damage = damage,
		falloff = falloff,
		shoot_player = shoot_player and self._hit_player
	}
	impact_info.armor_piercing = self:weapon_tweak_data().armor_piercing or nil
	
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
				falloff = falloff,
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

end