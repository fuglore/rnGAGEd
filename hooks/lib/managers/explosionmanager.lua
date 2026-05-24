if RNGAGED.settings.disable_balance_changes then
	return
end

local idstr_small_light_fire = Idstring("effects/particles/fire/small_light_fire")
local idstr_explosion_std = Idstring("explosion_std")
local empty_idstr = Idstring("")
local molotov_effect = "effects/payday2/particles/explosions/molotov_grenade"
local tmp_vec3 = Vector3()
local decal_ray_from = Vector3()
local decal_ray_to = Vector3()

function ExplosionManager:_damage_characters(detect_results, params, variant, damage_func_name)
	local user_unit = params.user
	local owner = params.owner
	local damage = params.damage
	local hit_pos = params.hit_pos
	local col_ray = params.col_ray
	local range = params.range
	local curve_pow = params.curve_pow
	local check_for_shield = nil
	local verify_callback = params.verify_callback
	local shield_mask
	damage_func_name = damage_func_name or "damage_explosion"
	
	if damage_func_name == "damage_explosion" then
		check_for_shield = true
		shield_mask = managers.slot:get_mask("enemy_shield_check")
	end
	
	local counts = {
		cops = {
			kills = 0,
			hits = 0
		},
		gangsters = {
			kills = 0,
			hits = 0
		},
		civilians = {
			kills = 0,
			hits = 0
		},
		criminals = {
			kills = 0,
			hits = 0
		}
	}
	local criminal_names = CriminalsManager.character_names()

	local function get_first_body_hit(bodies_hit)
		for _, hit_body in ipairs(bodies_hit or {}) do
			if alive(hit_body) then
				return hit_body
			end
		end
	end

	local dir, len, type, count_table, hit_body = nil

	for key, unit in pairs(detect_results.characters_hit) do
		hit_body = get_first_body_hit(detect_results.bodies_hit[key])
		dir = hit_body and hit_body:center_of_mass() or alive(unit) and unit:position()
		len = mvector3.direction(dir, hit_pos, dir)
		
		local can_damage = not verify_callback
		local reduce_dmg = nil

		if verify_callback then
			can_damage = verify_callback(unit)
		end

		if alive(unit) then
			if check_for_shield and can_damage then
				local dir_normalized = dir:normalized()
				local unit_inv = unit:inventory()
				
				if unit_inv and unit_inv.shield_unit and unit_inv:shield_unit() then
					local shield_fwd_inv = -unit_inv:shield_unit():rotation():y()
					
					if mvector3.dot(dir_normalized, shield_fwd_inv) > 0.7 then
						reduce_dmg = true
					end
				end
				
				if can_damage then
					local m_pos = hit_body and hit_body:center_of_mass() or alive(unit) and unit:position()
					local ray
					
					if params.ignore_unit then
						ray = unit:raycast("ray", hit_pos, m_pos, "ignore_unit", params.ignore_unit, "slot_mask", shield_mask, "report")
					else
						ray = unit:raycast("ray", hit_pos, m_pos, "slot_mask", shield_mask, "report")
					end
					
					if ray then
						reduce_dmg = true
					end
				end
			end
			
			if can_damage and unit:character_damage()[damage_func_name] then
				local action_data = {
					variant = variant or "explosion"
				}

				if damage > 0 then
					action_data.damage = math.max(damage * math.pow(math.clamp(1 - len / range, 0, 1), curve_pow), 1)
					
					if reduce_dmg then 
						action_data.damage = action_data.damage * 0.25
					end
				else
					action_data.damage = 0
				end

				action_data.attacker_unit = user_unit
				action_data.weapon_unit = owner
				action_data.col_ray = col_ray or {
					position = unit:position(),
					ray = dir
				}

				unit:character_damage()[damage_func_name](unit:character_damage(), action_data)
			elseif can_damage then
				debug_pause("unit: ", unit, " is missing " .. tostring(damage_func_name) .. " implementation")
			end
		end

		if alive(unit) and unit:base() and unit:base()._tweak_table then
			type = unit:base()._tweak_table

			if table.contains(criminal_names, CriminalsManager.convert_new_to_old_character_workname(type)) then
				count_table = counts.criminals
			elseif CopDamage.is_civilian(type) then
				count_table = counts.civilians
			elseif CopDamage.is_gangster(type) then
				count_table = counts.gangsters
			else
				count_table = counts.cops
			end

			count_table.hits = count_table.hits + 1

			if unit:character_damage():dead() then
				count_table.kills = count_table.kills + 1
			end
		end
	end

	local results = {
		count_cops = counts.cops.hits,
		count_gangsters = counts.gangsters.hits,
		count_civilians = counts.civilians.hits,
		count_criminals = counts.criminals.hits,
		count_cop_kills = counts.cops.kills,
		count_gangster_kills = counts.gangsters.kills,
		count_civilian_kills = counts.civilians.kills,
		count_criminal_kills = counts.criminals.kills
	}

	return results
end

function ExplosionManager:detect_and_give_dmg(params)
	local user_unit = params.user
	local owner = params.owner
	local damage = params.damage
	local player_damage = params.player_damage or damage
	local range = params.range
	local hit_pos = params.hit_pos
	local alert_radius = params.alert_radius or 10000
	local alert_filter = params.alert_filter or managers.groupai:state():get_unit_type_filter("civilians_enemies")
	local alert_unit = user_unit

	if alive(alert_unit) and alert_unit:base() and alert_unit:base().thrower_unit then
		alert_unit = alert_unit:base():thrower_unit()
	end

	local push_units = true

	if params.push_units ~= nil then
		push_units = params.push_units
	end

	local player = managers.player:player_unit()

	if alive(player) and player_damage ~= 0 then
		player:character_damage():damage_explosion({
			variant = "explosion",
			position = hit_pos,
			range = range,
			damage = player_damage
		})
	end

	managers.groupai:state():propagate_alert({
		"explosion",
		hit_pos,
		alert_radius,
		alert_filter,
		alert_unit
	})
	
	local detect_results = self:_detect_hits(params)
	local damage_results = self:_damage_characters(detect_results, params)
	
	self:_damage_bodies(detect_results, params)

	local results = {}

	if owner then
		results.count_cops = damage_results.count_cops
		results.count_gangsters = damage_results.count_gangsters
		results.count_civilians = damage_results.count_civilians
		results.count_cop_kills = damage_results.count_cop_kills
		results.count_gangster_kills = damage_results.count_gangster_kills
		results.count_civilian_kills = damage_results.count_civilian_kills
	end

	if push_units and push_units == true then
		self:units_to_push(detect_results.units_detected, hit_pos, range)
	end

	return detect_results.units_hit, detect_results.splinters, results
end
