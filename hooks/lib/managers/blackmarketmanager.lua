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