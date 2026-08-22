if RNGAGED.settings.disable_balance_changes then
	return
end

local is_win32 = SystemInfo:platform() == Idstring("WIN32")
local NOT_WIN_32 = not is_win32
local WIDTH_MULTIPLIER = NOT_WIN_32 and 0.68 or 0.71
local BOX_GAP = 13.5
local GRID_H_MUL = (NOT_WIN_32 and 6.9 or 6.95) / 8
local ITEMS_PER_ROW = 3
local ITEMS_PER_COLUMN = 3
local BUY_MASK_SLOTS = {
	7,
	4
}
local WEAPON_MODS_SLOTS = {
	6,
	1
}
local WEAPON_MODS_GRID_H_MUL = 0.126
local DEFAULT_LOCKED_BLEND_MODE = "normal"
local DEFAULT_LOCKED_BLEND_ALPHA = 0.35
local DEFAULT_LOCKED_COLOR = Color(1, 1, 1)
local massive_font = tweak_data.menu.pd2_massive_font
local large_font = tweak_data.menu.pd2_large_font
local medium_font = tweak_data.menu.pd2_medium_font
local small_font = tweak_data.menu.pd2_small_font
local tiny_font = tweak_data.menu.tiny_font
local massive_font_size = tweak_data.menu.pd2_massive_font_size
local large_font_size = tweak_data.menu.pd2_large_font_size
local medium_font_size = tweak_data.menu.pd2_medium_font_size
local small_font_size = tweak_data.menu.pd2_small_font_size
local tiny_font_size = tweak_data.menu.pd2_tiny_font_size

local function format_round(num, round_value)
	return round_value and tostring(math.round(num)) or string.format("%.1f", num):gsub("%.?0+$", "")
end

Hooks:PostHook(BlackMarketGui, "show_stats", "reengage_redefine_melee_gui", function(self)
	if not self._redefined_melee_gui then
		local tab_data = self._tabs[self._selected]._data
		
		if tab_data and tab_data.identifier then
			if tab_data.identifier ~= self.identifiers.melee_weapon then
				return
			end
		end
		
		
		--local help_me_jesus = self._slot_data.dont_compare_stats or tweak_data.weapon[self._slot_data.name] or self._slot_data.default_blueprint or tweak_data.blackmarket.armors[self._slot_data.name] or tweak_data.economy.armor_skins[self._slot_data.name] or tweak_data.blackmarket.player_styles[self._slot_data.name]
		local fuck_data = managers.blackmarket:get_melee_weapon_stats(self._slot_data.name)

		if not fuck_data or not fuck_data.min_damage then
			--log("bingus!")
			return
		end
	
		self._stats_panel:remove(self._mweapon_stats_panel)
		self._mweapon_stats_shown = {
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
				name = "auto_counter",
				range = true,
				bool = true
			},
			{
				index = true,
				name = "concealment"
			}
		}

		local x = 0
		local y = 20
		local text_panel = nil
		self._mweapon_stats_texts = {}
		local text_columns = {
			{
				size = 100,
				name = "name"
			},
			{
				align = "right",
				name = "equip",
				blend = "add",
				alpha = 0.75,
				size = 55
			},
			{
				align = "right",
				name = "base",
				blend = "add",
				alpha = 0.75,
				size = 60
			},
			{
				align = "right",
				name = "skill",
				blend = "add",
				alpha = 0.75,
				size = 65,
				color = tweak_data.screen_colors.resource
			},
			{
				size = 55,
				name = "total",
				align = "right"
			}
		}
	
		self._mweapon_stats_panel = self._stats_panel:panel()

		for i, stat in ipairs(self._mweapon_stats_shown) do
			panel = self._mweapon_stats_panel:panel({
				h = 20,
				x = 0,
				layer = 1,
				y = y,
				w = self._mweapon_stats_panel:w()
			})

			if math.mod(i, 2) == 0 and not panel:child(tostring(i)) then
				panel:rect({
					name = tostring(i),
					color = Color.black:with_alpha(0.3)
				})
			end

			x = 2
			y = y + 20
			self._mweapon_stats_texts[stat.name] = {}

			for _, column in ipairs(text_columns) do
				text_panel = panel:panel({
					layer = 0,
					x = x,
					w = column.size,
					h = panel:h()
				})
				self._mweapon_stats_texts[stat.name][column.name] = text_panel:text({
					layer = 1,
					font_size = small_font_size,
					font = small_font,
					align = column.align,
					alpha = column.alpha,
					blend_mode = column.blend,
					color = column.color or tweak_data.screen_colors.text
				})
				x = x + column.size

				if column.name == "total" then
					text_panel:set_x(190)
				end
			end
		end
		
		local weapon = managers.blackmarket:get_crafted_category_slot(self._slot_data.category, self._slot_data.slot)
		local name = weapon and weapon.weapon_id or self._slot_data.name
		local category = self._slot_data.category
		local slot = self._slot_data.slot
		local hide_stats = false
		local value = 0
		local tweak_stats = tweak_data.weapon.stats
		local modifier_stats = tweak_data.weapon[name] and tweak_data.weapon[name].stats_modifiers
		
		
		
		self:hide_melee_weapon_stats()
		
		if not help_me_jesus and tweak_data.blackmarket.melee_weapons[self._slot_data.name] then
			self:hide_armor_stats()
			self:hide_weapon_stats()
			self._mweapon_stats_panel:show()
			self:set_stats_titles({
				x = 185,
				name = "base"
			}, {
				name = "mod",
				x = 245,
				text_id = "bm_menu_stats_skill",
				color = tweak_data.screen_colors.resource
			}, {
				alpha = 0,
				name = "skill"
			})

			local equipped_item = managers.blackmarket:equipped_item(category)
			local equip_base_stats, equip_mods_stats, equip_skill_stats = self:_get_melee_weapon_stats(equipped_item)
			local base_stats, mods_stats, skill_stats = self:_get_melee_weapon_stats(self._slot_data.name)

			if self._slot_data.name ~= equipped_item then
				for _, title in pairs(self._stats_titles) do
					title:hide()
				end

				self:set_stats_titles({
					show = true,
					name = "total"
				}, {
					name = "equip",
					text_id = "bm_menu_equipped",
					alpha = 0.75,
					x = 105,
					show = true
				})
			else
				for title_name, title in pairs(self._stats_titles) do
					title:show()
				end

				self:set_stats_titles({
					hide = true,
					name = "total"
				}, {
					alpha = 1,
					name = "equip",
					x = 120,
					text_id = "bm_menu_stats_total"
				})
			end

			local value_min, value_max, skill_value_min, skill_value_max, skill_value = nil

			for _, stat in ipairs(self._mweapon_stats_shown) do
				self._mweapon_stats_texts[stat.name].name:set_text(utf8.to_upper(managers.localization:text("bm_menu_" .. stat.name)))

				if stat.range then
					value_min = math.max(base_stats[stat.name].min_value + mods_stats[stat.name].min_value + skill_stats[stat.name].min_value, 0)
					value_max = math.max(base_stats[stat.name].max_value + mods_stats[stat.name].max_value + skill_stats[stat.name].max_value, 0)
				end

				value = math.max(base_stats[stat.name].value + mods_stats[stat.name].value + skill_stats[stat.name].value, 0)

				if self._slot_data.name == equipped_item then
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
						if base and base > 0 then
							base_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_true"))
						else
							base_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_false"))
						end
					
						if value and value > 0 then
							equip_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_true"))
						else
							equip_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_false"))
						end
					end

					self._mweapon_stats_texts[stat.name].equip:set_alpha(1)
					self._mweapon_stats_texts[stat.name].equip:set_text(equip_text)
					self._mweapon_stats_texts[stat.name].base:set_text(base_text)
					self._mweapon_stats_texts[stat.name].skill:set_text(skill_stats[stat.name].skill_in_effect and (skill_stats[stat.name].value > 0 and "+" or "") .. skill_text or "")
					self._mweapon_stats_texts[stat.name].total:set_text("")
					self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.text)

					local positive = value ~= 0 and base < value
					local negative = value ~= 0 and value < base

					if stat.inverse then
						local temp = positive
						positive = negative
						negative = temp
					end

					if stat.range then
						if positive then
							self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.stats_positive)
						elseif negative then
							self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.stats_negative)
						end
					elseif positive then
						self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.stats_positive)
					elseif negative then
						self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.stats_negative)
					else
						self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.text)
					end

					self._mweapon_stats_texts[stat.name].total:set_color(tweak_data.screen_colors.text)
				else
					local equip, equip_min, equip_max = nil

					if stat.range then
						equip_min = math.max(equip_base_stats[stat.name].min_value + equip_mods_stats[stat.name].min_value + equip_skill_stats[stat.name].min_value, 0)
						equip_max = math.max(equip_base_stats[stat.name].max_value + equip_mods_stats[stat.name].max_value + equip_skill_stats[stat.name].max_value, 0)
					end

					equip = math.max(equip_base_stats[stat.name].value + equip_mods_stats[stat.name].value + equip_skill_stats[stat.name].value, 0)
					local format_string = "%0." .. tostring(stat.num_decimals or 0) .. "f"
					local equip_text = equip and format_round(equip, stat.round_value)
					local total_text = value and format_round(value, stat.round_value)
					local equip_min_text = equip_min and format_round(equip_min, true)
					local equip_max_text = equip_max and format_round(equip_max, true)
					local total_min_text = value_min and format_round(value_min, true)
					local total_max_text = value_max and format_round(value_max, true)
					local color_ranges = {}

					if stat.range then
						if equip_min ~= equip_max then
							equip_text = equip_min_text .. " (" .. equip_max_text .. ")"
						end

						if value_min ~= value_max then
							total_text = total_min_text .. " (" .. total_max_text .. ")"
						end
					end

					if stat.suffix then
						equip_text = equip_text .. tostring(stat.suffix)
						total_text = total_text .. tostring(stat.suffix)
					end

					if stat.prefix then
						equip_text = tostring(stat.prefix) .. equip_text
						total_text = tostring(stat.prefix) .. total_text
					end

					if stat.bool then
						if value and value > 0 then
							total_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_true"))
						else
							total_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_false"))
						end
					
						if equip and equip > 0 then
							equip_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_true"))
						else
							equip_text = utf8.to_upper(managers.localization:text("bm_menu_auto_counter_false"))
						end
					end

					self._mweapon_stats_texts[stat.name].equip:set_alpha(0.75)
					self._mweapon_stats_texts[stat.name].equip:set_text(equip_text)
					self._mweapon_stats_texts[stat.name].base:set_text("")
					self._mweapon_stats_texts[stat.name].skill:set_text("")
					self._mweapon_stats_texts[stat.name].total:set_text(total_text)

					if stat.range then
						local positive = equip_min < value_min
						local negative = value_min < equip_min

						if stat.inverse then
							local temp = positive
							positive = negative
							negative = temp
						end

						local color_range_min = {
							start = 0,
							stop = utf8.len(total_min_text)
						}

						if positive then
							color_range_min.color = tweak_data.screen_colors.stats_positive
						elseif negative then
							color_range_min.color = tweak_data.screen_colors.stats_negative
						else
							color_range_min.color = tweak_data.screen_colors.text
						end

						table.insert(color_ranges, color_range_min)

						positive = equip_max < value_max
						negative = value_max < equip_max

						if stat.inverse then
							local temp = positive
							positive = negative
							negative = temp
						end

						local color_range_max = {
							start = color_range_min.stop + 1
						}
						color_range_max.stop = color_range_max.start + 3 + utf8.len(total_max_text)

						if positive then
							color_range_max.color = tweak_data.screen_colors.stats_positive
						elseif negative then
							color_range_max.color = tweak_data.screen_colors.stats_negative
						else
							color_range_max.color = tweak_data.screen_colors.text
						end

						table.insert(color_ranges, color_range_max)
					else
						local positive = equip < value
						local negative = value < equip

						if stat.inverse then
							local temp = positive
							positive = negative
							negative = temp
						end

						local color_range = {
							start = 0,
							stop = utf8.len(total_text)
						}

						if positive then
							color_range.color = tweak_data.screen_colors.stats_positive
						elseif negative then
							color_range.color = tweak_data.screen_colors.stats_negative
						else
							color_range.color = tweak_data.screen_colors.text
						end

						table.insert(color_ranges, color_range)
					end

					self._mweapon_stats_texts[stat.name].total:set_color(tweak_data.screen_colors.text)
					self._mweapon_stats_texts[stat.name].equip:set_color(tweak_data.screen_colors.text)

					for _, color_range in ipairs(color_ranges) do
						self._mweapon_stats_texts[stat.name].total:set_range_color(color_range.start, color_range.stop, color_range.color)
					end
				end
			end
		end
		
		--self._redefined_melee_gui = true
	end
end)

function BlackMarketGui:_get_melee_weapon_stats(name)
	local base_stats = {}
	local mods_stats = {}
	local skill_stats = {}
	local stats_data = managers.blackmarket:get_melee_weapon_stats(name)
	local multiple_of = {}
	local has_non_special = managers.player:has_category_upgrade("player", "non_special_melee_multiplier")
	local has_special = managers.player:has_category_upgrade("player", "melee_damage_multiplier")
	local non_special = managers.player:upgrade_value("player", "non_special_melee_multiplier", 1) - 1
	local special = managers.player:upgrade_value("player", "melee_damage_multiplier", 1) - 1

	for i, stat in ipairs(self._mweapon_stats_shown) do
		local skip_rounding = stat.num_decimals
		base_stats[stat.name] = {
			value = 0,
			max_value = 0,
			min_value = 0
		}
		mods_stats[stat.name] = {
			value = 0,
			max_value = 0,
			min_value = 0
		}
		skill_stats[stat.name] = {
			value = 0,
			max_value = 0,
			min_value = 0
		}

		if stat.name == "damage" then
			local base_min = stats_data.min_damage * tweak_data.gui.stats_present_multiplier
			local base_max = stats_data.max_damage * tweak_data.gui.stats_present_multiplier
			local dmg_mul = managers.player:upgrade_value("player", "melee_" .. tostring(tweak_data.blackmarket.melee_weapons[name].stats.weapon_type) .. "_damage_multiplier", 1)
			local skill_mul = dmg_mul * ((has_non_special and has_special and math.max(non_special, special) or 0) + 1) - 1
			local skill_min = skill_mul
			local skill_max = skill_mul
			base_stats[stat.name] = {
				min_value = base_min,
				max_value = base_max,
				value = (base_min + base_max) / 2
			}
			skill_stats[stat.name] = {
				min_value = skill_min,
				max_value = skill_max,
				value = (skill_min + skill_max) / 2,
				skill_in_effect = skill_min > 0 or skill_max > 0
			}
		elseif stat.name == "damage_effect" then
			local base_min = stats_data.min_damage_effect
			local base_max = stats_data.max_damage_effect
			base_stats[stat.name] = {
				min_value = base_min,
				max_value = base_max,
				value = (base_min + base_max) / 2
			}
			local dmg_mul = managers.player:upgrade_value("player", "melee_" .. tostring(tweak_data.blackmarket.melee_weapons[name].stats.weapon_type) .. "_damage_multiplier", 1) - 1
			local gst_skill = managers.player:upgrade_value("player", "melee_knockdown_mul", 1) - 1
			local skill_mul = (1 + dmg_mul) * (1 + gst_skill) - 1
			local skill_min = skill_mul
			local skill_max = skill_mul
			skill_stats[stat.name] = {
				skill_min = skill_min,
				skill_max = skill_max,
				min_value = skill_min,
				max_value = skill_max,
				value = (skill_min + skill_max) / 2,
				skill_in_effect = skill_min > 0 or skill_max > 0
			}
		elseif stat.name == "charge_time" then
			local base = stats_data.charge_time
			base_stats[stat.name] = {
				value = base,
				min_value = base,
				max_value = base
			}
		elseif stat.name == "auto_counter" then
			local base_min = stats_data.auto_counter
			local base_max = stats_data.auto_counter
			base_stats[stat.name] = {
				min_value = base_min and 1 or 0,
				max_value = base_max and 1 or 0,
				value = base_min and 1 or 0
			}
		elseif stat.name == "concealment" then
			local base = managers.blackmarket:_calculate_melee_weapon_concealment(name)
			local skill = managers.blackmarket:concealment_modifier("melee_weapons")
			base_stats[stat.name] = {
				min_value = base,
				max_value = base,
				value = base
			}
			skill_stats[stat.name] = {
				min_value = skill,
				max_value = skill,
				value = skill,
				skill_in_effect = skill > 0
			}
		end

		if stat.multiple_of then
			table.insert(multiple_of, {
				stat.name,
				stat.multiple_of
			})
		end

		base_stats[stat.name].real_value = base_stats[stat.name].value
		mods_stats[stat.name].real_value = mods_stats[stat.name].value
		skill_stats[stat.name].real_value = skill_stats[stat.name].value
		base_stats[stat.name].real_min_value = base_stats[stat.name].min_value
		mods_stats[stat.name].real_min_value = mods_stats[stat.name].min_value
		skill_stats[stat.name].real_min_value = skill_stats[stat.name].min_value
		base_stats[stat.name].real_max_value = base_stats[stat.name].max_value
		mods_stats[stat.name].real_max_value = mods_stats[stat.name].max_value
		skill_stats[stat.name].real_max_value = skill_stats[stat.name].max_value
	end

	for i, data in ipairs(multiple_of) do
		local multiplier = data[1]
		local stat = data[2]
		base_stats[multiplier].min_value = base_stats[stat].real_min_value * base_stats[multiplier].real_min_value
		base_stats[multiplier].max_value = base_stats[stat].real_max_value * base_stats[multiplier].real_max_value
		base_stats[multiplier].value = (base_stats[multiplier].min_value + base_stats[multiplier].max_value) / 2
	end

	for i, stat in ipairs(self._mweapon_stats_shown) do
		if not stat.index then
			if skill_stats[stat.name].value and base_stats[stat.name].value then
				skill_stats[stat.name].value = base_stats[stat.name].value * skill_stats[stat.name].value
				base_stats[stat.name].value = base_stats[stat.name].value
			end

			if skill_stats[stat.name].min_value and base_stats[stat.name].min_value then
				skill_stats[stat.name].min_value = base_stats[stat.name].min_value * skill_stats[stat.name].min_value
				base_stats[stat.name].min_value = base_stats[stat.name].min_value
			end

			if skill_stats[stat.name].max_value and base_stats[stat.name].max_value then
				skill_stats[stat.name].max_value = base_stats[stat.name].max_value * skill_stats[stat.name].max_value
				base_stats[stat.name].max_value = base_stats[stat.name].max_value
			end
		end
	end

	return base_stats, mods_stats, skill_stats
end
