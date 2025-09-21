function WeaponLionGadget1:_shoot_bipod_rays(debug_draw)
	--debug_draw = true
	local mvec1 = Vector3()
	local mvec2 = Vector3()
	local mvec3 = Vector3()
	local mvec_look_dir = Vector3()
	local mvec_gun_down_dir = Vector3()
	local from = mvec1
	local to = mvec2
	local from_offset = mvec3
	local bipod_max_length = WeaponLionGadget1.bipod_length or 90

	if not self._bipod_obj then
		return nil
	end

	if not self._bipod_offsets then
		self:get_offsets()
	end

	mrotation.y(self:_get_bipod_alignment_obj():rotation(), mvec_look_dir)
	mrotation.x(self:_get_bipod_alignment_obj():rotation(), mvec_gun_down_dir)

	local bipod_position = Vector3()

	mvector3.set(bipod_position, self._bipod_offsets.direction)
	mvector3.rotate_with(bipod_position, self:_get_bipod_alignment_obj():rotation())
	mvector3.multiply(bipod_position, (self._bipod_offsets.distance or bipod_max_length) * -1)
	mvector3.add(bipod_position, self:_get_bipod_alignment_obj():position())

	if debug_draw then
		Application:draw_line(bipod_position, bipod_position + Vector3(10, 0, 0), unpack({
			1,
			0,
			0
		}))
		Application:draw_line(bipod_position, bipod_position + Vector3(0, 10, 0), unpack({
			0,
			1,
			0
		}))
		Application:draw_line(bipod_position, bipod_position + Vector3(0, 0, 10), unpack({
			0,
			0,
			1
		}))
	end

	if mvec_look_dir:to_polar().pitch > 60 then
		return nil
	end
	
	local slotmask = managers.slot:get_mask("player_ground_check")

	mvector3.set(from, bipod_position)
	mvector3.set(to, mvec_gun_down_dir)
	mvector3.multiply(to, bipod_max_length)
	mvector3.rotate_with(to, Rotation(mvec_look_dir, 120))
	mvector3.add(to, from)

	local ray_bipod_left = self._unit:raycast("ray", from, to, "slot_mask", slotmask, "ray_type", "walk -mover", "sphere_cast_radius", 2.5)

	if not debug_draw then
		self._left_ray_from = Vector3(from.x, from.y, from.z)
		self._left_ray_to = Vector3(to.x, to.y, to.z)
	else
		local color = ray_bipod_left and {
			0,
			1,
			0
		} or {
			1,
			0,
			0
		}

		Application:draw_line(from, to, unpack(color))
	end

	mvector3.set(to, mvec_gun_down_dir)
	mvector3.multiply(to, bipod_max_length)
	mvector3.rotate_with(to, Rotation(mvec_look_dir, 60))
	mvector3.add(to, from)

	local ray_bipod_right = self._unit:raycast("ray", from, to, "slot_mask", slotmask, "ray_type", "walk -mover", "sphere_cast_radius", 2.5)

	if not debug_draw then
		self._right_ray_from = Vector3(from.x, from.y, from.z)
		self._right_ray_to = Vector3(to.x, to.y, to.z)
	else
		local color = ray_bipod_right and {
			0,
			1,
			0
		} or {
			1,
			0,
			0
		}

		Application:draw_line(from, to, unpack(color))
	end

	mvector3.set(to, mvec_gun_down_dir)
	mvector3.multiply(to, bipod_max_length * math.cos(30))
	mvector3.rotate_with(to, Rotation(mvec_look_dir, 90))
	mvector3.add(to, from)

	local ray_bipod_center = self._unit:raycast("ray", from, to, "slot_mask", slotmask, "ray_type", "walk -mover", "sphere_cast_radius", 2.5)

	if not debug_draw then
		self._center_ray_from = Vector3(from.x, from.y, from.z)
		self._center_ray_to = Vector3(to.x, to.y, to.z)
	else
		local color = ray_bipod_center and {
			0,
			1,
			0
		} or {
			1,
			0,
			0
		}

		Application:draw_line(from, to, unpack(color))
	end

	mvector3.set(from_offset, Vector3(0, -100, 0))
	mvector3.rotate_with(from_offset, self:_get_bipod_alignment_obj():rotation())
	mvector3.add(from, from_offset)
	mvector3.set(to, mvec_look_dir)
	mvector3.multiply(to, 200)
	mvector3.add(to, from)

	local ray_bipod_forward = self._unit:raycast("ray", from, to, "slot_mask", slotmask, "ray_type", "walk -mover", "sphere_cast_radius", 2.5)

	if debug_draw then
		local color = ray_bipod_forward and {
			1,
			0,
			0
		} or {
			0,
			1,
			0
		}

		Application:draw_line(from, to, unpack(color))
	end

	return {
		left = ray_bipod_left,
		right = ray_bipod_right,
		center = ray_bipod_center,
		forward = ray_bipod_forward
	}
end

function WeaponLionGadget1:_is_deployable()
	if self._is_npc or not self:_get_bipod_obj() then
		return false
	end

	if self:_is_in_blocked_deployable_state() then
		return false
	end

	local bipod_rays = self:_shoot_bipod_rays()

	if not bipod_rays then
		return false
	end

	local bipod_min_length = 5

	if bipod_rays.forward then
		return false
	end

	if bipod_rays.left and bipod_rays.left.distance < bipod_min_length then
		return false
	end

	if bipod_rays.right and bipod_rays.right.distance < bipod_min_length then
		return false
	end

	if bipod_rays.center then
		return true
	end

	return false
end