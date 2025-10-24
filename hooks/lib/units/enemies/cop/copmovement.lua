function CopMovement:_get_spooc_attack_action()
	for body_part, action in pairs(self._active_actions) do
		if action and action:type() == "spooc" then
			return action
		end
	end
end

function CopMovement:_exit_hurt_clbk(unit, wanted_pose)
	if self._ext_damage:dead() then
		return
	end
	
	if self._anim_global ~= "shield" and wanted_pose then
		self:play_redirect(tostring(wanted_pose))
	else
		self:play_redirect("crouch")
	end
end

local hack_allow_reload_sfx = nil

local _allow_dropped_magazines = CopMovement.allow_dropped_magazines

function CopMovement.allow_dropped_magazines(self, ...)
    return hack_allow_reload_sfx or _allow_dropped_magazines(self, ...)
end

local __play_weapon_reload_animation_sfx = CopMovement._play_weapon_reload_animation_sfx

function CopMovement._play_weapon_reload_animation_sfx(self, ...)
    hack_allow_reload_sfx = true
    __play_weapon_reload_animation_sfx(self, ...)
    hack_allow_reload_sfx = nil
end

local _action_request = CopMovement.action_request

function CopMovement.action_request(self, ...)
	local action_desc = select(1, ...)
	
	if not Network:is_server() then
		if action_desc.type == "hurt" and action_desc.hurt_type ~= "death" or action_desc.type == "healed" then
			local queued_actions = self._queued_actions
				
			if next(queued_actions) then
				for i = #queued_actions, 1, -1 do
					if queued_actions[i].type == "hurt" and queued_actions[i].body_part == 1 and not queued_actions[i].hurt_type == "death" then
						if queued_actions[i].attacker_unit == action_desc.attacker_unit and action_desc.hurt_type == queued_actions[i].hurt_type then
							return
						end
					end
					
					if queued_actions[i].type == "act" and queued_actions[i].body_part ~= 3 and not queued_actions[i].host_expired then
						return
					end
				end
			end
		end
	end

	return _action_request(self, ...)
end