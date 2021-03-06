/proc/CreateGeneralRecord()
	var/datum/data/record/G = new /datum/data/record()
	G.fields["name"] = "New Record"
	G.fields["id"] = text("[]", add_zero(num2hex(rand(1, 1.6777215E7)), 6))
	G.fields["rank"] = "Unassigned"
	G.fields["real_rank"] = "Unassigned"
	G.fields["sex"] = "Male"
	G.fields["age"] = "Unknown"
	G.fields["fingerprint"] = "Unknown"
	G.fields["p_stat"] = "Active"
	G.fields["m_stat"] = "Stable"
	G.fields["species"] = "Human"
	G.fields["home_system"]	= "Unknown"
	G.fields["citizenship"]	= "Unknown"
	G.fields["faction"]		= "Unknown"
	G.fields["religion"]	= "Unknown"
	G.fields["photo_f"] = new /icon()
	G.fields["photo_s"] = new /icon()
	data_core.general += G
	return G

/proc/CreateSecurityRecord(name, id)
	var/datum/data/record/R = new /datum/data/record()
	R.fields["name"] = name
	R.fields["id"] = id
	R.name = text("Security Record #[id]")
	R.fields["criminal"] = "None"
	R.fields["mi_crim"] = "None"
	R.fields["mi_crim_d"] = "No minor crime convictions."
	R.fields["ma_crim"] = "None"
	R.fields["ma_crim_d"] = "No major crime convictions."
	R.fields["notes"] = "No notes."
	data_core.security += R
	return R
