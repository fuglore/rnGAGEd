local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_dot = mvector3.dot
local mvec3_sub = mvector3.subtract
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_dis = mvector3.distance
local mvec3_set_l = mvector3.set_length
local mvec3_len = mvector3.length
local mvec3_len_sq = mvector3.length_sq
local mvec3_lerp = mvector3.lerp
local mvec3_cpy = mvector3.copy
local math_clamp = math.clamp
local math_lerp = math.lerp
local math_acos = math.acos
local math_pow = math.pow
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()

local ids_bullet_fx = Idstring("effects/pd2_mod_rgg/particles/bullet")
local ids_bullet_marshal_fx = Idstring("effects/pd2_mod_rgg/particles/bullet_marshal")
local ids_bullet_pierce_fx = Idstring("effects/pd2_mod_rgg/particles/bullet_pierce")

function GamePlayCentralManager:add_dynamic_npc_bullet(impact_info)
	if not impact_info.col_ray or not impact_info.col_ray.ray or mvector3.is_zero(impact_info.col_ray.ray) then
		return
	end

	self._dynamic_bullets = self._dynamic_bullets or {}
	
	if not impact_info.current_pos then
		impact_info.current_pos = mvec3_cpy(impact_info.col_ray.from_pos)
	end
	
	local effect_manager = World:effect_manager()
	local effect_type = ids_bullet_fx
	
	if impact_info.armor_piercing then
		impact_info.travel_speed = 30000
		effect_type = ids_bullet_pierce_fx
	elseif impact_info.turret then
		impact_info.travel_speed = 5000
	else
		local td
		
		if alive(impact_info.weapon_unit) and impact_info.weapon_unit:base() then
			td = tweak_data.weapon[impact_info.weapon_unit:base()._name_id]
			
			if td.trail then
				effect_type = ids_bullet_marshal_fx
				impact_info.travel_speed = 20000
			elseif td.rays and td.rays > 4 then
				impact_info.travel_speed = 5000
			else
				impact_info.travel_speed = 10000
			end
		else
			impact_info.travel_speed = 10000
		end
	end
	
	impact_info.effect = effect_manager:spawn({
		effect = effect_type,
		position = impact_info.current_pos,
		normal = impact_info.col_ray.ray
	})

	self._dynamic_bullets[#self._dynamic_bullets + 1] = impact_info
end

function GamePlayCentralManager:flush_dynamic_npc_bullets()
	local dynamic_bullets = self._dynamic_bullets
	
	if not dynamic_bullets then
		return
	end
	
	local effect_manager = World:effect_manager()
	local new_bullets_table = {}
	
	for i = 1, #dynamic_bullets do
		local bullet_info = dynamic_bullets[i]
		
		if not bullet_info.reached then
			new_bullets_table[#new_bullets_table + 1] = bullet_info
		elseif bullet_info.effect then
			effect_manager:fade_kill(bullet_info.effect)
		end
	end
	
	self._dynamic_bullets = new_bullets_table
end

function GamePlayCentralManager:check_bullet_hits_player(bullet_info, travel)
	local unit = managers.player:player_unit()

	if not unit then
		return
	end
	
	local from_pos = bullet_info.current_pos
	local head_pos = unit:movement():m_head_pos()
	local head_dis = mvec3_dis(from_pos, head_pos)
	local weapon_base = not bullet_info.turret and bullet_info.weapon_unit:base() or bullet_info.user_unit:weapon()
	local bullet_slotmask = weapon_base._bullet_slotmask
	local ignore_units = weapon_base._setup and weapon_base._setup.ignore_units or {}
	local dis = head_dis / travel

	if dis <= 1.5 then
		local head_dir = tmp_vec1
		local head_ray_dis = mvec3_dir(head_dir, bullet_info.col_ray.from_pos, head_pos)
		local shoot_dir = tmp_vec2
		mvec3_set(shoot_dir, bullet_info.col_ray.ray)
		
		local cos_f = mvec3_dot(shoot_dir, head_dir)
		local b = head_ray_dis / cos_f
		
		mvec3_set_l(shoot_dir, b)
		mvec3_mul(head_dir, head_ray_dis)
		mvec3_sub(shoot_dir, head_dir)

		local proj_len = mvec3_len(shoot_dir)
		
		if not bullet_info.dodged and proj_len > 30 then
			local player_state = managers.player:get_current_state()
			
			if player_state and player_state.is_dashing and player_state:is_dashing() then
				managers.player:add_style("dodge")
				
				bullet_info.dodged = true
			end
		end
		
		if dis < 0.5 then
			if proj_len <= 30 then
				if World:raycast("ray", from_pos, head_pos, "slot_mask", bullet_slotmask, "ignore_unit", ignore_units, "report") then
					if not bullet_info.suppressed_player and weapon_base._suppression then
						unit:character_damage():build_suppression(weapon_base._suppression)
						unit:character_damage():play_whizby(from_pos)
						bullet_info.suppressed_player = true
					end
				else
					return true
				end
			elseif not bullet_info.suppressed_player and proj_len < 90 and weapon_base._suppression then
				unit:character_damage():build_suppression(weapon_base._suppression)
				unit:character_damage():play_whizby(from_pos)
				bullet_info.suppressed_player = true
			end
		end
	end
	
	return
end

Hooks:PostHook(GamePlayCentralManager, "update", "regunz_dodge_enemy_bullets", function(self, t, dt)
	if not self._dynamic_bullets then
		return
	end

	local player_unit = managers.player:player_unit()

	local effect_manager = World:effect_manager()
	local line = Draw:brush(Color.blue:with_alpha(0.5))
	local line2 = Draw:brush(Color.red:with_alpha(0.5))

	for i = 1, #self._dynamic_bullets do
		local bullet_info = self._dynamic_bullets[i]		
		local travel = bullet_info.travel_speed * dt
		local hit_size = bullet_info.travel_speed * 0.016
		local weapon_base = not bullet_info.turret and alive(bullet_info.weapon_unit) and bullet_info.weapon_unit:base() or alive(bullet_info.user_unit) and bullet_info.user_unit:weapon()
		
		if not weapon_base or not alive(bullet_info.user_unit) then
			bullet_info.reached = true
		elseif mvec3_dis(bullet_info.current_pos, bullet_info.col_ray.from_pos) > 20000 then
			bullet_info.reached = true
		elseif player_unit and bullet_info.shoot_player and self:check_bullet_hits_player(bullet_info, hit_size) then
			bullet_info.reached = true
			player_unit:character_damage():build_suppression(5)
			bullet_info.col_ray.position = bullet_info.current_pos
			bullet_info.col_ray.unit = player_unit
			
			if not bullet_info.turret then
				weapon_base:bullet_class():give_impact_damage(bullet_info.col_ray, bullet_info.weapon_unit, bullet_info.user_unit, bullet_info.damage, bullet_info.armor_piercing)
			else
				local damage = weapon_base:_apply_dmg_mul(weapon_base._damage, bullet_info.col_ray, bullet_info.col_ray.from_pos)

				InstantBulletBase:on_hit_player(bullet_info.col_ray, bullet_info.user_unit, bullet_info.user_unit, damage)
			end
		end
		
		if not bullet_info.reached then
			mvec3_set(tmp_vec1, bullet_info.current_pos)
			mvec3_add(tmp_vec1, travel * bullet_info.col_ray.ray)
				
			local impact_slotmask = weapon_base._bullet_slotmask
			local blank_slotmask = weapon_base._blank_slotmask
			local ignore_units = weapon_base._setup and weapon_base._setup.ignore_units or {}
			local fires_blanks = weapon_base._fires_blanks
			local bullet_slotmask = fires_blanks and blank_slotmask or impact_slotmask
			
			if World:raycast("ray", bullet_info.current_pos, tmp_vec1, "slot_mask", bullet_slotmask, "ignore_unit", ignore_units, "report") then
				bullet_info.reached = true
				local col_ray = World:raycast("ray", bullet_info.current_pos, tmp_vec1, "slot_mask", bullet_slotmask, "ignore_unit", ignore_units)
				
				if not bullet_info.turret then
					bullet_info.weapon_unit:base():bullet_class():on_collision(col_ray, bullet_info.weapon_unit, bullet_info.user_unit, bullet_info.damage, fires_blanks)
					--effect_manager:move(bullet_info.effect, col_ray.position)
				else
					local damage = weapon_base:_apply_dmg_mul(weapon_base._damage, col_ray, col_ray.from_pos)
				
					InstantBulletBase:on_collision(col_ray, bullet_info.user_unit, bullet_info.user_unit, damage, fires_blanks)
					--effect_manager:move(bullet_info.effect, col_ray.position)
				end
				--line2:cylinder(bullet_info.current_pos, tmp_vec1, 1)
				--line2:sphere(col_ray.position, 5)
			else
				--line:cylinder(bullet_info.current_pos, tmp_vec1, 1)
				bullet_info.current_pos = mvec3_cpy(tmp_vec1)
				
				effect_manager:move(bullet_info.effect, bullet_info.current_pos)
			end
			
			if not bullet_info.reached then
				if not weapon_base or not alive(bullet_info.user_unit) then
					bullet_info.reached = true
				elseif mvec3_dis(bullet_info.current_pos, bullet_info.col_ray.from_pos) > 20000 then
					bullet_info.reached = true
				elseif player_unit and bullet_info.shoot_player and self:check_bullet_hits_player(bullet_info, hit_size) then
					bullet_info.reached = true
					player_unit:character_damage():build_suppression(5)
					bullet_info.col_ray.position = bullet_info.current_pos
					bullet_info.col_ray.unit = player_unit
					
					if not bullet_info.turret then
						weapon_base:bullet_class():give_impact_damage(bullet_info.col_ray, bullet_info.weapon_unit, bullet_info.user_unit, bullet_info.damage, bullet_info.armor_piercing)
					else
						local damage = weapon_base:_apply_dmg_mul(weapon_base._damage, bullet_info.col_ray, bullet_info.col_ray.from_pos)

						InstantBulletBase:on_hit_player(bullet_info.col_ray, bullet_info.user_unit, bullet_info.user_unit, damage)
					end
				end
			end
		end
	end
end)

Hooks:PostHook(GamePlayCentralManager, "end_update", "regunz_toilet", function(self, t, dt)
	self:flush_dynamic_npc_bullets()
end)