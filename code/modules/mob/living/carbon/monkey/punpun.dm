/mob/living/carbon/monkey/punpun //along with a few special persistence features, pun pun is no longer just a normal monkey
	name = "Pun Pun" //C A N O N
	desc = "The bartender's monkey. Loyal to them, and knows a couple of tricks."
	unique_name = 0
	welcome_message = "<span class='warning'>ALL PAST LIVES ARE FORGOTTEN.</span>\n\
	<b>You are [name], a bar monkey onboard Space Station 13. \n\
	As the Bartender's pet monkey, you are loyal to them. They have taught you a few tricks, mostly related to bartending and waitering.\n\
	While you're pretty smart, you are nowhere near as intelligent as a human in any field, and have no idea how to use most tools and technologies barring the booze and soda dispensers.</b>"
	var/new_mob_message = span_notice("[name] seems to have zoned back in.")
	var/ancestor_name
	var/ancestor_chain = 1
	var/relic_hat	//Note: these two are paths
	var/relic_mask
	var/memory_saved = FALSE
	var/list/pet_monkey_names = list("Pun Pun", "Bubbles", "Mojo", "George", "Darwin", "Aldo", "Caeser", "Kanzi", "Kong", "Terk", "Grodd", "Mala", "Bojangles", "Coco", "Able", "Baker", "Scatter", "Norbit", "Travis")
	var/list/rare_pet_monkey_names = list("Professor Bobo", "Deempisi's Revenge", "Furious George", "King Louie", "Dr. Zaius", "Jimmy Rustles", "Dinner", "Lanky")

/mob/living/carbon/monkey/punpun/Initialize(mapload)
	Read_Memory()
	if(ancestor_name)
		name = ancestor_name
		if(ancestor_chain > 1)
			name += " \Roman[ancestor_chain]"
	else
		if(prob(5))
			name = pick(rare_pet_monkey_names)
		else
			name = pick(pet_monkey_names)
		gender = pick(MALE, FEMALE)
	. = ..()

	//These have to be after the parent new to ensure that the monkey
	//bodyparts are actually created before we try to equip things to
	//those slots
	if(ancestor_chain > 1)
		generate_fake_scars(rand(ancestor_chain, ancestor_chain * 4))
	if(relic_hat)
		equip_to_slot_or_del(new relic_hat, ITEM_SLOT_HEAD)
	if(relic_mask)
		equip_to_slot_or_del(new relic_mask, ITEM_SLOT_MASK)

/mob/living/carbon/monkey/punpun/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	if(!stat && SSticker.current_state == GAME_STATE_FINISHED && !memory_saved)
		Write_Memory(FALSE, FALSE)
		memory_saved = TRUE
	..()

/mob/living/carbon/monkey/punpun/death(gibbed)
	if(!memory_saved)
		Write_Memory(TRUE, gibbed)
	..()

/mob/living/carbon/monkey/punpun/proc/Read_Memory()
	if(fexists("data/npc_saves/Punpun.sav")) //legacy compatability to convert old format to new
		var/savefile/S = new /savefile("data/npc_saves/Punpun.sav")
		S["ancestor_name"]	>> ancestor_name
		S["ancestor_chain"] >> ancestor_chain
		S["relic_hat"]		>> relic_hat
		S["relic_mask"]		>> relic_mask
		fdel("data/npc_saves/Punpun.sav")
	else
		var/json_file = file("data/npc_saves/Punpun.json")
		if(!fexists(json_file))
			return
		var/list/json = json_decode(file2text(json_file))
		ancestor_name = json["ancestor_name"]
		ancestor_chain = json["ancestor_chain"]
		relic_hat = json["relic_hat"]
		relic_mask = json["relic_hat"]

/mob/living/carbon/monkey/punpun/proc/Write_Memory(dead, gibbed)
	var/json_file = file("data/npc_saves/Punpun.json")
	var/list/file_data = list()
	if(gibbed)
		file_data["ancestor_name"] = null
		file_data["ancestor_chain"] = null
		file_data["relic_hat"] = null
		file_data["relic_mask"] = null
	else
		file_data["ancestor_name"] = ancestor_name ? ancestor_name : name
		file_data["ancestor_chain"] = dead ? ancestor_chain + 1 : ancestor_chain
		file_data["relic_hat"] = head ? head.type : null
		file_data["relic_mask"] = wear_mask ? wear_mask.type : null
	fdel(json_file)
	WRITE_FILE(json_file, json_encode(file_data))

/mob/living/carbon/monkey/punpun/proc/activate(mob/user)
	if(QDELETED(brainmob))
		return
	if(is_occupied() || is_banned_from(user.ckey, ROLE_POSIBRAIN) || QDELETED(brainmob) || QDELETED(src) || QDELETED(user))
		return
	if(!(GLOB.ghost_role_flags & GHOSTROLE_SILICONS))
		to_chat(user, span_warning("Central Command has temporarily outlawed monkey intelligence in this sector..."))
		return
	if(user.suiciding) //if they suicided, they're out forever.
		to_chat(user, span_warning("[src] shakes their head. Sadly, they refuse to be the host of someone who suicided!"))
		return
	if(user.ckey in brain_users) //no double dipping
		to_chat(user, span_warning("[src] shakes their head. You have already used a positronic brain!"))
		return
	var/playtime = SSjob.GetJob("Cyborg").required_playtime_remaining(user.client)
	if(playtime)
		to_chat(user, span_warning("Positronic brains are beyond your knowledge to control."))
		to_chat(user, span_warning("In order to play as a positron brain, you require [playtime] more minutes of experience on-board the station."))
		return
	var/posi_ask = tgui_alert(usr,"Become [name]? (Warning, You can no longer be revived, and all past lives will be forgotten!)","Are you positive?",list("Yes","No"))
	if(posi_ask == "No" || QDELETED(src))
		return
	if(brainmob.suiciding) //clear suicide status if the old occupant suicided.
		brainmob.set_suicide(FALSE)
	transfer_personality(user)

/mob/living/carbon/monkey/punpun/transfer_identity(mob/living/carbon/C)
	name = "[initial(name)] ([C])"
	brainmob.name = C.real_name
	brainmob.real_name = C.real_name
	if(C.has_dna())
		if(!brainmob.stored_dna)
			brainmob.stored_dna = new /datum/dna/stored(brainmob)
		C.dna.copy_dna(brainmob.stored_dna)
	brainmob.timeofhostdeath = C.timeofdeath
	brainmob.set_stat(CONSCIOUS)
	if(brainmob.mind)
		brainmob.mind.assigned_role = new_role
	if(C.mind)
		C.mind.transfer_to(brainmob)

	brainmob.mind.remove_all_antag()
	brainmob.mind.wipe_memory()
	update_appearance(UPDATE_ICON)
	return ..()

/mob/living/carbon/monkey/punpun/proc/transfer_personality(mob/candidate)
	if(QDELETED(brainmob))
		return
	if(is_occupied()) //Prevents hostile takeover if two ghosts get the prompt or link for the same brain.
		to_chat(candidate, span_warning("This [name] was taken over before you could get to it! Perhaps it might be available later?"))
		return FALSE
	if(candidate.mind && !isobserver(candidate))
		candidate.mind.transfer_to(brainmob)
	else
		brainmob.ckey = candidate.ckey
	name = "[initial(name)] ([brainmob.name])"
	to_chat(brainmob, welcome_message)
	brainmob.mind.assigned_role = new_role
	brainmob.set_stat(CONSCIOUS)
	brainmob.remove_from_dead_mob_list()
	brainmob.add_to_alive_mob_list()
	LAZYADD(brain_users, brainmob.ckey)
	ADD_TRAIT(brainmob, TRAIT_PACIFISM, POSIBRAIN_TRAIT)

	visible_message(new_mob_message)
	check_success()

	GLOB.poi_list -= src
	var/list/spawners = GLOB.mob_spawners[initial(name)]
	LAZYREMOVE(spawners, src)
	if(!LAZYLEN(spawners))
		GLOB.mob_spawners -= initial(name)

	return TRUE


/mob/living/carbon/monkey/punpun/examine(mob/user)
	. = ..()
	if(brainmob && brainmob.key)
		switch(brainmob.stat)
			if(CONSCIOUS)
				if(!brainmob.client)
					. += "It appears to be in stand-by mode." //afk
			if(DEAD)
				. += span_deadsay("It appears to be completely inactive.")
	else
		. += "[dead_message]"

/mob/living/carbon/monkey/punpun/Initialize(mapload)
	. = ..()
	var/area/A = get_area(src)
	brainmob = new(src)
	var/new_name
	if(!LAZYLEN(possible_names))
		new_name = pick(GLOB.posibrain_names)
	else
		new_name = pick(possible_names)
	brainmob.name = "[new_name]-[rand(100, 999)]"
	brainmob.real_name = brainmob.name
	brainmob.forceMove(src)
	brainmob.container = src
	if(autoping && A)
		notify_ghosts("A positronic brain has been created in \the [A.name].", source = src, action=NOTIFY_ATTACKORBIT, flashwindow = FALSE, ignore_key = POLL_IGNORE_POSIBRAIN)
	GLOB.poi_list |= src
	LAZYADD(GLOB.mob_spawners[initial(name)], src) //Yogs -- Adds positronic brains to Spawner Menu

/mob/living/carbon/monkey/punpun/Destroy()
	GLOB.poi_list -= src
	var/list/spawners = GLOB.mob_spawners[initial(name)]
	LAZYREMOVE(spawners, src)
	if(!LAZYLEN(spawners))
		GLOB.mob_spawners -= initial(name)
	return ..()

/mob/living/carbon/monkey/punpun/attackby(obj/item/O, mob/user)
	if(istype(O, /obj/item/aiModule))
		var/obj/item/aiModule/M = O
		M.install(laws, user)
	return


/mob/living/carbon/monkey/punpun/update_icon_state()
	. = ..()
	if(searching)
		icon_state = "[initial(icon_state)]-searching"
		return
	if(brainmob && brainmob.key)
		icon_state = "[initial(icon_state)]-occupied"
		return
	icon_state = initial(icon_state)

/mob/living/carbon/monkey/punpun/add_mmi_overlay()
	return
