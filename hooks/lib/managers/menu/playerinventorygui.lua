if RNGAGED.settings.disable_balance_changes then
	return
end

local IS_WIN_32 = SystemInfo:platform() == Idstring("WIN32")
local NOT_WIN_32 = not IS_WIN_32
local TOP_ADJUSTMENT = NOT_WIN_32 and 50 or 55
local BOT_ADJUSTMENT = NOT_WIN_32 and 40 or 60
local join_stinger_binding = "menu_respec_tree_all"

local function _animate(objects, scale, anim_time)
	local anims = {}

	for _, object in pairs(objects) do
		if object then
			local data = {
				sw = object.gui:width(),
				sh = object.gui:height(),
				ew = object.shape[3] * scale,
				eh = object.shape[4] * scale,
				sf = object.gui.font_scale and object.gui:font_scale() or scale,
				ef = scale
			}

			if object.font_scale then
				data.sf = data.sf
				data.ef = data.ef * object.font_scale
			end

			table.insert(anims, {
				object = object,
				data = data
			})
		end
	end

	if anim_time == 0 then
		for _, anim in ipairs(anims) do
			local cx, cy = anim.object.gui:center()

			anim.object.gui:set_size(anim.data.ew, anim.data.eh)
			anim.object.gui:set_center(cx, cy)

			if anim.object.gui.set_font_scale then
				anim.object.gui:set_font_scale(anim.data.ef)
			end
		end

		return
	end

	local time = 0

	while anim_time > time do
		local dt = coroutine.yield()
		time = time + dt
		local p = time / anim_time

		for _, anim in ipairs(anims) do
			local cx, cy = anim.object.gui:center()

			anim.object.gui:set_size(math.lerp(anim.data.sw, anim.data.ew, p), math.lerp(anim.data.sh, anim.data.eh, p))
			anim.object.gui:set_center(cx, cy)

			if anim.object.gui.set_font_scale then
				anim.object.gui:set_font_scale(math.lerp(anim.data.sf, anim.data.ef, p))
			end
		end
	end
end

local function select_anim(o, box, instant)
	_animate({
		box.image_object,
		box.animate_text and box.text_object
	}, 1, instant and 0 or 0.2)
end

local function unselect_anim(o, box, instant)
	_animate({
		box.image_object,
		box.animate_text and box.text_object
	}, 0.8, instant and 0 or 0.2)
end

local function make_fine_text(text)
	local x, y, w, h = text:text_rect()

	text:set_size(w, h)
	text:set_position(math.round(text:x()), math.round(text:y()))
end

local function format_round(num, round_value)
	return round_value and tostring(math.round(num)) or string.format("%.1f", num):gsub("%.?0+$", "")
end

function PlayerInventoryGui:_update_info_melee(name)
	local player_loadout_data = managers.blackmarket:player_loadout_data()
	local category = "melee_weapons"
	local equipped_item = managers.blackmarket:equipped_item(category)
	local base_stats, mods_stats, skill_stats = self:_get_melee_weapon_stats(equipped_item)
	local text_string = string.format("%s", player_loadout_data.melee_weapon.info_text)

	self:set_info_text(text_string)

	local value, value_min, value_max = nil

	for _, stat in ipairs(self._stats_shown) do
		if stat.range then
			value_min = math.max(base_stats[stat.name].min_value + mods_stats[stat.name].min_value + skill_stats[stat.name].min_value, 0)
			value_max = math.max(base_stats[stat.name].max_value + mods_stats[stat.name].max_value + skill_stats[stat.name].max_value, 0)
		end

		value = math.max(base_stats[stat.name].value + mods_stats[stat.name].value + skill_stats[stat.name].value, 0)
		local base, base_min, base_max, skill, skill_min, skill_max = nil

		if stat.range then
			base_min = base_stats[stat.name].min_value
			base_max = base_stats[stat.name].max_value
			skill_min = skill_stats[stat.name].min_value
			skill_max = skill_stats[stat.name].max_value
		end

		base = base_stats[stat.name].value
		skill = skill_stats[stat.name].value
		local format_string = "%0." .. tostring(stat.num_decimals or 0) .. "f"
		local equip_text = value and format_round(value, stat.round_value)
		local base_text = base and format_round(base, stat.round_value)
		local skill_text = skill_stats[stat.name].value and format_round(skill_stats[stat.name].value, stat.round_value)
		local base_min_text = base_min and format_round(base_min, true)
		local base_max_text = base_max and format_round(base_max, true)
		local value_min_text = value_min and format_round(value_min, true)
		local value_max_text = value_max and format_round(value_max, true)
		local skill_min_text = skill_min and format_round(skill_min, true)
		local skill_max_text = skill_max and format_round(skill_max, true)

		if stat.range then
			if base_min ~= base_max then
				base_text = base_min_text .. " (" .. base_max_text .. ")"
			end

			if value_min ~= value_max then
				equip_text = value_min_text .. " (" .. value_max_text .. ")"
			end

			if skill_min ~= skill_max then
				skill_text = skill_min_text .. " (" .. skill_max_text .. ")"
			end
		end

		if stat.suffix then
			base_text = base_text .. tostring(stat.suffix)
			equip_text = equip_text .. tostring(stat.suffix)
			skill_text = skill_text .. tostring(stat.suffix)
		end

		if stat.prefix then
			base_text = tostring(stat.prefix) .. base_text
			equip_text = tostring(stat.prefix) .. equip_text
			skill_text = tostring(stat.prefix) .. skill_text
		end
		
		if stat.name == "auto_counter" then
			if value and value > 0 then
				equip_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_true"))
			else
				equip_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_false"))
			end
			
			if base and base > 0 then
				base_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_true"))
			else
				base_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_false"))
			end
		end

		self._stats_texts[stat.name].total:set_alpha(1)
		self._stats_texts[stat.name].total:set_text(equip_text)
		self._stats_texts[stat.name].base:set_text(base_text)
		self._stats_texts[stat.name].skill:set_text(skill_stats[stat.name].skill_in_effect and (skill_stats[stat.name].value > 0 and "+" or "") .. skill_text or "")

		local positive = value ~= 0 and base < value
		local negative = value ~= 0 and value < base

		if stat.inverse then
			local temp = positive
			positive = negative
			negative = temp
		end

		if stat.range then
			if positive then
				self._stats_texts[stat.name].total:set_color(tweak_data.screen_colors.stats_positive)
			elseif negative then
				self._stats_texts[stat.name].total:set_color(tweak_data.screen_colors.stats_negative)
			end
		elseif positive then
			self._stats_texts[stat.name].total:set_color(tweak_data.screen_colors.stats_positive)
		elseif negative then
			self._stats_texts[stat.name].total:set_color(tweak_data.screen_colors.stats_negative)
		else
			self._stats_texts[stat.name].total:set_color(tweak_data.screen_colors.text)
		end
	end
end



Hooks:PostHook(PlayerInventoryGui, "_update_stats", "regunz_melee", function(self, name)
	if self._rehooked_stats_shown == name then
		return
	end
	
	self._rehooked_stats_shown = name
	
	if name == "melee" then
		self:set_info_text("")
		self._info_panel:clear()
	
		self:set_melee_stats(self._info_panel, {
			{
				range = true,
				name = "damage"
			},
			{
				range = true,
				name = "damage_effect",
				multiple_of = "damage"
			},
			{
				inverse = true,
				name = "charge_time",
				num_decimals = 1,
				suffix = managers.localization:text("menu_seconds_suffix_short")
			},
			{
				range = true,
				bool = true,
				name = "auto_counter"
			},
			{
				index = true,
				name = "concealment"
			}
		})
		self:_update_info_melee(name)
	end
end)