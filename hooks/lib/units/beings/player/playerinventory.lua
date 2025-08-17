function PlayerInventory:destroy_all_items()
	local had_equipped = nil

	do
		local equipped_key = self._equipped_selection and self._available_selections[ self._equipped_selection ]
		equipped_key = equipped_key and alive( equipped_key.unit ) and equipped_key.unit:key()

		for i_sel, selection_data in pairs(self._available_selections) do
			if selection_data.unit and selection_data.unit:base() then
				had_equipped = had_equipped or equipped_key == selection_data.unit:key()

				selection_data.unit:base():remove_destroy_listener(self._listener_id)
				selection_data.unit:base():set_slot(selection_data.unit, 0)

				if selection_data.unit:base():charm_data() then
					managers.charm:remove_weapon(selection_data.unit)
					managers.belt:remove_weapon(selection_data.unit)
				end
			else
				debug_pause_unit(self._unit, "[PlayerInventory:destroy_all_items] broken inventory unit", selection_data.unit, selection_data.unit:base())
			end
		end
	end

	self._equipped_selection = nil
	self._available_selections = {}

	-- we had an equipped weapon that we're now destroying
	-- we need to call listeners for other functions to act accordingly as expected and prevent crashing
	-- IMPORTANT this must be done after setting _equipped_selection to nil due to how the listener functions handle these cases
	if had_equipped then
		self:_call_listeners("unequip")
	end

	if alive(self._mask_unit) then
		for _, linked_unit in ipairs(self._mask_unit:children()) do
			linked_unit:unlink()
			World:delete_unit(linked_unit)
		end

		World:delete_unit(self._mask_unit)

		self._mask_unit = nil
	end

	if self._melee_weapon_unit_name then
		managers.dyn_resource:unload(Idstring("unit"), self._melee_weapon_unit_name, DynamicResourceManager.DYN_RESOURCES_PACKAGE, false)

		self._melee_weapon_unit_name = nil
	end

	local shield_unit = self._shield_unit

	if alive(shield_unit) then
		self:unequip_shield()

		if Network:is_server() or shield_unit:id() == -1 then
			shield_unit:set_slot(0)
		else
			shield_unit:set_enabled(false)
		end
	end
end
