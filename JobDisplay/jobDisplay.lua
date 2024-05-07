_addon.name = 'Job Display'
_addon.author = 'Hylin'
_addon.version = '0.1'
_addon.commands = {'jobdisplay','jd'}


require('sets')
require('functions')
require('logger')
texts = require('texts')
config = require('config')
res = require('resources')

settings = config.load("data/settings.xml")
ability_data = config.load("data/ability_data.xml")

show_all_skills = settings['show_all_skills']
color_active = '\\cs('..settings.color_active.r..','..settings.color_active.g..','..settings.color_active.b..')'
color_ready = '\\cs('..settings.color_ready.r..','..settings.color_ready.g..','..settings.color_ready.b..')'
color_flash = '\\cs('..settings.color_flash.r..','..settings.color_flash.g..','..settings.color_flash.b..')'
color_timer = '\\cs('..settings.color_timer.r..','..settings.color_timer.g..','..settings.color_timer.b..')'

max_width = 10
columns = settings.columns
jd_info_table = {}
job_display = nil
show_display = false
pet_exists = false
last_x = settings.display.pos.x
last_y = settings.display.pos.y

stratagems_total = 0
stratagems_time = 0

function getJobData()

	if windower.ffxi.get_mob_by_target('pet') then
		pet_exists = true
	else
		pet_exists = false 
	end

	local player_info = windower.ffxi.get_player()
	local ability_info_table = windower.ffxi.get_abilities()['job_abilities']

	local main_job_abilities = ability_data[string.lower(player_info['main_job'])]
	local sub_job_abilities = ability_data[string.lower(player_info['sub_job'])]

	if player_info['main_job'] == "SCH" and player_info['main_job_level'] == 99 and player_info['job_points']['sch']['jp_spent'] >= 550 then
		stratagems_total = 5
		stratagems_time = 33
	elseif player_info['main_job'] == "SCH" and player_info['main_job_level'] >= 90 then
		stratagems_total = 5
		stratagems_time = 48
	elseif player_info['main_job'] == "SCH" and player_info['main_job_level'] >= 70 then
		stratagems_total = 4
		stratagems_time = 60
	elseif (player_info['main_job'] == "SCH" and player_info['main_job_level'] >= 50) or (player_info['sub_job'] == "SCH" and player_info['sub_job_level'] >= 50) then
		stratagems_total = 3
		stratagems_time = 80
	elseif (player_info['main_job'] == "SCH" and player_info['main_job_level'] >= 30) or (player_info['sub_job'] == "SCH" and player_info['sub_job_level'] >= 30) then
		stratagems_total = 2
		stratagems_time = 120
	elseif (player_info['main_job'] == "SCH" and player_info['main_job_level'] >= 10) or (player_info['sub_job'] == "SCH" and player_info['sub_job_level'] >= 10) then
		stratagems_total = 1
		stratagems_time = 240
	end

	for abilityName, abilityInfo in pairs(main_job_abilities) do
		if abilityInfo.type == 'spell' then
			for spellId, spellInfo in pairs(res.spells) do
				if string.lower(spellInfo['en']) == string.gsub(string.lower(abilityName), "_", " ") then
					table.insert(ability_info_table, spellInfo)
				end
			end
		end
	end
	for abilityName, abilityInfo in pairs(sub_job_abilities) do
		if abilityInfo.type == 'spell' then
			for spellId, spellInfo in pairs(res.spells) do
				if string.lower(spellInfo['en']) == string.gsub(string.lower(abilityName), "_", " ") then
					table.insert(ability_info_table, spellInfo)
				end
			end
		end
	end

	for key, abilityId in pairs(ability_info_table) do
		local abilityInfo = {}
		if res.job_abilities[abilityId] then
			abilityInfo = res.job_abilities[abilityId]
		elseif abilityId.id then 
			abilityInfo = abilityId
		end

		local abilityName = abilityInfo['en']
		local lowerSpaceAbilityName = string.gsub(string.gsub(string.gsub(string.lower(abilityName), " ", "_"),"'", ""),":", "")
		local recastId = abilityInfo['recast_id']
		local status = abilityInfo['status']
		if abilityName == 'Light Arts' then
			status = {status,401}
		elseif abilityName == 'Dark Arts' then
			status = {status,402}
		end

		local abilitySettings = nil
		if main_job_abilities and main_job_abilities[lowerSpaceAbilityName] then
			abilitySettings = main_job_abilities[lowerSpaceAbilityName]
		elseif sub_job_abilities and sub_job_abilities[lowerSpaceAbilityName] then
			abilitySettings = sub_job_abilities[lowerSpaceAbilityName]
		end

		if (abilitySettings and abilitySettings.display) or show_all_skills then
			local abilityType = "ability"
			local weight = 100
			local flash = false
			if abilitySettings then
				if abilitySettings.type then
					abilityType = abilitySettings.type
				end
				if abilitySettings.weight then
					weight = abilitySettings.weight
				end
				if abilitySettings.flash then
					flash = abilitySettings.flash
				end
			end

			tempInfoTable = {}
			tempInfoTable['name'] = abilityName
			tempInfoTable['recastId'] = recastId
			tempInfoTable['status'] = status
			tempInfoTable['type'] = abilityType
			tempInfoTable['flash'] = flash
			tempInfoTable['value'] = 0
			tempInfoTable['weight'] = weight

			table.insert(jd_info_table, tempInfoTable)
		end
	end

	table.sort(jd_info_table, function(x, y)
		xOrder = 2
		if x['type'] == 'stance' then
			xOrder = 1
		end
		yOrder = 2
		if y['type'] == 'stance' then
			yOrder = 1
		end

		if xOrder ~= yOrder then
			return xOrder < yOrder 
		else
			return x['weight'] > y['weight']
		end
	end)

	local column_count = 1
	for key, info in ipairs(jd_info_table) do
		local display_text = ' ${ability'..key..'|error} '
		if(job_display == nil) then
			job_display = texts.new(display_text,settings.display)
			column_count = 1
		else
			if column_count >= columns then
				job_display:appendline(display_text)
				column_count = 1
			else
				job_display:append(display_text)
				column_count = column_count + 1
			end
		end
	end

	show_display = true
end

function checkForBuff(statusId, buffs)
	for key, info in pairs(buffs) do
		if (type(statusId) == 'table' and (info == statusId[1] or info == statusId[2])) or info == statusId then
			return true
		end
	end
	return false
end

function reset_texts()
	if job_display then
		job_display:hide()
	end
	show_display = false
	jd_info_table = {}
	job_display = nil

	coroutine.schedule(getJobData, 1)
end

getJobData()

windower.register_event('job change', function()
	reset_texts()
end)

windower.register_event('prerender', function()
	if settings.display.pos.x ~= last_x or settings.display.pos.y ~= last_y then
		last_x = settings.display.pos.x
		last_y = settings.display.pos.y
		config.save(settings)
	end

	if (pet_exists and windower.ffxi.get_mob_by_target('pet') == nil) or (not pet_exists and windower.ffxi.get_mob_by_target('pet')) then
		reset_texts()
	elseif show_display and job_display then

		jd_abilityRecastInfo = windower.ffxi.get_ability_recasts()
		jd_spellRecastInfo = windower.ffxi.get_spell_recasts()
		evenTime = math.fmod(math.ceil(os.clock()*2), 2) == 0
		local player_buffs = windower.ffxi.get_player()['buffs']

		job_display_info = S{}

		for key, info in ipairs(jd_info_table) do

			local recastVal = 0
			local buffActive = checkForBuff(info['status'], player_buffs)
			local value_color = color_ready
			local label_color = color_ready
			local display_value = 0
			local display_label = info['name']
			local width_offset = 0


			if (info['name'] == "Light Arts" and checkForBuff(401, player_buffs)) or (info['name'] == "Dark Arts" and checkForBuff(402, player_buffs)) then
				display_label = '+ '..display_label..' +'
			end


			if info['type'] == 'ability' and info['recastId'] ~= nil and jd_abilityRecastInfo[info['recastId']] ~= nil then
				if info['name'] == 'Stratagems' then
					recastVal = math.ceil(jd_abilityRecastInfo[231])
				else
					recastVal = math.ceil(jd_abilityRecastInfo[info['recastId']])
				end
			end


			if info['type'] == 'spell' and info['recastId'] ~= nil and jd_spellRecastInfo[info['recastId']] ~= nil then
				recastVal = math.ceil(jd_spellRecastInfo[info['recastId']] / 60.0)
			end

			if buffActive then
				value_color = color_active
				label_color = color_active
			end

			if info['name'] == 'Stratagems' then
				if recastVal <= 0 then
					display_value =  "5/5 00:00"
					value_color = color_ready
				else
					--local math.ceil(recastVal / stratagems_time)
					local stratagems_remaining = stratagems_total - math.ceil(recastVal / stratagems_time)
					recastVal = recastVal - (math.floor(recastVal / stratagems_time) * 33)
					if recastVal == 0 and stratagems_remaining ~= 5 then
						recastVal = 33
					end
					local display_time = string.format("%02d:%02d", 0, recastVal)


					if stratagems_remaining == 0 then
						display_value = tostring(stratagems_remaining).."/"..tostring(stratagems_total).." "..display_time

						value_color = color_timer
						label_color = color_timer
					else
						display_value = tostring(stratagems_remaining).."/"..tostring(stratagems_total).." "..color_timer..display_time
						width_offset = width_offset + string.len(color_timer)
						value_color = color_ready
					end
				end
			else

				if recastVal <= 0 then
					display_value = 'READY'

					if info['name'] == 'Sublimation' then
						local sublimation_full = false
						if checkForBuff(188, player_buffs) then
							sublimation_full = true
							display_value = '*****'
						end

						if buffActive then
							if evenTime then
								display_value = '*****'
							else
								display_value = '+++++'
							end
						else
							if sublimation_full and evenTime then
								value_color = color_active
								label_color = color_active
							elseif info['flash'] and evenTime then
								value_color = color_flash
							end
						end
					else
						if not buffActive then
							value_color = color_ready
							if info['flash'] and evenTime then
								value_color = color_flash
							end
						end
					end
				else
					local minutes = math.floor(recastVal / 60)
					local seconds = recastVal - (minutes * 60)
					local display_time = string.format("%02d:%02d", minutes, seconds)
					display_value = display_time

					if not buffActive then
						value_color = color_timer
						label_color = color_timer
					end
				end
			end

			current_width = (string.len(display_label) + string.len(display_value) + 2) - width_offset
			if current_width > max_width then
				max_width = current_width
			end

			diff_width = max_width - current_width

			local display_text = label_color..display_label..": "

			for i=1, diff_width do
				display_text = display_text..' '
			end

			display_text = display_text..value_color..display_value
			
			if key % columns ~= 0 then
				display_text = display_text..color_ready..'  |'
			end

			job_display_info['ability'..key] = display_text
			
		end

		job_display:update(job_display_info)
		job_display:show()
	end
end)

windower.register_event('zone change', function()
    reset_texts()
end)

windower.register_event('addon command', function(...)
	local commands = {...}
    local player = windower.ffxi.get_player()
    commands[1] = commands[1] and commands[1]:lower()
    if not player then
    elseif not commands[1] or commands[1] == 'help' then
        notice('Commands: command | alias [optional]')
        notice(' //jobdisplay | //jd')
        notice(' columns | cols | col  [1-20]	- Set number of columns to display')
        notice(' showall | all  			        - Toggle display of all abilities available')
        notice(' pos [x] [y]					   - Set text box position')
    elseif (commands[1] == 'columns' or commands[1] == 'cols' or commands[1] == 'col') then
    	
    	newColumns = tonumber(commands[2])

    	if newColumns and newColumns > 0 and newColumns < 20 then
    		columns = newColumns
    		settings.columns = newColumns
    		config.save(settings, player.name)
	    	reset_texts()
        	notice('columns set to '..tostring(newColumns))
	    else
        	notice('second argument must be a number between 1 and 20')
	    end
    elseif commands[1] == 'showall' or commands[1] == 'all' then
    	show_all_skills = not show_all_skills
    	settings.show_all_skills = not show_all_skills
    	config.save(settings, player.name)
    	reset_texts()
        notice('show all skills: '..tostring(show_all_skills))
    elseif commands[1] == 'pos' then
    	local new_x = tonumber(commands[2])
    	local new_y = tonumber(commands[3])
    	if new_x and new_y then
    		settings.display.pos.x = new_x
			settings.display.pos.y = new_y

	    	config.save(settings, player.name)
	    	reset_texts()
        	notice('position set to x: '..commands[2]..' y: '..commands[3])
    	else
        	notice('second and third argument must be a number')
    	end
    elseif commands[1] == 'reset' then
    	reset_texts()
    elseif commands[1] == 'recasts' then
		for key, info in pairs(windower.ffxi.get_ability_recasts()) do
			print(key..' - '..info)
		end    	
    elseif commands[1] == 'buffs' then
		for key, info in pairs(windower.ffxi.get_player()['buffs']) do
			print(key..' - '..info)
		end    	
    end
end)