function BlackMarketManager:equipped_grenade_allows_pickups()
	local id = self:equipped_grenade()
	local grenade_tweak = id and tweak_data.blackmarket.projectiles[id]

	return grenade_tweak and (not grenade_tweak.base_cooldown or grenade_tweak.is_a_grenade and grenade_tweak.is_explosive)
end

function BlackMarketManager:threat_multiplier(name, categories, silencer)
	local multiplier = 1
	multiplier = multiplier + 1 - managers.player:upgrade_value("player", "suppression_multiplier", 1)
	multiplier = multiplier + 1 - managers.player:upgrade_value("player", "suppression_multiplier2", 1)
	multiplier = multiplier + 1 - managers.player:upgrade_value("player", "passive_suppression_multiplier", 1)

	if categories then
		for _, category in ipairs(categories) do
			multiplier = multiplier + 1 - managers.player:upgrade_value(category, "passive_suppression_multiplier", 1)
		end
	end

	return self:_convert_add_to_mul(multiplier)
end

function BlackMarketManager:recoil_index(name, categories, recoil_index, silencer, blueprint, current_state, is_single_shot)
	local addend = 0

	if recoil_index then
		local index = recoil_index
		index = index + managers.player:upgrade_value("weapon", "recoil_index_addend", 0)
		index = index + managers.player:upgrade_value("player", "stability_increase_bonus_1", 0)
		index = index + managers.player:upgrade_value("player", "stability_increase_bonus_2", 0)
		index = index + managers.player:upgrade_value(name, "recoil_index_addend", 0)

		for _, category in ipairs(categories) do
			index = index + managers.player:upgrade_value(category, "recoil_index_addend", 0)
		end

		if managers.player:player_unit() and managers.player:player_unit():character_damage():is_suppressed() then
			for _, category in ipairs(categories) do
				if managers.player:has_team_category_upgrade(category, "suppression_recoil_index_addend") then
					index = index + managers.player:team_upgrade_value(category, "suppression_recoil_index_addend", 0)
				end
			end

			if managers.player:has_team_category_upgrade("weapon", "suppression_recoil_index_addend") then
				index = index + managers.player:team_upgrade_value("weapon", "suppression_recoil_index_addend", 0)
			end
		else
			for _, category in ipairs(categories) do
				if managers.player:has_team_category_upgrade(category, "recoil_index_addend") then
					index = index + managers.player:team_upgrade_value(category, "recoil_index_addend", 0)
				end
			end

			if managers.player:has_team_category_upgrade("weapon", "recoil_index_addend") then
				index = index + managers.player:team_upgrade_value("weapon", "recoil_index_addend", 0)
			end
		end

		if silencer then
			index = index + managers.player:upgrade_value("weapon", "silencer_recoil_index_addend", 0)

			for _, category in ipairs(categories) do
				index = index + managers.player:upgrade_value(category, "silencer_recoil_index_addend", 0)
			end
		end

		if blueprint and self:is_weapon_modified(managers.weapon_factory:get_factory_id_by_weapon_id(name), blueprint) then
			index = index + managers.player:upgrade_value("weapon", "modded_recoil_index_addend", 0)
		end

		local recoil_tweak = tweak_data.weapon.stats.recoil
		index = math.clamp(index, 1, #recoil_tweak)
		
		return index
	end
end
