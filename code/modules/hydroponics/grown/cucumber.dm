/obj/item/seeds/cucumber
	name = "pack of cucumber seeds"
	desc = "These seeds grow into cucumber plants."
	icon_state = "seed-cucumber"
	species = "cucumber"
	plantname = "Cucumber Plant"
	product = /obj/item/reagent_containers/food/snacks/grown/cucumber
	maturation = 10
	production = 1
	yield = 5
	growing_icon = 'icons/obj/hydroponics/growing_vegetables.dmi'
	icon_grow = "cucumber-grow"
	icon_dead = "cucumber-dead"
	genes = list(/datum/plant_gene/trait/repeated_harvest)
	reagents_add = list(/datum/reagent/consumable/nutriment/vitamin = 0.04, /datum/reagent/consumable/nutriment = 0.1)

/obj/item/reagent_containers/food/snacks/grown/cucumber
	seed = /obj/item/seeds/cucumber
	name = "cucumber"
	desc = "Oblong and green, the standard of salads."
	icon_state = "cucumber"
	foodtype = VEGETABLES
	juice_results = list(/datum/reagent/consumable/cucumberjuice = 0)
	tastes = list("cucumber" = 1)


/obj/item/reagent_containers/food/snacks/grown/cucumber/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	if(isliving(hit_atom) && throwingdatum.thrower && isliving(throwingdatum.thrower))
		keep_away(hit_atom, throwingdatum.thrower)

/obj/item/reagent_containers/food/snacks/grown/cucumber/attack(mob/living/target, mob/living/user)
	. = ..()
	keep_away(target, user)

/obj/item/reagent_containers/food/snacks/grown/cucumber/proc/keep_away(mob/living/target, mob/living/user)
	if(target == user)
		return
	if(iscatperson(target))
		var/atom/throw_target = get_edge_target_turf(target, user.dir)
		ADD_TRAIT(target, TRAIT_IMPACTIMMUNE, "cucumber")//keep them away, don't hurt them
		target.throw_at(throw_target, 1, 1, user, FALSE, TRUE, callback = CALLBACK(src, PROC_REF(afterimpact), target))
		//note to self or future coders, please add code that makes it so that felinids get a negative moodlet here

/obj/item/reagent_containers/food/snacks/grown/cucumber/proc/afterimpact(mob/living/M)
	REMOVE_TRAIT(M, TRAIT_IMPACTIMMUNE, "cucumber")
