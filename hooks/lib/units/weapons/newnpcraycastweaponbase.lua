function NewNPCRaycastWeaponBase:_sound_autofire_start(nr_shots)
	self._sound_fire:stop()
	
	local tweak = tweak_data.weapon[self._name_id]
	
	if not tweak then
		log("bingus broke: " .. tostring(self._name_id))
		return
	end

	local tweak_sound = tweak_data.weapon[self._name_id].sounds
	local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. (nr_shots and "_" .. tostring(nr_shots) .. "shot" or "_loop")
	local sound = self._sound_fire:post_event(sound_name, callback(self, self, "_on_auto_fire_stop"), nil, "end_of_event")

	if not sound then
		sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_end"
		sound = self._sound_fire:post_event(sound_name)
	end
end

function NewNPCRaycastWeaponBase:_sound_singleshot()
	local tweak = tweak_data.weapon[self._name_id]
	
	if not tweak then
		log("bingus broke: " .. tostring(self._name_id))
		return
	end
	
	local tweak_sound = tweak_data.weapon[self._name_id].sounds
	local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. "_1shot"
	local sound = self._sound_fire:post_event(sound_name)

	if not sound then
		sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_1shot"
		sound = self._sound_fire:post_event(sound_name)
	end
end

function NewNPCRaycastWeaponBase:_sound_autofire_end()
	local tweak = tweak_data.weapon[self._name_id]
	
	if not tweak then
		log("bingus broke: " .. tostring(self._name_id))
		return
	end

	local tweak_sound = tweak_data.weapon[self._name_id].sounds
	local sound_name = tweak_sound.prefix .. self._setup.user_sound_variant .. self._voice .. "_end"
	local sound = self._sound_fire:post_event(sound_name)

	if not sound then
		sound_name = tweak_sound.prefix .. "1" .. self._voice .. "_end"
		sound = self._sound_fire:post_event(sound_name)
	end
end