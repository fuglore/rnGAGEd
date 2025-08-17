function CopActionDodge:init(action_desc, common_data)
	self._common_data = common_data
	self._ext_base = common_data.ext_base
	self._ext_movement = common_data.ext_movement
	self._ext_anim = common_data.ext_anim
	self._body_part = action_desc.body_part	
	self._unit = common_data.unit
	self._timeout = action_desc.timeout
	self._machine = common_data.machine
	self._ids_base = Idstring("base")

	local redir_name = "dodge_" .. tostring(action_desc.variation)
	local redir_res = self._ext_movement:play_redirect(redir_name)

	if redir_res then
		self._side = action_desc.side
		self._direction = action_desc.direction

		CopActionAct._create_blocks_table(self, action_desc.blocks)

		self._last_vel_z = 0

		self:_determine_rotation_transition()

		self._root_blend_disabled = true

		self._ext_movement:set_root_blend(false)

		if action_desc.speed then
			self._machine:set_speed(redir_res, action_desc.speed)
		end

		self._machine:set_parameter(redir_res, action_desc.side, 1)

		if Network:is_server() then
			local sync_accuracy = math.clamp(math.floor((action_desc.shoot_accuracy or 1) * 10), 0, 10)
			self._shoot_accuracy = sync_accuracy / 10

			common_data.ext_network:send("action_dodge_start", self._body_part, CopActionDodge._get_variation_index(action_desc.variation), CopActionDodge._get_side_index(action_desc.side), Rotation(action_desc.direction, math.UP):yaw(), action_desc.speed or 1, sync_accuracy)
		else
			self._shoot_accuracy = action_desc.shoot_accuracy / 10
		end

		self._ext_movement:enable_update()

		return true
	else
		debug_pause_unit(self._unit, "[CopActionDodge:init] redirect", redir_name, "failed in", self._machine:segment_state(Idstring("base")), common_data.unit)

		return
	end
end