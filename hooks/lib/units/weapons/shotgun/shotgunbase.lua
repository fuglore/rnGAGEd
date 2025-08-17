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