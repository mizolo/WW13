/turf/floor/attackby(obj/item/C as obj, mob/user as mob)

	if(!C || !user)
		return 0

	if(istype(C, /obj/item/stack/cable_coil) || (flooring && istype(C, /obj/item/stack/rods)))
		return ..(C, user)

	//var/dir_to_floor =

	var/your_dir = "NORTH"

	switch (user.dir)
		if (NORTH)
			your_dir = "NORTH"
		if (SOUTH)
			your_dir = "SOUTH"
		if (EAST)
			your_dir = "EAST"
		if (WEST)
			your_dir = "WEST"

	var/sandbag_time = 50

	if (ishuman(user))
		var/mob/living/carbon/human/H = user
		if (istype(H.original_job, /datum/job/german/engineer))
			sandbag_time = 20
		if (istype(H.original_job, /datum/job/russian/engineer))
			sandbag_time = 20

	if (src == get_step(user, user.dir))
		if (istype(C, /obj/item/weapon/sandbag))
			if (alert(user, "This will start building a sandbag [your_dir] of you.", "", "Continue", "Stop") == "Continue")
				visible_message("<span class='danger'>[user] starts constructing the base of a sandbag wall.</span>", "<span class='danger'>You start constructing the base of a sandbag wall.</span>")
				if (do_after(user, sandbag_time, user.loc))
					var/obj/item/weapon/sandbag/bag = C
					var/progress = bag.sand_amount
					qdel(C)
					var/obj/structure/window/sandbag/incomplete/sandbag = new/obj/structure/window/sandbag/incomplete(src, user)
					sandbag.progress = progress
					visible_message("<span class='danger'>[user] finishes constructing the base of a sandbag wall. Anyone can now add to it.</span>")
			return


	if(flooring)
		if(istype(C, /obj/item/weapon/crowbar))
			if(broken || burnt)
				user << "<span class='notice'>You remove the broken [flooring.descriptor].</span>"
				make_plating()
			else if(flooring.flags & TURF_IS_FRAGILE)
				user << "<span class='danger'>You forcefully pry off the [flooring.descriptor], destroying them in the process.</span>"
				make_plating()
			else if(flooring.flags & TURF_REMOVE_CROWBAR)
				user << "<span class='notice'>You lever off the [flooring.descriptor].</span>"
				make_plating(1)
			else
				return
			playsound(src, 'sound/items/Crowbar.ogg', 80, 1)
			return
		else if(istype(C, /obj/item/weapon/screwdriver) && (flooring.flags & TURF_REMOVE_SCREWDRIVER))
			if(broken || burnt)
				return
			user << "<span class='notice'>You unscrew and remove the [flooring.descriptor].</span>"
			make_plating(1)
			playsound(src, 'sound/items/Screwdriver.ogg', 80, 1)
			return
		else if(istype(C, /obj/item/weapon/wrench) && (flooring.flags & TURF_REMOVE_WRENCH))
			user << "<span class='notice'>You unwrench and remove the [flooring.descriptor].</span>"
			make_plating(1)
			playsound(src, 'sound/items/Ratchet.ogg', 80, 1)
			return
		else if(istype(C, /obj/item/weapon/shovel) && (flooring.flags & TURF_REMOVE_SHOVEL))
			user << "<span class='notice'>You shovel off the [flooring.descriptor].</span>"
			make_plating(1)
			playsound(src, 'sound/items/Deconstruct.ogg', 80, 1)
			return
		else if(istype(C, /obj/item/stack/cable_coil))
			user << "<span class='warning'>You must remove the [flooring.descriptor] first.</span>"
			return
	else
		if(istype(C, /obj/item/stack))
			if(broken || burnt)
				user << "<span class='warning'>This section is too damaged to support anything. Use a welder to fix the damage.</span>"
				return
			var/obj/item/stack/S = C
			var/decl/flooring/use_flooring
			for(var/flooring_type in flooring_types)
				var/decl/flooring/F = flooring_types[flooring_type]
				if(!F.build_type)
					continue
				if((ispath(S.type, F.build_type) || ispath(S.build_type, F.build_type)) && ((S.type == F.build_type) || (S.build_type == F.build_type)))
					use_flooring = F
					break
			if(!use_flooring)
				return
			// Do we have enough?
			if(use_flooring.build_cost && S.get_amount() < use_flooring.build_cost)
				user << "<span class='warning'>You require at least [use_flooring.build_cost] [S.name] to complete the [use_flooring.descriptor].</span>"
				return
			// Stay still and focus...
			if(use_flooring.build_time && !do_after(user, use_flooring.build_time, src))
				return
			if(flooring || !S || !user || !use_flooring)
				return
			if(S.use(use_flooring.build_cost))
				set_flooring(use_flooring)
				playsound(src, 'sound/items/Deconstruct.ogg', 80, 1)
				return
		// Repairs.
		else if(istype(C, /obj/item/weapon/weldingtool))
			var/obj/item/weapon/weldingtool/welder = C
			if(welder.isOn() && (is_plating()))
				if(broken || burnt)
					if(welder.remove_fuel(0,user))
						user << "<span class='notice'>You fix some dents on the broken plating.</span>"
						playsound(src, 'sound/items/Welder.ogg', 80, 1)
						icon_state = "plating"
						burnt = null
						broken = null
					else
						user << "<span class='warning'>You need more welding fuel to complete this task.</span>"
					return
	return ..()


/turf/floor/can_build_cable(var/mob/user)
	if(!is_plating() || flooring)
		user << "<span class='warning'>Removing the tiling first.</span>"
		return 0
	if(broken || burnt)
		user << "<span class='warning'>This section is too damaged to support anything. Use a welder to fix the damage.</span>"
		return 0
	return 1