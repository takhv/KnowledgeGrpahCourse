-- ===========================================================================
--	Civilopedia - Unit Page Layout
-- ===========================================================================

PageLayouts["Unit" ] = function(page)
	local sectionId = page.SectionId;
	local pageId = page.PageId;

	SetPageHeader(page.Title);
	SetPageSubHeader(page.Subtitle);

	local unit = GameInfo.Units[pageId];
	if(unit == nil) then
		return;
	end
	local unitType = unit.UnitType;

	-- Get some info!

	-- Index city-states
	-- City states are always referenced by their civilization type and not leader type
	-- despite game data referencing it that way.
	local city_state_civilizations = {};
	local city_state_leaders = {};
	for row in GameInfo.Civilizations() do
		if(row.StartingCivilizationLevelType == "CIVILIZATION_LEVEL_CITY_STATE") then
			city_state_civilizations[row.CivilizationType] = true;
		end
	end

	for row in GameInfo.CivilizationLeaders() do
		if(city_state_civilizations[row.CivilizationType]) then
			city_state_leaders[row.LeaderType] = row.CivilizationType;
		end
	end

	local unique_to = {};
	if(unit.TraitType) then
		local traitType = unit.TraitType;
		for row in GameInfo.LeaderTraits() do
			if(row.TraitType == traitType) then
				local leader = GameInfo.Leaders[row.LeaderType];
				if(leader) then
					-- If this is a city state, use the civilization type.
					local city_state_civilization = city_state_leaders[row.LeaderType];
					if(city_state_civilization) then
						local civ = GameInfo.Civilizations[city_state_civilization];
						if(civ) then
							table.insert(unique_to, {"ICON_" .. civ.CivilizationType, civ.Name, civ.CivilizationType});
						end
					else
						table.insert(unique_to, {"ICON_" .. row.LeaderType, leader.Name, row.LeaderType});
					end
				end
			end
		end

		for row in GameInfo.CivilizationTraits() do
			if(row.TraitType == traitType) then
				local civ = GameInfo.Civilizations[row.CivilizationType];
				if(civ) then
					table.insert(unique_to, {"ICON_" .. row.CivilizationType, civ.Name, row.CivilizationType});
				end
			end
		end
	end

	-- Many beliefs unlock units using modifiers.
	-- Search for a specific effect type in belief modifiers to see if any refer to this unit.
	local unlock_modifiers = {};
	for row in GameInfo.Modifiers() do
		local info = GameInfo.DynamicModifiers[row.ModifierType];
		if(info) then
			if(info.EffectType == "EFFECT_ADD_RELIGIOUS_UNIT") then
				for args in GameInfo.ModifierArguments() do
					if(args.ModifierId == row.ModifierId) then
						if(args.Name == "UnitType" and args.Value == unitType) then
							unlock_modifiers[row.ModifierId] = true;
						end
					end
				end
			end
		end
	end

	local beliefs = {};
	for row in GameInfo.BeliefModifiers() do
		if(unlock_modifiers[row.ModifierID]) then
			beliefs[row.BeliefType] = true;
		end
	end

	for k,_ in pairs(beliefs) do
		local belief = GameInfo.Beliefs[k];
		if(belief) then
			table.insert(unique_to, {"ICON_" .. belief.BeliefType, belief.Name, belief.BeliefType});
		end
	end

	local replaces;
	local replaced_by = {};
	for row in GameInfo.UnitReplaces() do
		if(row.CivUniqueUnitType == unitType) then
			local u = GameInfo.Units[row.ReplacesUnitType]; 
			if(u and u.TraitType ~= "TRAIT_BARBARIAN") then
				replaces = {"ICON_" .. u.UnitType, u.Name, u.UnitType};
			end
		end

		if(row.ReplacesUnitType == unitType) then
			local u = GameInfo.Units[row.CivUniqueUnitType];
			if(u and u.TraitType ~= "TRAIT_BARBARIAN") then
				table.insert(replaced_by, {"ICON_" .. u.UnitType, u.Name, u.UnitType});
			end
		end
	end

	local function matches_unique(other)
		if(#unique_to > 0) then
			-- Determine who the item is unique to.
			local other_unique_to = {};
			local traitType = other.TraitType;

			-- Other unit is not unique, so it matches.
			if(traitType == nil) then
				return true;
			else
				for leader_trait in GameInfo.LeaderTraits() do
					if(leader_trait.TraitType == traitType) then
						local leader = GameInfo.Leaders[leader_trait.LeaderType];
						if(leader) then
							other_unique_to[leader_trait.LeaderType] = true;

							-- Include Leader's civiliazations
							for cl in GameInfo.CivilizationLeaders() do
								if(cl.LeaderType == leader_trait.LeaderType) then
									other_unique_to[cl.CivilizationType] = true;
								end
							end
						end
					end
				end

				for civ_trait in GameInfo.CivilizationTraits() do
					if(civ_trait.TraitType == traitType) then
						local civ = GameInfo.Civilizations[civ_trait.CivilizationType];
						if(civ) then
							other_unique_to[civ_trait.CivilizationType] = true;

							-- Include Civilization's Leaders
							for cl in GameInfo.CivilizationLeaders() do
								if(cl.CivilizationType == civ_trait.CivilizationType) then
									other_unique_to[cl.LeaderType] = true;
								end
							end
						end
					end
				end
			
				-- Other unit is unique but matches.
				for i, v in ipairs(unique_to) do
					if(other_unique_to[v[3]]) then
						return true;
					end
				end

				return false;
			end
		else
			-- This unit isn't unique.
			return true;
		end
	end

	local upgrades_to = {};		-- the unit(s) of what it upgrades to.
	local upgrades_from = {};	-- the unit(s) of what it upgrades from.
	for row in GameInfo.UnitUpgrades() do
		if(row.Unit == unitType) then
			local u = GameInfo.Units[row.UpgradeUnit];
			if(u and u.TraitType ~= "TRAIT_BARBARIAN") then

				if(matches_unique(u)) then
					table.insert(upgrades_to, {"ICON_" .. u.UnitType, u.Name, u.UnitType});
				end

				for r in GameInfo.UnitReplaces() do
					if(r.ReplacesUnitType == u.UnitType) then
						local replaced_unit = GameInfo.Units[r.CivUniqueUnitType];
						if(replaced_unit and matches_unique(replaced_unit)) then
							table.insert(upgrades_to, {"ICON_" .. replaced_unit.UnitType, replaced_unit.Name, replaced_unit.UnitType});
						end
					end
				end

			end
		end

		if(row.UpgradeUnit == unitType) then
			local u = GameInfo.Units[row.Unit];
			if(u and u.TraitType ~= "TRAIT_BARBARIAN" and matches_unique(u)) then
				table.insert(upgrades_from, {"ICON_" .. u.UnitType, u.Name, u.UnitType});
			end
		end

		-- For unique units, check the upgrade path of the unit they replace. (but make sure another unique unit isn't in the path).
		for r in GameInfo.UnitReplaces() do
			if(r.CivUniqueUnitType == unitType and row.UpgradeUnit == r.ReplacesUnitType) then
				local u = GameInfo.Units[row.Unit];
				if(u and u.TraitType ~= "TRAIT_BARBARIAN" and matches_unique(u)) then
					table.insert(upgrades_from, {"ICON_" .. u.UnitType, u.Name, u.UnitType});
				end
			end
		end
	end

	local obsolete_with;
	if(unit.ObsoleteCivic) then
		local item = GameInfo.Civics[unit.ObsoleteCivic];
		obsolete_with = item and {unit.ObsoleteCivic, item.Name};
	elseif(unit.ObsoleteTech) then
		local item = GameInfo.Technologies[unit.ObsoleteTech];
		obsolete_with = item and {unit.ObsoleteTech, item.Name};
	end

	local requires_buildings = {};
	for row in GameInfo.Unit_BuildingPrereqs() do
		if(row.Unit == unitType) then
			local building = GameInfo.Buildings[row.PrereqBuilding];
			if(building) then
				table.insert(requires_buildings, {"ICON_" .. building.BuildingType, building.Name, building.BuildingType});
			end
		end
	end

	local improvements = {};
	for row in GameInfo.Improvement_ValidBuildUnits() do
		if(row.UnitType == unitType) then
			local improvement = GameInfo.Improvements[row.ImprovementType];
			table.insert(improvements, improvement);
		end
	end

	local routes = {};
	for row in GameInfo.Route_ValidBuildUnits() do
		if(row.UnitType == unitType) then
			local route = GameInfo.Routes[row.RouteType];
			table.insert(routes, route);
		end
	end

	local cost = tonumber(unit.Cost);
	local maintenance = tonumber(unit.Maintenance);
	local purchase_cost;
	if(unit.PurchaseYield) then
		if(unit.PurchaseYield == "YIELD_GOLD") then
			purchase_cost = cost * GlobalParameters.GOLD_PURCHASE_MULTIPLIER * GlobalParameters.GOLD_EQUIVALENT_OTHER_YIELDS;
		else
			purchase_cost = cost *  GlobalParameters.GOLD_EQUIVALENT_OTHER_YIELDS
		end
	end
	
	-- Right Column!
	AddPortrait("ICON_" .. unitType);

	AddRightColumnStatBox("LOC_UI_PEDIA_TRAITS", function(s)
		if(#unique_to > 0) then
			s:AddHeader("LOC_UI_PEDIA_UNIQUE_TO");
			for _, icon in ipairs(unique_to) do
				s:AddIconLabel(icon, icon[2]);
			end
		end
			
		if(replaces) then
			s:AddHeader("LOC_UI_PEDIA_REPLACES");
			s:AddIconLabel(replaces, replaces[2]);
		end

		if(#replaced_by > 0) then
			s:AddHeader("LOC_UI_PEDIA_REPLACED_BY");
			for _, icon in ipairs(replaced_by) do
				s:AddIconLabel(icon, icon[2]);
			end
		end

		if(replaces or #replaced_by > 0) then
			s:AddSeparator();
		end

		if(#upgrades_to > 0 or #upgrades_from > 0) then

			if(#upgrades_to > 0) then
				s:AddHeader("LOC_UI_PEDIA_UPGRADES_TO");
				for _, icon in ipairs(upgrades_to) do
					s:AddIconLabel(icon, icon[2]);
				end
			end

			if(#upgrades_from > 0) then
				s:AddHeader("LOC_UI_PEDIA_UPGRADE_FROM");
				for _, icon in ipairs(upgrades_from) do
					s:AddIconLabel(icon, icon[2]);
				end
			end

			s:AddSeparator();
		end

		if(obsolete_with) then
			local tType = obsolete_with[1];
			local tName = obsolete_with[2];
		
			s:AddHeader("LOC_UI_PEDIA_MADE_OBSOLETE_BY");		
			s:AddIconLabel({"ICON_" .. tType, tName, tType}, tName);
			s:AddSeparator();
		end

		if(unit.PromotionClass ~= nil) then
			local promotionClassInfo = GameInfo.UnitPromotionClasses[unit.PromotionClass];
			if (promotionClassInfo ~= nil) then
				s:AddLabel(Locale.Lookup("LOC_UNIT_PROMOTION_CLASS", promotionClassInfo.Name));
			end
		end

		if(unit.BaseMoves ~= 0) then
			if (not unit.IgnoreMoves or unit.Domain == "DOMAIN_AIR") then
				s:AddIconNumberLabel({"ICON_MOVES", nil,"MOVEMENT_1"}, unit.BaseMoves, "LOC_UI_PEDIA_MOVEMENT_POINTS");
			end
		end

		if(unit.Combat ~= 0) then
			s:AddIconNumberLabel({"ICON_STRENGTH", nil,"COMBAT_5"}, unit.Combat, "LOC_UI_PEDIA_MELEE_STRENGTH");
		end

		if(unit.RangedCombat ~= 0) then
			s:AddIconNumberLabel({"ICON_RANGED_STRENGTH", nil,"COMBAT_5"}, unit.RangedCombat, "LOC_UI_PEDIA_RANGED_STRENGTH");
		end

		if(unit.Bombard ~= 0) then
			s:AddIconNumberLabel({"ICON_BOMBARD", nil,"COMBAT_5"}, unit.Bombard, "LOC_UI_PEDIA_BOMBARD_STRENGTH");
		end

		if(unit.ReligiousStrength ~= 0) then
			s:AddIconNumberLabel({"ICON_RELIGION", nil,"FAITH_6"}, unit.ReligiousStrength, "LOC_UI_PEDIA_RELIGIOUS_STRENGTH");
		end
		
		if(unit.AntiAirCombat ~= 0) then
			s:AddIconNumberLabel({"ICON_STATS_ANTIAIR", nil,"COMBAT_5"}, unit.AntiAirCombat, "LOC_UI_PEDIA_ANTIAIR_STRENGTH");
		end

		if(unit.Range ~= 0) then
			s:AddIconNumberLabel({"ICON_RANGE", nil,"COMBAT_5"}, unit.Range, "LOC_UI_PEDIA_RANGE");
		end

		local iLifespan:number = UnitManager.GetUnitTypeBaseLifespan(unit.Index);
		if (iLifespan > 0) then
			s:AddIconNumberLabel({"ICON_LIFESPAN", nil,"HEROES"}, iLifespan, "LOC_HUD_UNIT_PANEL_LIFESPAN");
		end

		if(unit.SpreadCharges ~= 0) then
			s:AddIconNumberLabel({"ICON_RELIGION", nil,"FAITH_6"}, unit.SpreadCharges, "LOC_UI_PEDIA_SPREAD_CHARGES");
		end

		if(unit.BuildCharges ~= 0) then
			s:AddIconNumberLabel({"ICON_BUILD_CHARGES", nil,"IMPROVEMENTS"}, unit.BuildCharges, "LOC_UI_PEDIA_BUILD_CHARGES");
		end		

		if(unit.ReligiousHealCharges ~= 0) then
			s:AddIconNumberLabel({"ICON_RELIGION", nil,"FAITH_6"}, unit.ReligiousHealCharges, "LOC_UI_PEDIA_HEAL_CHARGES");
		end		

		local airSlots = unit.AirSlots or 0;
		if(airSlots ~= 0) then
			s:AddLabel(Locale.Lookup("LOC_TYPE_TRAIT_AIRSLOTS", airSlots));
		end

		if (unit.CanEarnExperience ~= nil) then
			if (unit.CanEarnExperience == false) then
				s:AddLabel(Locale.Lookup("LOC_TYPE_TRAIT_CANNOT_EARN_EXPERIENCE"));
			end
		end

		s:AddSeparator();
	end);

	AddRightColumnStatBox("LOC_UI_PEDIA_REQUIREMENTS", function(s)
		s:AddSeparator();
		if(unit.PrereqTech or unit.PrereqCivic or unit.PrereqDistrict or unit.StrategicResource or #requires_buildings > 0) then
			if(unit.PrereqDistrict ~= nil) then
				local district = GameInfo.Districts[unit.PrereqDistrict];
				if(district) then
					s:AddHeader("LOC_DISTRICT_NAME");
					s:AddIconLabel({"ICON_" .. district.DistrictType, district.Name, district.DistrictType}, district.Name);
				end
			end

			if(unit.PrereqCivic ~= nil) then
				local civic = GameInfo.Civics[unit.PrereqCivic];
				if(civic) then
					s:AddHeader("LOC_CIVIC_NAME");
					s:AddIconLabel({"ICON_" .. civic.CivicType, civic.Name, civic.CivicType}, civic.Name);
				end
			end

			if(unit.PrereqTech ~= nil) then
				local technology = GameInfo.Technologies[unit.PrereqTech];
				if(technology) then
					s:AddHeader("LOC_TECHNOLOGY_NAME");
					s:AddIconLabel({"ICON_" .. technology.TechnologyType, technology.Name, technology.TechnologyType}, technology.Name);
				end
			end

			if(unit.StrategicResource ~= nil) then
				local resource = GameInfo.Resources[unit.StrategicResource];
				if(resource) then
					s:AddHeader("LOC_RESOURCE_NAME");
					s:AddIconLabel({"ICON_" .. resource.ResourceType, resource.Name, resource.ResourceType}, resource.Name);
				end
			end

			if(#requires_buildings > 0) then
				s:AddHeader("LOC_BUILDING_NAME");		
				for i,v in ipairs(requires_buildings) do
					s:AddIconLabel(v, v[2]);
				end
			end

			s:AddSeparator();
		end
				
		if(unit.CanTrain and not unit.MustPurchase) then
			local yield = GameInfo.Yields["YIELD_PRODUCTION"];
			if(yield) then
				s:AddHeader("LOC_UI_PEDIA_PRODUCTION_COST");
				local t = Locale.Lookup("LOC_UI_PEDIA_BASE_COST", cost, yield.IconString, yield.Name);
				s:AddLabel(t);
			end
		end

		if(purchase_cost) then	
			local y = GameInfo.Yields[unit.PurchaseYield];
			if(y) then
				s:AddHeader("LOC_UI_PEDIA_PURCHASE_COST");
				local t = Locale.Lookup("LOC_UI_PEDIA_BASE_COST", purchase_cost, y.IconString, y.Name);
				s:AddLabel(t);
			end
		end
	
		if(maintenance ~= 0) then
			local yield = GameInfo.Yields["YIELD_GOLD"];
			if(yield) then
				s:AddHeader("LOC_UI_PEDIA_MAITENANCE_COST");
				local t = Locale.Lookup("LOC_UI_PEDIA_BASE_COST", maintenance, yield.IconString, yield.Name );
				s:AddLabel(t);
			end
		end
		s:AddSeparator();
	end);

	AddRightColumnStatBox("LOC_UI_PEDIA_USAGE", function(s)
		s:AddSeparator();
		if(#improvements > 0 or #routes > 0) then
			s:AddHeader("LOC_UI_PEDIA_USAGE_CAN_CONSTRUCT");

			for i,v in ipairs(improvements) do
				s:AddIconLabel({"ICON_" .. v.ImprovementType, v.Name, v.ImprovementType}, v.Name);
			end

			for i,v in ipairs(routes) do
				s:AddIconLabel({"ICON_UNITOPERATION_BUILD_ROUTE", v.Name, v.RouteType}, v.Name);
			end
		end

		s:AddSeparator();
	end);
	
	
	AddRightColumnStatBox("LOC_UI_PEDIA_ESPIONAGE_MISSIONS", function(s)
		s:AddSeparator();
		if(unit ~= nil and unit.Spy == true) then
			for row in GameInfo.UnitOperations() do
				if(row.InterfaceMode == "INTERFACEMODE_SPY_CHOOSE_MISSION") then
					s:AddIconLabel({row.Icon, row.Description, row.OperationType}, row.Description);
					if(row.Turns > 0) then
						s:AddLabel(Locale.Lookup("LOC_TYPE_TRAIT_TURNS", row.Turns));
					end
					if(row.BaseProbability > 0) then
						iThreeDieSixProb = { 0, 0, 1, 3, 6, 10, 15, 21, 25, 27, 27, 25, 21, 15, 10, 6, 3, 1 };
						local iRolls = 0;
						for iI = row.BaseProbability, 18 do
							 iRolls = iRolls + iThreeDieSixProb[iI];
						end
						
						iRolls = iRolls / 216.0 * 100.0;
					
						s:AddLabel(Locale.Lookup("LOC_TYPE_TRAIT_BASE_PROBABILITY",  math.floor(iRolls + 0.5)));
					end
					if(row.TargetDistrict ~= nil) then
						s:AddLabel(Locale.Lookup("LOC_TYPE_TRAIT_TARGET_DISTRICT",  GameInfo.Districts[row.TargetDistrict].Name));
					end
				end
			end
		end

		s:AddSeparator();
	end);

	-- Left Column!
	AddChapter("LOC_UI_PEDIA_DESCRIPTION", unit.Description);

	local chapters = GetPageChapters(page.PageLayoutId);
	for i, chapter in ipairs(chapters) do
		local chapterId = chapter.ChapterId;
		local chapter_header = GetChapterHeader(sectionId, pageId, chapterId);
		local chapter_body = GetChapterBody(sectionId, pageId, chapterId);

		AddChapter(chapter_header, chapter_body);
	end
end
