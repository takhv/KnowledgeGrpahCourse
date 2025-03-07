-- Copyright 2016-2018, Firaxis Games

-- ===========================================================================
--	NOTES:
--	Items exist in one of 7 "rows" that span horizontally and within a 
--	"column" based on the era and cost.
--
--	Rows    Start   Eras->
--	-3               _____        _____  
--	-2            /-|_____|----/-|_____| 
--	-1            |  _____     |       Nodes 
--	0        O----%-|_____|----'        
--	1       
--	2
--	3
--
-- ===========================================================================

-- Include self contained additional tabs
g_ExtraIconData = {};
include("CivicsTreeIconLoader_", true);

include( "InstanceManager" );	
include( "SupportFunctions" );
include( "Civ6Common" );			-- Tutorial check support
include( "TechAndCivicSupport" );
include( "TechFilterFunctions" );
include( "ModalScreen_PlayerYieldsHelper" );
include( "GameCapabilities" );

-- ===========================================================================
--	DEBUG
--	Toggle these for temporary debugging help.
-- ===========================================================================
debugFilterEraMaxIndex	= -1;		-- (-1 default) Only load up to a specific ERA (Value less than 1 to disable)
debugOutputCivicInfo	= false;	-- (false default) Send to console detailed information on tech?
debugShowIDWithName		= false;	-- (false default) Show the ID before the name in each node.
debugShowAllMarkers		= false;	-- (false default) Show all player markers in the timline; even if they haven't been met.
debugExplicitList		= {};		-- List of indexes to (only) explicitly show. e.g., {0,1,2,3,4} or {5,11,17}


-- ===========================================================================
--	GLOBALS
-- ===========================================================================
DATA_FIELD_GOVERNMENT   = "_GOVERNMENT"; --holds players govt and policies
DATA_FIELD_LIVEDATA		= "_LIVEDATA";	-- The current status of an item.
DATA_FIELD_PLAYERINFO	= "_PLAYERINFO";-- Holds a table with summary information on that player.
DATA_FIELD_UIOPTIONS	= "_UIOPTIONS";	-- What options the player has selected for this screen.
DATA_ICON_PREFIX		= "ICON_";
DATA_ICON_UNAVAILABLE   = "_FOW";
PIC_BOLT_OFF			= "Controls_BoltOff";
PIC_BOLT_ON				= "Controls_BoltOn";
PIC_BOOST_OFF			= "BoostTech";
PIC_BOOST_ON			= "BoostTechOn";
PIC_DEFAULT_ERA_BACKGROUND= "CivicsTree_BGAncient";
PIC_MARKER_PLAYER		= "Tree_TimePipPlayer";
PIC_MARKER_OTHER		= "Controls_TimePip";
PIC_METER_BACK			= "Tree_Meter_GearBack";
PIC_METER_BACK_DONE		= "TechTree_Meter_Done";

PREREQ_ID_TREE_START	= "_TREESTART";	-- Made up, unique value, to mark a non-node tree start
ITEM_STATUS				= {
							BLOCKED		= 1,
							READY		= 2,
							CURRENT		= 3,
							RESEARCHED	= 4,
						};
ROW_MAX					= 3;			-- Highest level row above 0
ROW_MIN					= -3;			-- Lowest level row below 0
SIZE_NODE_X				= 420;			-- Item node dimensions
SIZE_NODE_Y				= 84;
SIZE_NODE_LARGE_Y		= 140;				
STATUS_ART				= {};
STATUS_ART_LARGE		= {};
STATUS_ART[ITEM_STATUS.BLOCKED]			= { Name="BLOCKED",			TextColor0=UI.GetColorValueFromHexLiteral(0xff202726), TextColor1=UI.GetColorValueFromHexLiteral(0x00000000), FillTexture="CivicsTree_GearButtonTile_Disabled.dds",		BGU=0,BGV=(SIZE_NODE_Y*3),		HideIcon=true,  IsButton=false,	BoltOn=false,	IconBacking=PIC_METER_BACK };
STATUS_ART[ITEM_STATUS.READY]			= { Name="READY",			TextColor0=UI.GetColorValueFromHexLiteral(0xaaffffff), TextColor1=UI.GetColorValueFromHexLiteral(0x88000000), FillTexture=nil,											BGU=0,BGV=0,					HideIcon=true,  IsButton=true,	BoltOn=false,	IconBacking=PIC_METER_BACK };
STATUS_ART[ITEM_STATUS.CURRENT]			= { Name="CURRENT",			TextColor0=UI.GetColorValueFromHexLiteral(0xaaffffff), TextColor1=UI.GetColorValueFromHexLiteral(0x88000000), FillTexture=nil,											BGU=0,BGV=(SIZE_NODE_Y*4),		HideIcon=false, IsButton=false,	BoltOn=true,	IconBacking=PIC_METER_BACK };
STATUS_ART[ITEM_STATUS.RESEARCHED]		= { Name="RESEARCHED",		TextColor0=UI.GetColorValueFromHexLiteral(0xaaffffff), TextColor1=UI.GetColorValueFromHexLiteral(0x88000000), FillTexture="CivicsTree_GearButtonTile_Done.dds",			BGU=0,BGV=(SIZE_NODE_Y*5),		HideIcon=false, IsButton=false,	BoltOn=true,	IconBacking=PIC_METER_BACK_DONE  };

STATUS_ART_LARGE[ITEM_STATUS.BLOCKED]	= { Name="LARGEBLOCKED",	TextColor0=UI.GetColorValueFromHexLiteral(0xff202726), TextColor1=UI.GetColorValueFromHexLiteral(0x00000000), FillTexture="CivicsTree_GearButton2Tile_Disabled.dds",	BGU=0,BGV=(SIZE_NODE_LARGE_Y*3),HideIcon=true,  IsButton=false,	BoltOn=false,	IconBacking=PIC_METER_BACK };
STATUS_ART_LARGE[ITEM_STATUS.READY]		= { Name="LARGEREADY",		TextColor0=UI.GetColorValueFromHexLiteral(0xaaffffff), TextColor1=UI.GetColorValueFromHexLiteral(0x88000000), FillTexture=nil,											BGU=0,BGV=0,					HideIcon=true,  IsButton=true,	BoltOn=false,	IconBacking=PIC_METER_BACK };
STATUS_ART_LARGE[ITEM_STATUS.CURRENT]	= { Name="LARGECURRENT",	TextColor0=UI.GetColorValueFromHexLiteral(0xaaffffff), TextColor1=UI.GetColorValueFromHexLiteral(0x88000000), FillTexture=nil,											BGU=0,BGV=(SIZE_NODE_LARGE_Y*4),HideIcon=false, IsButton=false,	BoltOn=true,	IconBacking=PIC_METER_BACK };
STATUS_ART_LARGE[ITEM_STATUS.RESEARCHED]= { Name="LARGERESEARCHED",	TextColor0=UI.GetColorValueFromHexLiteral(0xaaffffff), TextColor1=UI.GetColorValueFromHexLiteral(0x88000000), FillTexture="CivicsTree_GearButton2Tile_Completed.dds",	BGU=0,BGV=(SIZE_NODE_LARGE_Y*5),HideIcon=false, IsButton=false,	BoltOn=true,	IconBacking=PIC_METER_BACK_DONE  };

TXT_BOOSTED				= Locale.Lookup("LOC_BOOST_BOOSTED");
TXT_TO_BOOST			= Locale.Lookup("LOC_BOOST_TO_BOOST");
MAX_BEFORE_TRUNC_TO_BOOST = 335;

-- Add to item status table. Instead of enum use hash of "UNREVEALED"; special case.
ITEM_STATUS["UNREVEALED"] = 0xB87BE593;
STATUS_ART[ITEM_STATUS.UNREVEALED]		= { Name="UNREVEALED",	TextColor0=UI.GetColorValueFromHexLiteral(0xff202726), TextColor1=UI.GetColorValueFromHexLiteral(0x00000000), FillTexture="CivicsTree_GearButtonTile_Disabled.dds",		BGU=0,BGV=(SIZE_NODE_Y*3),		HideIcon=true,  IsButton=false,	BoltOn=false,	IconBacking=PIC_METER_BACK  };
STATUS_ART_LARGE[ITEM_STATUS.UNREVEALED]= { Name="UNREVEALED",	TextColor0=UI.GetColorValueFromHexLiteral(0xff202726), TextColor1=UI.GetColorValueFromHexLiteral(0x00000000), FillTexture="CivicsTree_GearButton2Tile_Disabled.dds",	BGU=0,BGV=(SIZE_NODE_LARGE_Y*3),HideIcon=true,  IsButton=false,	BoltOn=false,	IconBacking=PIC_METER_BACK  };

g_kEras					= {};		-- type to costs
g_kItemDefaults			= {};		-- Static data about items
g_uiNodes				= {};
g_uiConnectorSets		= {};



-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

-- Spacing / Positioning Constants
local COLUMN_WIDTH					:number = 250;			-- Space of node and line(s) after it to the next node
local COLUMNS_NODES_SPAN			:number = 2;			-- How many colunms do the nodes span
local PADDING_TIMELINE_LEFT			:number = 225;
local PADDING_PAST_ERA_LEFT			:number = 30;
local PADDING_FIRST_ERA_INDICATOR	:number = -300;

-- Graphic constants
local SIZE_ART_ERA_OFFSET_X		:number = 40;			-- How far to push each era marker
local SIZE_ART_ERA_START_X		:number = 40;			-- How far to set the first era marker
local SIZE_GOVTPANEL_HEIGHT     :number = 220;
local SIZE_MARKER_PLAYER_X		:number = 42;			-- Marker of player
local SIZE_MARKER_PLAYER_Y		:number = 42;			-- "
local SIZE_MARKER_OTHER_X		:number = 34;			-- Marker of other players
local SIZE_MARKER_OTHER_Y		:number = 37;			-- "
local SIZE_OPTIONS_X			:number = 200;
local SIZE_OPTIONS_Y			:number = 150;
local SIZE_PATH					:number = 40;
local SIZE_PATH_HALF			:number = 20;
local SIZE_TIMELINE_AREA_Y		:number = 41;
local SIZE_TOP_AREA_Y			:number = 60;
local SIZE_WIDESCREEN_HEIGHT	:number = 768;

local PATH_MARKER_OFFSET_X			:number = 20;
local PATH_MARKER_OFFSET_Y			:number = 50;
local PATH_MARKER_NUMBER_0_9_OFFSET	:number = 20;
local PATH_MARKER_NUMBER_10_OFFSET	:number = 15;

local LINE_LENGTH_BEFORE_CURVE		:number = 20;			-- How long to make a line before a node before it curves
local LINE_VERTICAL_OFFSET			:number = 0;
local PADDING_NODE_STACK_Y			:number = 20;
local PARALLAX_SPEED				:number = 1.1;			-- Speed for how much slower background moves (1.0=regular speed, 0.5=half speed)
local PARALLAX_ART_SPEED			:number = 1.2;			-- Speed for how much slower background moves (1.0=regular speed, 0.5=half speed)
local TREE_START_ROW				:number = -999;			-- Which virtual "row" does tree start on? (or -999 for first node)
local TREE_START_COLUMN				:number = 0;			-- Which virtual "column" does tree start on? (Can be negative!)
local TREE_START_NONE_ID			:number = -999;			-- Special, unique value, to mark no special tree start node.
local VERTICAL_CENTER				:number = (SIZE_NODE_Y) / 2;
local MAX_BEFORE_TRUNC_GOV_TITLE	:number = 165;

local NO_PLAYER						:number = -1;			-- Value GetLocalPlayer() returns during autoplay

-- ===========================================================================
--	MEMBERS / VARIABLES
-- ===========================================================================
local m_kNodeIM				:table = InstanceManager:new( "NodeInstance", 			"Top", 		Controls.NodeScroller );
local m_kLargeNodeIM		:table = InstanceManager:new( "LargeNodeInstance", 		"Top", 		Controls.NodeScroller );
local m_kLineIM				:table = InstanceManager:new( "LineImageInstance", 		"LineImage",Controls.LineScroller );
local m_kEraArtIM			:table = InstanceManager:new( "EraArtInstance", 		"Top", 		Controls.EraArtScroller );
local m_kEraLabelIM			:table = InstanceManager:new( "EraLabelInstance", 		"Top", 		Controls.ArtScroller );
local m_kEraDotIM			:table = InstanceManager:new( "EraDotInstance",			"Dot", 		Controls.ScrollbarBackgroundArt );
local m_kMarkerIM			:table = InstanceManager:new( "PlayerMarkerInstance",	"Top",		Controls.TimelineScrollbar );
local m_kSearchResultIM		:table = InstanceManager:new( "SearchResultInstance",   "Root",     Controls.SearchResultsStack);

local m_kDiplomaticPolicyIM	:table = InstanceManager:new( "DiplomaticPolicyInstance", 	"DiplomaticPolicy", Controls.DiplomaticStack );
local m_kEconomicPolicyIM	:table = InstanceManager:new( "EconomicPolicyInstance", 	"EconomicPolicy", 	Controls.EconomicStack );
local m_kMilitaryPolicyIM	:table = InstanceManager:new( "MilitaryPolicyInstance", 	"MilitaryPolicy", 	Controls.MilitaryStack );
local m_kWildcardPolicyIM	:table = InstanceManager:new( "WildcardPolicyInstance", 	"WildcardPolicy", 	Controls.WildcardStack );
local m_kPathMarkerIM		:table = InstanceManager:new( "ResearchPathMarker",			"Top",				Controls.LineScroller);

local m_kUnlocksIM			:table = {};

local m_TopPanelConsideredHeight:number = 0;
local m_width				:number= 1024;		-- Screen Width (default / min spec)
local m_height				:number= 768;		-- Screen Height (default / min spec)
local m_scrollWidth			:number= 1024;		-- Width of the scroll bar (default to screen min_spec until set)
local m_kEraCounter			:table = {};		-- counter to determine which eras have techs
local m_maxColumns			:number= 0;			-- # of columns (highest column #)
local m_ePlayer				:number= -1;
local m_kAllPlayersTechData	:table = {};		-- All data for local players.
local m_kCurrentData		:table = {};		-- Current set of data.
local m_kFilters			:table = {};
local m_kGovernments		:table = {};
local m_kPolicyCatalogData	:table;
local m_isTreeRandomized	:boolean = false;	-- Is the tree in a randomized mode

local m_shiftDown			:boolean = false;

local m_lastPercent         :number = 0.1;
local m_FirstEraIndex		:number = -1;
local m_gameSeed			:number = GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED");
local m_kScrambledRowLookup	:table  = {-1,-3,2,0,1,-2,3};		-- To help scramble modulo rows



-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--	Accessor (for MODs) so current data doesn't need to be made global.
-- ===========================================================================
function GetLiveData()
	if m_kCurrentData then
		return m_kCurrentData[DATA_FIELD_LIVEDATA];
	end
	return nil;
end

-- ===========================================================================
--	If anyone reverse processing needs to be done with the eras tracking
--	the civic, do that here.
-- ===========================================================================
function AddCivicToEra( kEntry:table )
	if m_kEraCounter[kEntry.EraType] == nil then
		m_kEraCounter[kEntry.EraType] = 0;
	end			
	m_kEraCounter[kEntry.EraType] = m_kEraCounter[ kEntry.EraType ] + 1;
end


-- ===========================================================================
-- Return string respresenation of a prereq table
-- ===========================================================================
function GetPrereqsString( prereqs:table )
	local out:string = "";
	for _,prereq in pairs(prereqs) do
		if prereq == PREREQ_ID_TREE_START then
			out = "n/a ";
		elseif g_kItemDefaults[prereq] ~= nil then
			out = out .. g_kItemDefaults[prereq].Type .. " ";	-- Add space between civics
		else
			out = out .. "n/a ";
		end
	end
	return "[" .. string.sub(out,1,string.len(out)-1) .. "]";	-- Remove trailing space
end

-- ===========================================================================
function SetCurrentNode( hash )
	if hash ~= nil then
		local localPlayerCulture = Players[Game.GetLocalPlayer()]:GetCulture();
		-- Get the complete path to the tech
		local pathToCivic = localPlayerCulture:GetCivicPath( hash );
		local tParameters = {};
		tParameters[PlayerOperations.PARAM_CIVIC_TYPE]	= pathToCivic;
		if m_shiftDown then
			tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_APPEND;
		else
			tParameters[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE;
		end
		UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.PROGRESS_CIVIC, tParameters);
        UI.PlaySound("Confirm_Civic_CivicsTree");
	else
		UI.DataError("Attempt to change current tree item with NIL hash!");
	end

end

-- ===========================================================================
--	If the next item isn't immediate, show a path of #s traversing the tree 
--	to the desired node.
-- ===========================================================================
function RealizePathMarkers()
	
	local pCulture	:table = Players[Game.GetLocalPlayer()]:GetCulture();
	local kNodeIds	:table = pCulture:GetCivicQueue();		-- table: index, IDs
	
	m_kPathMarkerIM:ResetInstances();

	for i,nodeNumber in pairs(kNodeIds) do
		local pathPin = m_kPathMarkerIM:GetInstance();

		if(i < 10) then
			pathPin.NodeNumber:SetOffsetX(PATH_MARKER_NUMBER_0_9_OFFSET);
		else
			pathPin.NodeNumber:SetOffsetX(PATH_MARKER_NUMBER_10_OFFSET);
		end
		pathPin.NodeNumber:SetText(tostring(i));
		for j,node in pairs(g_kItemDefaults) do
			if node.Index == nodeNumber then
				local x:number = g_uiNodes[node.Type].x;
				local y:number = g_uiNodes[node.Type].y;
				pathPin.Top:SetOffsetX(x-PATH_MARKER_OFFSET_X);
				pathPin.Top:SetOffsetY(y-PATH_MARKER_OFFSET_Y);
			end
		end
	end
end

-- ===========================================================================
--	Does the era randomize layout?
-- ===========================================================================
function IsEraRandomizingLayout( eraType:string )
	local isFutureEra		:boolean = eraType=="ERA_FUTURE";
	return isFutureEra;
end

-- ===========================================================================
--	Get visual row for tech.
-- ===========================================================================
function GetRandomizedTreeRow( uirow:number )
	local range :number = (ROW_MAX - ROW_MIN);
	local index	:number = ((uirow + m_gameSeed) % range) + 1;
	uirow = m_kScrambledRowLookup[index];
	return uirow;
end

-- ===========================================================================
--	Convert a virtual column # and row # to actual pixels within the
--	scrollable tree area.
-- ===========================================================================
function ColumnRowToPixelXY( column:number, row:number)	
	local horizontal		:number = ((column-1) * COLUMNS_NODES_SPAN * COLUMN_WIDTH) + PADDING_TIMELINE_LEFT + PADDING_PAST_ERA_LEFT;
	local vertical			:number = PADDING_NODE_STACK_Y + (SIZE_WIDESCREEN_HEIGHT / 2) + (row * SIZE_NODE_Y);
	return horizontal, vertical;
end

-- ===========================================================================
--	Get the width of the scroll panel
-- ===========================================================================
function GetMaxScrollWidth()
	return m_maxColumns + (m_maxColumns * COLUMN_WIDTH) + PADDING_TIMELINE_LEFT + PADDING_PAST_ERA_LEFT;
end

-- ===========================================================================
--	Get the x offset of an era art instance
-- ===========================================================================
function GetEraArtXOffset(instArt, eraData, firstEraPadding)
	local centerx			:number = ColumnRowToPixelXY(eraData.MiddleColumn, 0) - PADDING_PAST_ERA_LEFT;
	local startPaddingAmount:number = (eraData.Index == m_FirstEraIndex and PADDING_FIRST_ERA_INDICATOR or 0);
	return (centerx + startPaddingAmount) * (1 / PARALLAX_ART_SPEED);
end


-- ===========================================================================
--	The rules to determine how nodes are placed on an invisible grid.
--	Override this if you want to use a different algorithm for node placement.
-- ===========================================================================
function LayoutNodeGrid()

	local kNodeGrid :table = {};
	local kPaths	:table = {};

	-- By era, layout all items in single "sort" row
	local eraGrids:table = {};					-- each era has it's own "grid" of items to layout
	for _,item in pairs(g_kItemDefaults) do		

		-- Create any data structures related to this era/row that don't exist:
		if eraGrids[item.EraType] == nil then
			eraGrids[item.EraType] = { rows={}, sortRow={ columns={} } };
			for i= ROW_MIN, ROW_MAX, 1 do
				eraGrids[item.EraType].rows[i] = { columns={} };
			end			
		end

		-- For first placement, ignore row and place everything in the middle (row 0)
		local pos:number = table.count(eraGrids[item.EraType].sortRow.columns) + 1;
		eraGrids[item.EraType].sortRow.columns[pos] = item.Type;

		-- determine if this is a large node
		local playerId = Game.GetLocalPlayer();
		if playerId ~= nil and playerId ~= NO_PLAYER then
			local civic:table		= GameInfo.Civics[item.Type];
			local civicType:string	= civic and civic.CivicType;
			local unlockableTypes	= GetUnlockablesForCivic_Cached(civicType, playerId);
			local numUnlocks		:number = 0;
			local extraUnlocks		:table = {};

			if unlockableTypes ~= nil then
				for _, unlockItem in ipairs(unlockableTypes) do
					local typeInfo = GameInfo.Types[unlockItem[1]];

					if typeInfo.Kind == "KIND_GOVERNMENT" then
						numUnlocks = numUnlocks + 4;				-- 4 types of policy slots
					else
						numUnlocks = numUnlocks + 1;
					end
				end
			end

			-- Include extra icons in total unlocks
			if ( item.ModifierList ) then
				for _,tModifier in ipairs(item.ModifierList) do
					local tIconData :table = g_ExtraIconData[tModifier.ModifierType];
					if ( tIconData ) then
						numUnlocks = numUnlocks + 1;
						hideDescriptionIcon = hideDescriptionIcon or tIconData.HideDescriptionIcon;
						table.insert(extraUnlocks, {IconData=tIconData, ModifierTable=tModifier});
					end
				end
			end

			if numUnlocks > 8 then
				item.IsLarge = true;
			end
		end
	end

	-- Manually sort based on prereqs, 2(N log N)
	for eraType,grid in pairs(eraGrids) do		
		local numEraItems:number = table.count(grid.sortRow.columns);
		if numEraItems > 1 then			
			for pass=1,2,1 do					-- Make 2 passes so the first swapped item is checked.
				for a=1,numEraItems do
					for b=a,numEraItems do
						if a ~= b then
							for _,prereq in ipairs(g_kItemDefaults[grid.sortRow.columns[a] ].Prereqs) do
								if prereq == grid.sortRow.columns[b] then
									grid.sortRow.columns[a], grid.sortRow.columns[b] = grid.sortRow.columns[b], grid.sortRow.columns[a];	-- swap LUA style
								end
							end					
						end
					end
				end
			end
		end
	end
	
	-- Unflatten single, traversing each era grid from left to right, pushing the item to the right if it hits a prereq
	for eraType,grid in pairs(eraGrids) do
		local maxColumns:number = table.count(grid.sortRow.columns);	-- Worst case, straight line
		while ( table.count(grid.sortRow.columns) > 0 ) do

			local typeName	:string = table.remove( grid.sortRow.columns, 1);				-- Rip off first item in sort row (next item to place)
			local item		:table	= g_kItemDefaults[typeName];
			local pos		:number = 1;

			-- No prereqs? Just put at start, otherwise push forward past them all.
			if item.Prereqs ~= nil then
				for _,prereq in ipairs(item.Prereqs) do							-- For every prereq
					local isPrereqMatched :boolean = false;					
					for x=pos,maxColumns,1 do									-- For every column (from last highest found start position)
						for y=ROW_MIN, ROW_MAX,1 do								-- For every row in the column
							if grid.rows[y].columns[x] ~= nil then				-- Is a prereq in that position of the grid?
								if prereq == grid.rows[y].columns[x] then		-- And is it a prereq for this item?
									pos = x + 1;								-- If so, this item can only exist at least 1 column further over from the prereq
									isPrereqMatched = true;
									break;
								end
							end
						end
						if isPrereqMatched then 							
							-- Ensuring this node wasn't just placed on top of another:
							while( grid.rows[item.UITreeRow].columns[pos] ~= nil ) do
								pos = pos + 1;
							end
							break;
						end
					end
				end
			end

			-- The Lua side in "by prereq" mode horizontally compacts the columns
			-- into as few as possible.  This is normally good and it makes for a
			-- nicer-looking tree, but sometimes it moves something underneath a
			-- large node when the C++ didn't want that, so we'll check for that
			-- happening and move the small node forward a column.
			if item.IsLarge and item.UITreeRow < (ROW_MAX - 1) then
				if grid.rows[item.UITreeRow + 1].columns[pos] ~= nil then
					-- move the small node forward; moving the large one can cause an incorrect graph.
					grid.rows[item.UITreeRow + 1].columns[pos + 1] = grid.rows[item.UITreeRow + 1].columns[pos];
					grid.rows[item.UITreeRow + 1].columns[pos] = nil;
					g_kItemDefaults[grid.rows[item.UITreeRow + 1].columns[pos + 1]].Column = pos + 1;
				end
			end

  		-- if the large node got placed first and we're being put underneath it, move forward
			if item.UITreeRow > ROW_MIN then
				if grid.rows[item.UITreeRow - 1].columns[pos] ~= nil then
					if g_kItemDefaults[grid.rows[item.UITreeRow - 1].columns[pos]] ~= nil and g_kItemDefaults[grid.rows[item.UITreeRow - 1].columns[pos]].IsLarge then
						pos = pos + 1;
					end
				end
			end

			-- We can accidentally compact two items into the same row, causing orphaned prereqs for
			-- later nodes.  (Tech Tree uses a smarter algorithm for this, something to keep in mind).
			-- Find the closest open spot in the current column.  GameCore is guaranteed to leave at least one open.
			local newPos:number = item.UITreeRow;
			local newDistance:number = ROW_MAX+1;
			if grid.rows[item.UITreeRow] ~= nil then
				if grid.rows[item.UITreeRow].columns[pos] ~= nil then
					for y=ROW_MIN, ROW_MAX,1 do								-- For every row in the column
						local tmpDistance:number = ROW_MAX+1;
						if grid.rows[y].columns[pos] == nil then
							if y > item.UITreeRow then
								 tmpDistance = y - item.UITreeRow;
							else
								 tmpDistance = item.UITreeRow - y;
							end
							if tmpDistance < newDistance then
								item.UITreeRow = y;
								newDistance = tmpDistance;
							end
						end
					end
				end
			end

			grid.rows[item.UITreeRow].columns[pos] = typeName;	-- Set for future lookups.
			item.Column = pos;									-- Set which column within era item exists.

			if pos > g_kEras[item.EraType].NumColumns then
				g_kEras[item.EraType].NumColumns = pos;
			end
		end	
	end

	-- Determine total # of columns prior to a given era, and max columns overall.
	local index = 0;
	local priorColumns:number = 0;
	m_maxColumns = 0;
	for row:table in GameInfo.Eras() do
		for era,eraData in pairs(g_kEras) do
			if eraData.Index == index then									-- Ensure indexed order
				eraData.PriorColumns = priorColumns;
				eraData.MiddleColumn = priorColumns + ((eraData.NumColumns + 1) / 2);
				priorColumns = priorColumns + eraData.NumColumns + 1;	-- Add one for era art between
				m_FirstEraIndex = m_FirstEraIndex < 0 and index or math.min(m_FirstEraIndex, index);
				break;
			end
		end
		index = index + 1;
	end
	m_maxColumns = priorColumns;
	
	-- Create grid used to route lines, determine maximum number of columns.
	kNodeGrid	 = {};
	for i = ROW_MIN,ROW_MAX,1 do
		kNodeGrid[i] = {};
	end
	for _,item in pairs(g_kItemDefaults) do	
		local era		:table  = g_kEras[item.EraType];
		local columnNum :number = era.PriorColumns + item.Column;

		-- Randomize UI tree row (if this game & era does that sort of thing.)
		if IsEraRandomizingLayout(item.EraType) then
			item.UITreeRow = GetRandomizedTreeRow(item.UITreeRow);
		end
	end

	return kNodeGrid, kPaths;
end

-- ===========================================================================
--	Create UI controls based on the a node grid and connecting paths.
--	
--	kNodeGrid,	A 2D table array of [row][columns]=itemType
--	kPaths,		A table describing paths.  TODO: Describe this format. ??TRON
--
--	No state specific data (e.g., selected node) should be set here in order
--	to reuse the nodes across viewing other players' trees for single seat
--	multiplayer or if a (spy) game rule allows looking at another's tree.
-- ===========================================================================
function AllocateUI( kNodeGrid:table, kPaths:table )

	g_uiNodes = {};
	m_kNodeIM:ResetInstances();
	m_kLargeNodeIM:ResetInstances();

	g_uiConnectorSets = {};
	m_kLineIM:ResetInstances();

	kNodeGrid = LayoutNodeGrid();

	-- Era divider information
	m_kEraArtIM:ResetInstances();
	m_kEraLabelIM:ResetInstances();
	m_kEraDotIM:ResetInstances();

	for era,eraData in pairs(g_kEras) do		
		
		local instArt :table = m_kEraArtIM:GetInstance();
		if eraData.BGTexture ~= nil then
			instArt.BG:SetTexture( eraData.BGTexture );
			instArt.BG:SetOffsetX( eraData.BGTextureOffsetX );
		else
			UI.DataError("Civic tree is unable to find an EraCivicBackgroundTexture entry for era '"..eraData.Description.."'; using a default.");
			instArt.BG:SetTexture(PIC_DEFAULT_ERA_BACKGROUND);
		end

		instArt.Top:SetOffsetX(GetEraArtXOffset(instArt, eraData));
		instArt.Top:SetOffsetY( (SIZE_WIDESCREEN_HEIGHT * 0.5) - (instArt.BG:GetSizeY()*0.5) );	
		instArt.Top:SetSizeVal(eraData.NumColumns*SIZE_NODE_X, 600);

		local inst:table = m_kEraLabelIM:GetInstance();
		local eraMarkerx, _	= ColumnRowToPixelXY( eraData.PriorColumns + 1, 0);
		inst.Top:SetOffsetX( (eraMarkerx - (SIZE_NODE_X*0.5)) * (1/PARALLAX_SPEED) );
		inst.EraTitle:SetText( Locale.Lookup("LOC_GAME_ERA_DESC",eraData.Description) );

		-- Dots on scrollbar
		local markerx:number = (eraData.PriorColumns / m_maxColumns) * Controls.ScrollbarBackgroundArt:GetSizeX();
		if markerx > 0 then
			local inst:table = m_kEraDotIM:GetInstance();
			inst.Dot:SetOffsetX(markerx);	
		end	
	end
	
	-- Early out if not a real player.
	local playerId :number = Game.GetLocalPlayer();
	if playerId == PlayerTypes.OBSERVER or playerId == PlayerTypes.NONE then 
		return;
	end

	-- Reset extra icon instances
	for _,iconData in pairs(g_ExtraIconData) do
		iconData:Reset();
	end

	-- Actually build UI nodes
	local isForcedSmall	:boolean = (m_isTreeRandomized==true);
	for _,item in pairs(g_kItemDefaults) do		

		local uiNode		:table	= AllocateNode( item, isForcedSmall );

		-- Get position
		-- Horizontal # = All prior nodes across all previous eras + node position in current era (based on cost vs. other nodes in that era)
		local era:table = g_kEras[item.EraType];
		local horizontal, vertical = ColumnRowToPixelXY(era.PriorColumns + item.Column, item.UITreeRow );

		-- Set position and save.
		uiNode.x	= horizontal;					
		uiNode.y	= vertical - VERTICAL_CENTER;
		uiNode.Top:SetOffsetVal( horizontal, vertical);
		g_uiNodes[item.Type] = uiNode;
	end

	if Controls.TreeStart ~= nil then
		local h,v = ColumnRowToPixelXY( TREE_START_COLUMN, TREE_START_ROW );
		Controls.TreeStart:SetOffsetVal( h,v );
	end

	-- Determine the lines between nodes.
	-- NOTE: Potentially move this to view, since lines are constantly change in look, but
	--		 it makes sense to have at least the routes computed here since they are
	--		 consistent regardless of the look.
	local spaceBetweenColumns:number = COLUMN_WIDTH - SIZE_NODE_X;
	for _,item in pairs(g_kItemDefaults) do
		local node:table = g_uiNodes[item.Type];
		local scanRow:number = item.UITreeRow;

		for _,prereqId in pairs(item.Prereqs) do
			
			local previousRow	:number = 0;
			local previousColumn:number = 0;
			if prereqId == PREREQ_ID_TREE_START then
				previousRow		= TREE_START_ROW;
				previousColumn	= TREE_START_COLUMN;
			else
				-- There had better be a preq if there is a prereq ID (unless debugging the tree).
				local prereq :table = g_kItemDefaults[prereqId];
				if (prereq ~= nil) then
					previousRow		= prereq.UITreeRow;
					scanRow			= previousRow;		-- scan the row that this dependancy is on
					previousColumn	= g_kEras[prereq.EraType].PriorColumns + prereq.Column;
				else			
					if table.count(debugExplicitList) == 0 then
						UI.DataError("Unable to find PREREQ for tech '"..item.Type.."'("..tostring(item.Index)..")");
					end
				end
			end
			
			local startColumn	:number = g_kEras[item.EraType].PriorColumns + item.Column;
			local column		:number = startColumn - 1;										-- start one back
			while kNodeGrid[scanRow][column] == nil and column > previousColumn do		-- keep working backwards until hitting a node
				column = column - 1;
			end

			if previousRow == TREE_START_NONE_ID then

				-- Nothing goes before this, not even a fake start area.

			elseif previousRow < item.UITreeRow or previousRow > item.UITreeRow  then				
				
				-- Obtain the line objects
				local inst	:table = m_kLineIM:GetInstance();
				local line1	:table = inst.LineImage; inst = m_kLineIM:GetInstance();
				local line2	:table = inst.LineImage; inst = m_kLineIM:GetInstance();
				local line3	:table = inst.LineImage; inst = m_kLineIM:GetInstance();
				local line4	:table = inst.LineImage; inst = m_kLineIM:GetInstance();
				local line5	:table = inst.LineImage;

				-- Find all the empty space before the node before to make a bend.
				local LineStartX:number = node.x;
				local LineEndX1	:number = (node.x - LINE_LENGTH_BEFORE_CURVE ) ;
				local LineEndX2, _ = ColumnRowToPixelXY( column, item.UITreeRow );
				LineEndX2 = LineEndX2 + SIZE_NODE_X;

				local LineY1	:number;
				local LineY2	:number;
				if previousRow < item.UITreeRow  then
					LineY2 = node.y-((item.UITreeRow-previousRow)*SIZE_NODE_Y)+ LINE_VERTICAL_OFFSET;-- above
					LineY1 = node.y -LINE_VERTICAL_OFFSET;
				else
					LineY2 = node.y+((previousRow-item.UITreeRow)*SIZE_NODE_Y)- LINE_VERTICAL_OFFSET;-- below
					LineY1 = node.y +LINE_VERTICAL_OFFSET;
				end
				
				line1:SetOffsetVal(LineEndX1 + SIZE_PATH_HALF, LineY1 - SIZE_PATH_HALF);				
				line1:SetSizeVal( LineStartX - LineEndX1 - SIZE_PATH_HALF, SIZE_PATH);
				
				line2:SetOffsetVal(LineEndX1 - SIZE_PATH_HALF, LineY1 - SIZE_PATH_HALF);
				line2:SetSizeVal( SIZE_PATH, SIZE_PATH);
				if previousRow < item.UITreeRow  then
					line2:SetTexture("Controls_TreePathDashSE");
				else
					line2:SetTexture("Controls_TreePathDashNE");
				end

				line3:SetOffsetVal(LineEndX1 - SIZE_PATH_HALF, math.min(LineY1 + SIZE_PATH_HALF, LineY2 + SIZE_PATH_HALF) );	
				line3:SetSizeVal( SIZE_PATH, math.abs(LineY1 - LineY2) - SIZE_PATH );
				line3:SetTexture("Controls_TreePathDashNS");
				
				line4:SetOffsetVal(LineEndX1 - SIZE_PATH_HALF, LineY2 - SIZE_PATH_HALF);
				line4:SetSizeVal( SIZE_PATH, SIZE_PATH);
				if previousRow < item.UITreeRow  then
					line4:SetTexture("Controls_TreePathDashES");
				else
					line4:SetTexture("Controls_TreePathDashEN");
				end	

				line5:SetSizeVal(  LineEndX1 - LineEndX2 - SIZE_PATH_HALF, SIZE_PATH );
				line5:SetOffsetVal(LineEndX2, LineY2 - SIZE_PATH_HALF);	

				-- Directly store the line (not instance) with a key name made up of this type and the prereq's type.
				g_uiConnectorSets[item.Type..","..prereqId] = {line1,line2,line3,line4,line5};

			else
				-- Prereq is on the same row
				local inst:table = m_kLineIM:GetInstance();
				local line:table = inst.LineImage;
				local end1, _ = ColumnRowToPixelXY( column, item.UITreeRow );
				end1 = end1 + SIZE_NODE_X;

				line:SetOffsetVal(end1, node.y - SIZE_PATH_HALF);				
				line:SetSizeVal( node.x - end1, SIZE_PATH);	

				-- Directly store the line (not instance) with a key name made up of this type and the prereq's type.
				g_uiConnectorSets[item.Type..","..prereqId] = {line};
			end				
		end
	end

	Controls.NodeScroller:CalculateSize();
	Controls.ArtScroller:CalculateSize();
	Controls.EraArtScroller:CalculateSize();

	Controls.NodeScroller:RegisterScrollCallback( OnScroll );

	-- We use a separate BG within the PeopleScroller control since it needs to scroll with the contents
	Controls.ModalBG:SetHide(true);
	Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnClose);
	Controls.ModalScreenTitle:SetText(Locale.ToUpper(Locale.Lookup("LOC_CIVICS_TREE_HEADER")));
end

-- ===========================================================================
--	Obtain three pieces of information for a given logical tree node item:
--	RETURNS:	number of unlockable items from reseraching
--				Whether or not a description should be hidden for an icon.
--				Extra unlocks table.
-- ===========================================================================
function GetCountHideDescriptionAndExtraUnlocks( item:table )
	local playerId			:number = Game.GetLocalPlayer();
	local numUnlocks		:number = 0;
	local kUnlockableTypes	:table = GetUnlockablesForCivic_Cached(item.Type, playerId);
	local extraUnlocks		:table = {};

	if kUnlockableTypes ~= nil then
		for _, unlockItem in ipairs(kUnlockableTypes) do
			local typeInfo = GameInfo.Types[unlockItem[1]];

			if typeInfo.Kind == "KIND_GOVERNMENT" then
				numUnlocks = numUnlocks + 4;				-- 4 types of policy slots
			else
				numUnlocks = numUnlocks + 1;
			end
		end
	end

	-- Include extra icons in total unlocks
	if ( item.ModifierList ) then
		for _,tModifier in ipairs(item.ModifierList) do
			local tIconData :table = g_ExtraIconData[tModifier.ModifierType];
			if ( tIconData ) then
				numUnlocks = numUnlocks + 1;
				hideDescriptionIcon = hideDescriptionIcon or tIconData.HideDescriptionIcon;
				table.insert(extraUnlocks, {IconData=tIconData, ModifierTable=tModifier});
			end
		end
	end
	return numUnlocks, hideDescriptionIcon, extraUnlocks;
end


-- ===========================================================================
--	Allocate a single node for the tree
--	item			logical data to use when allocating
--	isForcedSmall	used to force a smaller node even if there are many
--					unlocks to show (used in tree randomization to hide
--					the type of node to be researched.)
-- ===========================================================================
function AllocateNode( item:table, isForcedSmall:boolean )
	-- Create node based on # of unlocks for this civic.	
	numUnlocks, hideDescriptionIcon, extraUnlocks = GetCountHideDescriptionAndExtraUnlocks( item );		

	local uiNode:table = nil;
	if numUnlocks <= 8 or isForcedSmall then
		uiNode = m_kNodeIM:GetInstance();
		if (numUnlocks > 8) then
			item.wasForcedSmall = true;	-- Small, but shouldn't be (won't be later!)
		end
	else
		uiNode = m_kLargeNodeIM:GetInstance();
		uiNode.IsLarge = true;
	end
	
	uiNode.Top:SetTag( item.Hash );	-- Set the hash of the civic to the tag of the node (for tutorial to be able to callout)

	-- Add data fields to UI component		
	uiNode.Type	= item.Type;	-- Dynamically add "Type" field to UI node for quick look ups in item data table.

	if uiNode["unlockIM"] == nil then
		uiNode["unlockIM"] = InstanceManager:new( "UnlockInstance", "UnlockIcon", uiNode.UnlockStack );
	else
		uiNode["unlockIM"]:ResetInstances();
	end
		
	if uiNode["unlockGOV"] == nil then
		uiNode["unlockGOV"] = InstanceManager:new( "GovernmentIcon", "GovernmentInstanceGrid", uiNode.UnlockStack );
	else
		uiNode["unlockGOV"]:ResetInstances();
	end

	item.Callback = function()
		SetCurrentNode(item.Hash);
	end
			
	local playerId	:number = Game.GetLocalPlayer();
	local civic		:table = GameInfo.Civics[item.Type];
	PopulateUnlockablesForCivic( playerId, civic.Index, uiNode["unlockIM"], uiNode["unlockGOV"], item.Callback, hideDescriptionIcon);

	-- Initialize extra icons
	for _,tUnlock in pairs(extraUnlocks) do
		tUnlock.IconData:Initialize(uiNode.UnlockStack, tUnlock.ModifierTable);
	end

	uiNode.NodeButton:RegisterCallback( Mouse.eLClick, item.Callback);
	uiNode.OtherStates:RegisterCallback( Mouse.eLClick, item.Callback);

	return uiNode;
end


-- ===========================================================================
--	UI Event
--	Callback when the main scroll panel is scrolled.
-- ===========================================================================
function OnScroll( control:table, percent:number )
	
	-- Parallax 
	Controls.ArtScroller:SetScrollValue( percent );
	Controls.LineScroller:SetScrollValue( percent );
	Controls.EraArtScroller:SetScrollValue( percent );
	
	-- Audio
	if percent==0 or percent==1.0 then 
        if m_lastPercent == percent then
            return;
        end
		UI.PlaySound("UI_TechTree_ScrollTick_End"); 
	else 
		UI.PlaySound("UI_TechTree_ScrollTick"); 
	end 

    m_lastPercent = percent; 
end

-- ===========================================================================
function GetLargeNodeFromSmall( item:table, uiNode:table )
	item.wasForcedSmall = false;		
	local isForcedSmall:boolean = false;
	local uiLargeNode :table = AllocateNode( item, isForcedSmall );
	uiLargeNode.x = uiNode.x;
	uiLargeNode.y = uiNode.y;		
	uiLargeNode.Top:SetOffsetVal( uiLargeNode.x, uiLargeNode.y + VERTICAL_CENTER);	-- Add back vertical center.
	g_uiNodes[item.Type] = uiLargeNode;		
	m_kNodeIM:ReleaseInstance( uiNode );	-- Clear old instances
	
	return uiLargeNode;
end

-- ===========================================================================
--	Now its own function so Mods / Expansions can modify the nodes
-- ===========================================================================
function PopulateNode(uiNode, playerTechData)

	local item		:table = g_kItemDefaults[uiNode.Type];						-- static item data
	local live		:table = playerTechData[DATA_FIELD_LIVEDATA][uiNode.Type];	-- live (changing) data
	local status	:number = live.IsRevealed and live.Status or ITEM_STATUS.UNREVEALED;

	-- Check if a node just changed status to reveled and needs to be reallocated to a different shape.	
	if (status ~= ITEM_STATUS.UNREVEALED) and item.wasForcedSmall then		
		uiNode = GetLargeNodeFromSmall( item, uiNode );
	end

	local artInfo	:table = (uiNode.IsLarge) and STATUS_ART_LARGE[status] or STATUS_ART[status];

	if(status == ITEM_STATUS.RESEARCHED) then
		for _,prereqId in pairs(item.Prereqs) do
			if(prereqId ~= PREREQ_ID_TREE_START) then
				local prereq		:table = g_kItemDefaults[prereqId];
				if prereq ~= nil then
					local previousRow	:number = prereq.UITreeRow;
					local previousColumn:number = g_kEras[prereq.EraType].PriorColumns;

					for lineNum,line in pairs(g_uiConnectorSets[item.Type..","..prereqId]) do
						if(lineNum == 1 or lineNum == 5) then
							line:SetTexture("Controls_TreePathEW");
						end
						if( lineNum == 3) then
							line:SetTexture("Controls_TreePathNS");
						end
	
						if(lineNum==2)then
							if previousRow < item.UITreeRow  then
								line:SetTexture("Controls_TreePathSE");
							else
								line:SetTexture("Controls_TreePathNE");
							end
						end

						if(lineNum==4)then
							if previousRow < item.UITreeRow  then
								line:SetTexture("Controls_TreePathES");
							else
								line:SetTexture("Controls_TreePathEN");
							end
						end
					end
				end
			end
		end
	end

	uiNode.NodeName:SetColor( artInfo.TextColor0, 0 );
	uiNode.NodeName:SetColor( artInfo.TextColor1, 1 );

	uiNode.UnlockStack:SetHide( status==ITEM_STATUS.UNREVEALED );	-- Show/hide unlockables based on revealed status.

	local techName :string = (status==ITEM_STATUS.UNREVEALED) and Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_CIVIC") or Locale.Lookup(item.Name);
	if debugShowIDWithName then
		uiNode.NodeName:SetText( tostring(item.Index).."  ".. techName);	-- Debug output
	else
		uiNode.NodeName:SetText( Locale.ToUpper( techName ));				-- Normal output
	end

	if live.Turns > 0 then
		uiNode.Turns:SetHide( false );
		uiNode.Turns:SetColor( artInfo.TextColor0, 0 );
		uiNode.Turns:SetColor( artInfo.TextColor1, 1 );
		uiNode.Turns:SetText( Locale.Lookup("LOC_TECH_TREE_TURNS",live.Turns) );
	else
		uiNode.Turns:SetHide( true );
	end

	if item.IsBoostable and status ~= ITEM_STATUS.RESEARCHED and status ~= ITEM_STATUS.UNREVEALED then
		uiNode.BoostIcon:SetHide( false );
		uiNode.BoostText:SetHide( false );
		uiNode.BoostText:SetColor( artInfo.TextColor0, 0 );
		uiNode.BoostText:SetColor( artInfo.TextColor1, 1 );

		local boostText:string;
		if live.IsBoosted then
			boostText = TXT_BOOSTED.." "..item.BoostText;
			uiNode.BoostIcon:SetTexture( PIC_BOOST_ON );
			uiNode.BoostMeter:SetHide( false );
			uiNode.BoostedBack:SetHide( false );
		else
			boostText = TXT_TO_BOOST.." "..item.BoostText;
			uiNode.BoostedBack:SetHide( true );
			uiNode.BoostIcon:SetTexture( PIC_BOOST_OFF );
			uiNode.BoostMeter:SetHide( false );
			local boostAmount = (item.BoostAmount*.01) + (live.Progress/ live.Cost);
			uiNode.BoostMeter:SetPercent( boostAmount );
		end
		TruncateStringWithTooltip(uiNode.BoostText, MAX_BEFORE_TRUNC_TO_BOOST, boostText);
	else
		uiNode.BoostIcon:SetHide( true );
		uiNode.BoostText:SetHide( true );
		uiNode.BoostedBack:SetHide( true );
		uiNode.BoostMeter:SetHide( true );
	end

	if status == ITEM_STATUS.CURRENT then
		uiNode.GearAnim:SetHide( false );
	else
		uiNode.GearAnim:SetHide( true );
	end

	if live.Progress > 0 and status ~= ITEM_STATUS.RESEARCHED then
		uiNode.ProgressMeter:SetHide( false );
		uiNode.ProgressMeter:SetPercent(live.Progress / live.Cost);
	else
		uiNode.ProgressMeter:SetHide( true );
	end

	-- Set art for icon area
	-- Set art and tool tip for icon area
	if status == ITEM_STATUS.UNREVEALED then
		uiNode.NodeButton:SetToolTipString(Locale.Lookup("LOC_CIVICS_TREE_NOT_REVEALED_TOOLTIP"));
		uiNode.Icon:SetIcon("ICON_TECH_UNREVEALED");
		uiNode.IconBacking:SetHide(true);
		uiNode.BoostMeter:SetColor(UI.GetColorValueFromHexLiteral(0x66ffffff));
		uiNode.BoostIcon:SetColor(UI.GetColorValueFromHexLiteral(0x66000000));
	else
		uiNode.NodeButton:SetToolTipString(ToolTipHelper.GetToolTip(item.Type, Game.GetLocalPlayer()));

		if(item.Type ~= nil) then
			local iconName :string = DATA_ICON_PREFIX .. item.Type;
			if (artInfo.Name == "BLOCKED" or artInfo.Name == "LARGEBLOCKED") then
				uiNode.IconBacking:SetHide(true);
				iconName = iconName .. "_FOW";
				uiNode.BoostMeter:SetColor(UI.GetColorValueFromHexLiteral(0x66ffffff));
				uiNode.BoostIcon:SetColor(UI.GetColorValueFromHexLiteral(0x66000000));
			else
				uiNode.IconBacking:SetHide(false);
				iconName = iconName;
				uiNode.BoostMeter:SetColor(UI.GetColorValue("COLOR_WHITE"));
				uiNode.BoostIcon:SetColor(UI.GetColorValue("COLOR_WHITE"));
			end
			local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(iconName,42);
			if (textureOffsetX ~= nil) then
				uiNode.Icon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
			end
		end
	end

	if artInfo.IsButton then
		uiNode.OtherStates:SetHide( true );
		uiNode.NodeButton:SetTextureOffsetVal( artInfo.BGU, artInfo.BGV );
	else
		uiNode.OtherStates:SetHide( false );
		uiNode.OtherStates:SetTextureOffsetVal( artInfo.BGU, artInfo.BGV );
	end

	if artInfo.FillTexture ~= nil then
		uiNode.FillTexture:SetHide( false );
		uiNode.FillTexture:SetTexture( artInfo.FillTexture );
	else
		uiNode.FillTexture:SetHide( true );
	end

	if artInfo.BoltOn then
		uiNode.Bolt:SetTexture(PIC_BOLT_ON);
	else
		uiNode.Bolt:SetTexture(PIC_BOLT_OFF);
	end

	uiNode.IconBacking:SetTexture(artInfo.IconBacking);

	-- Darken items not making it past filter.
	local currentFilter:table = playerTechData[DATA_FIELD_UIOPTIONS].filter;
	if currentFilter == nil or currentFilter.Func == nil or currentFilter.Func( item.Type ) then
		uiNode.FilteredOut:SetHide( true );
	else
		uiNode.FilteredOut:SetHide( false );
	end

	-- Civilopedia: Only show if revealed civic; only wire up handlers if not in an on-rails tutorial.
	function OpenPedia()
		if live.IsRevealed then
			LuaEvents.OpenCivilopedia(uiNode.Type);
		end
	end
	if IsTutorialRunning()==false then
		uiNode.NodeButton:RegisterCallback( Mouse.eRClick, OpenPedia);
		uiNode.OtherStates:RegisterCallback( Mouse.eRClick,OpenPedia);
	end

	-- Show/Hide Recommended Icon
	if live.IsRecommended and live.AdvisorType ~= nil then
		uiNode.RecommendedIcon:SetIcon(live.AdvisorType);
		uiNode.RecommendedIcon:SetHide(false);
	else
		uiNode.RecommendedIcon:SetHide(true);
	end
end

-- ===========================================================================
--	Display the state of the tree (filter, node display, etc...) based on the 
--	active player's item data. 
--	Viewxx
-- ===========================================================================
function View( playerTechData:table )

	-- Output the node states for the tree
	for _,node in pairs(g_uiNodes) do
		PopulateNode( node, playerTechData );
	end

	-- Fill in where the markers (representing players) are at:
	m_kMarkerIM:ResetInstances();
	local PADDING		:number = 24;
	local thisPlayerID	:number = Game.GetLocalPlayer();
	local markers		:table	= m_kCurrentData[DATA_FIELD_PLAYERINFO].Markers;
	for _,markerStat in ipairs( markers ) do

		-- Only build a marker if a player has started researching...
		if markerStat.HighestColumn ~= -1 then
			local instance	:table	= m_kMarkerIM:GetInstance();

			if markerStat.IsPlayerHere then
				-- Representing the player viewing the tree			
				instance.Portrait:SetHide( true );
				instance.TurnGrid:SetHide( false );
				instance.TurnLabel:SetText( Locale.Lookup("LOC_TECH_TREE_TURN_NUM" ));
				instance.TurnNumber:SetText( tostring(Game.GetCurrentGameTurn()) );
				local turnLabelWidth = PADDING + instance.TurnLabel:GetSizeX() +  instance.TurnNumber:GetSizeX(); 
				instance.TurnGrid:SetSizeX( turnLabelWidth );
				instance.Marker:SetTexture( PIC_MARKER_PLAYER );
				instance.Marker:SetSizeVal( SIZE_MARKER_PLAYER_X, SIZE_MARKER_PLAYER_Y );
			else
				-- An other player				
				instance.TurnGrid:SetHide( true );
				instance.Marker:SetTexture( PIC_MARKER_OTHER );
				instance.Marker:SetSizeVal( SIZE_MARKER_OTHER_X, SIZE_MARKER_OTHER_Y );
			end

			-- Different content in marker based on if there is just 1 player in the column, or more than 1
			local higestEraName = "";
			if markerStat.HighestEra ~= nil and GameInfo.Eras[markerStat.HighestEra] ~= nil then
				higestEraName = GameInfo.Eras[markerStat.HighestEra].Name;
			end

			local tooltipString				:string = Locale.Lookup("LOC_TREE_ERA", Locale.Lookup(higestEraName) ).."[NEWLINE]";
			local numOfPlayersAtThisColumn	:number = table.count(markerStat.PlayerNums);
			if numOfPlayersAtThisColumn < 2 then
				instance.Num:SetHide( true );			
				local playerNum		:number = markerStat.PlayerNums[1];
				local pPlayerConfig :table = PlayerConfigurations[playerNum];
				tooltipString = tooltipString.. Locale.Lookup(pPlayerConfig:GetPlayerName());	-- TODO: Temporary using player name until leaderame is fixed

				if not markerStat.IsPlayerHere then
					local iconName:string = "ICON_"..pPlayerConfig:GetLeaderTypeName();
					instance.Portrait:SetHide( false );
					instance.Portrait:SetIcon( iconName );
				end
			else
				instance.Portrait:SetHide( true );
				instance.Num:SetHide( false );
				instance.Num:SetText(tostring(numOfPlayersAtThisColumn));
				for i,playerNum in ipairs(markerStat.PlayerNums) do
					local pPlayerConfig :table = PlayerConfigurations[playerNum];
					--[[ TODO: The human player, player 0, has whack values! No leader name coming from engine!
						local name = pPlayerConfig:GetPlayerName();
						local nick = pPlayerConfig:GetNickName();
						local leader = pPlayerConfig:GetLeaderName();
						local civ = pPlayerConfig:GetCivilizationTypeName();
						local isHuman = pPlayerConfig:IsHuman();
						print("debug info:",name,nick,leader,civ,isHuman);
					]]
					--tooltipString = tooltipString.. Locale.Lookup(pPlayerConfig:GetLeaderName()); 
					tooltipString = tooltipString.. Locale.Lookup(pPlayerConfig:GetPlayerName());	-- TODO:: Temporary using player name until leaderame is fixed
					if i < numOfPlayersAtThisColumn then
						tooltipString = tooltipString.."[NEWLINE]";
					end
				end
			end
			instance.Marker:SetToolTipString( tooltipString );
		
			local MARKER_OFFSET_START:number = 20;
			local markerPercent :number = math.clamp( markerStat.HighestColumn / m_maxColumns, 0, 1 );
			local markerX		:number = MARKER_OFFSET_START + (markerPercent * m_scrollWidth );
			instance.Top:SetOffsetVal(markerX ,0);
		end
	end
	
	RealizePathMarkers();
	RealizeFilterPulldown();
	RealizeKeyPanel();
	RealizeGovernmentPanel();
end

--
--
--
function GetPlayerGovernment(ePlayer:number)
	local kPlayer		:table	= Players[ePlayer];
	local playerCulture	:table	= kPlayer:GetCulture();
	local kCurrentGovernment:table;
	local kGovernmentInfo:table = {};

	local governmentId :number = playerCulture:GetCurrentGovernment();
	if governmentId ~= -1 then
		kCurrentGovernment = GameInfo.Governments[governmentId];
		kGovernmentInfo["NAMES"] = Locale.Lookup(kCurrentGovernment.Name);	
	end

	kGovernmentInfo["DIPLOMATIC"] = 0;
	kGovernmentInfo["ECONOMIC"] = 0;
	kGovernmentInfo["WILDCARD"] = 0;
	kGovernmentInfo["MILITARY"] = 0;
	kGovernmentInfo["DIPLOMATICPOLICIES"] = {};
	kGovernmentInfo["ECONOMICPOLICIES"] = {};
	kGovernmentInfo["MILITARYPOLICIES"] = {};
	kGovernmentInfo["WILDCARDPOLICIES"] = {};

	local numSlots:number = playerCulture:GetNumPolicySlots();
	for i = 0, numSlots-1, 1 do
		local	iSlotType	:number = playerCulture:GetSlotType(i);
		local	iSlotPolicy	:number= playerCulture:GetSlotPolicy(i);
		local	rowSlotType	:string = GameInfo.GovernmentSlots[iSlotType].GovernmentSlotType;				
				
		if	rowSlotType == "SLOT_DIPLOMATIC" then	
			kGovernmentInfo["DIPLOMATIC"] = kGovernmentInfo["DIPLOMATIC"]+1;
			table.insert(kGovernmentInfo["DIPLOMATICPOLICIES"], iSlotPolicy);
		elseif	rowSlotType == "SLOT_ECONOMIC"	then	
			kGovernmentInfo["ECONOMIC"] = kGovernmentInfo["ECONOMIC"]+1;
			table.insert(kGovernmentInfo["ECONOMICPOLICIES"], iSlotPolicy);
		elseif	rowSlotType == "SLOT_MILITARY"	then	
			kGovernmentInfo["MILITARY"] = kGovernmentInfo["MILITARY"]+1;
			table.insert(kGovernmentInfo["MILITARYPOLICIES"], iSlotPolicy);
		elseif	rowSlotType == "SLOT_WILDCARD"	then	
			kGovernmentInfo["WILDCARD"] = kGovernmentInfo["WILDCARD"]+1;
			table.insert(kGovernmentInfo["WILDCARDPOLICIES"], iSlotPolicy);
		else
			UI.DataError("On initialization; unhandled slot type for a policy '"..rowSlotType.."'");
		end		
	end

	return kGovernmentInfo;
end

-- ===========================================================================
--	Load all the 'live' data for a player.
-- ===========================================================================
function GetCurrentData( ePlayer:number )
	
	-- If first time, initialize player data tables.
	local data	:table = m_kAllPlayersTechData[ePlayer];	
	if data == nil then
		-- Initialize player's top level tables:
		data = {};
		data[DATA_FIELD_LIVEDATA]			= {};
		data[DATA_FIELD_PLAYERINFO]			= {};
		data[DATA_FIELD_UIOPTIONS]			= {};
		data[DATA_FIELD_GOVERNMENT]			= {};
		
		-- Initialize data, and sub tables within the top tables.
		data[DATA_FIELD_PLAYERINFO].Player	= ePlayer;	-- Number of this player
		data[DATA_FIELD_PLAYERINFO].Markers	= {};		-- Hold a condenced, UI-ready version of stats
		data[DATA_FIELD_PLAYERINFO].Stats	= {};		-- Hold stats on where each player is (based on what this player can see)
	end	

	local kPlayer		:table	= Players[ePlayer];
	local playerCulture	:table	= kPlayer:GetCulture();
	local currentCivicID:number = playerCulture:GetProgressingCivic();

	-- DEBUG: Output header to console.
	if debugOutputCivicInfo then
		print("                          Item Id  Status      Progress   $ Era              Prereqs");
		print("------------------------------ --- ---------- --------- --- ---------------- --------------------------");
	end

	-- Get recommendations
	local civicRecommendations:table = {};
	local kGrandAI:table = kPlayer:GetGrandStrategicAI();
	if kGrandAI then
		for i,recommendation in pairs(kGrandAI:GetCivicsRecommendations()) do
			civicRecommendations[recommendation.CivicHash] = recommendation.CivicScore;
		end
	end

	-- Loop through all items and place in appropriate buckets as well
	-- read in the associated information for it.
	for type,item in pairs(g_kItemDefaults) do
		local civicID	:number = GameInfo.Civics[item.Type].Index;
		local status	:number = ITEM_STATUS.BLOCKED;
		local turnsLeft	:number = 0;
		if playerCulture:HasCivic(civicID) then
			status = ITEM_STATUS.RESEARCHED;
		elseif civicID == currentCivicID then
			status = ITEM_STATUS.CURRENT;
			turnsLeft = playerCulture:GetTurnsLeft();
		elseif playerCulture:CanProgress(civicID) then
			status = ITEM_STATUS.READY;
			turnsLeft = playerCulture:GetTurnsToProgressCivic(civicID);
		else
			turnsLeft = playerCulture:GetTurnsToProgressCivic(civicID);
		end

		data[DATA_FIELD_LIVEDATA][type] = {
			Cost		= playerCulture:GetCultureCost(civicID),
			IsBoosted	= playerCulture:HasBoostBeenTriggered(civicID),
			Progress	= playerCulture:GetCulturalProgress(civicID),
			Status		= status,
			Turns		= turnsLeft
		}

		-- Determine if tech is recommended
		if civicRecommendations[item.Hash] then
			data[DATA_FIELD_LIVEDATA][type].AdvisorType = GameInfo.Civics[item.Type].AdvisorType;
			data[DATA_FIELD_LIVEDATA][type].IsRecommended = true;
		else
			data[DATA_FIELD_LIVEDATA][type].IsRecommended = false;
		end

		-- DEBUG: Output to console detailed information about the tech.
		if debugOutputCivicInfo then
			local this:table = data[DATA_FIELD_LIVEDATA][type];
			print( string.format("%30s %-3d %-10s %4d/%-4d %3d %-16s %s",
				type,item.Index,
				STATUS_ART[status].Name,
				this.Progress,
				this.Cost,
				this.Turns,
				item.EraType,
				GetPrereqsString(item.Prereqs)
			));
		end
	end

	local players = Game.GetPlayers{Major = true};

	-- Determine where all players are.
	local playerVisibility = PlayersVisibility[ePlayer];
	if playerVisibility ~= nil then
		for i, otherPlayer in ipairs(players) do
			local playerID		:number = otherPlayer:GetID();
			local playerCulture	:table	= players[i]:GetCulture();
			local currentCivic	:number = playerCulture:GetProgressingCivic();

			data[DATA_FIELD_PLAYERINFO].Stats[playerID] = {
				CurrentID		= currentCivic,	
				HasMet			= kPlayer:GetDiplomacy():HasMet(playerID) or playerID==ePlayer or debugShowAllMarkers;
				HighestColumn	= -1,				-- where they are in the timeline
				HighestEra		= ""
			};

			-- The latest tech a player may be researching may not be the one
			-- furthest along in time; so go through ALL the techs and track
			-- the highest column of all researched tech.
			local highestColumn :number = -1;
			local highestEra	:string = "";
			for _,item in pairs(g_kItemDefaults) do
				local civicID:number = GameInfo.Civics[item.Type].Index;
				if playerCulture:HasCivic(civicID) then
					local column:number = item.Column + g_kEras[item.EraType].PriorColumns;
					if column > highestColumn then
						highestColumn	= column;
						highestEra		= item.EraType;
					end
				end
			end
			data[DATA_FIELD_PLAYERINFO].Stats[playerID].HighestColumn	= highestColumn;
			data[DATA_FIELD_PLAYERINFO].Stats[playerID].HighestEra		= highestEra;
		end
	end


	-- All player data is added.. build markers data based on player data.
	local checkedID:table = {};
	data[DATA_FIELD_PLAYERINFO].Markers	= {};
	for playerID:number, targetPlayer:table in pairs(data[DATA_FIELD_PLAYERINFO].Stats) do
		-- Only look for IDs that haven't already been merged into a marker.
		if checkedID[playerID] == nil and targetPlayer.HasMet then
			checkedID[playerID] = true;
			local markerData:table = {};
			if data[DATA_FIELD_PLAYERINFO].Markers[playerID] ~= nil then
				markerData = data[DATA_FIELD_PLAYERINFO].Markers[playerID];
				markerData.HighestColumn = targetPlayer.HighestColumn;
				markerData.HighestEra    = targetPlayer.HighestEra;
				markerData.IsPlayerHere  = (playerID == ePlayer);
			else
				markerData = {
							HighestColumn	= targetPlayer.HighestColumn,	-- Which column this marker should be placed
							HighestEra		= targetPlayer.HighestEra,
							IsPlayerHere	= (playerID == ePlayer),				
							PlayerNums		= {playerID}}									-- All players who share this marker spot
				table.insert( data[DATA_FIELD_PLAYERINFO].Markers, markerData );				
			end
			-- SPECIAL CASE: Current player starts at column 0 so it's immediately visible on timeline:
			if playerID == ePlayer and markerData.HighestColumn == -1 then
				markerData.HighestColumn = 0;		
				local firstEra:table = nil;
				for _,era in pairs(g_kEras) do
					if firstEra == nil or era.Index < firstEra.Index then
						firstEra = era;
					end
				end						
				if firstEra ~= nil then
					markerData.HighestEra = firstEra.Index;
				end
			end

			-- Traverse all the IDs and merge them with this one.
			for anotherID:number, anotherPlayer:table in pairs(data[DATA_FIELD_PLAYERINFO].Stats) do				
				-- Don't add if: it's outself, if hasn't researched at least 1 tech, if we haven't met
				if playerID ~= anotherID and anotherPlayer.HighestColumn > -1 and anotherPlayer.HasMet then		
					if markerData.HighestColumn == data[DATA_FIELD_PLAYERINFO].Stats[anotherID].HighestColumn then
						checkedID[anotherID] = true;
						-- Need to do this check if player's ID didn't show up first in the list in creating the marker.						
						if anotherID == ePlayer then
							markerData.IsPlayerHere	= true;
						end
						local foundAnotherID:boolean = false;

						for _, playernumsID in pairs(markerData.PlayerNums) do
							if not foundAnotherID and playernumsID == anotherID then
								foundAnotherID = true;
							end
						end

						if not foundAnotherID then
							table.insert( markerData.PlayerNums, anotherID );
						end
					end
				end
			end
		end
	end

	data[DATA_FIELD_GOVERNMENT]	= GetPlayerGovernment(ePlayer);
	
	-- Loop through all items and add an IsRevealed field.
	local pPlayerCultureManager:table = Players[ePlayer]:GetCulture();
	if (pPlayerCultureManager ~= nil) then
		for type,item in pairs(g_kItemDefaults) do
			if pPlayerCultureManager.IsCivicRevealed ~= nil then
				data[DATA_FIELD_LIVEDATA][type]["IsRevealed"] = pPlayerCultureManager:IsCivicRevealed(item.Index);
			else
				data[DATA_FIELD_LIVEDATA][type]["IsRevealed"] = true;
			end
		end
	end

	return data;
end

-- ===========================================================================
function RefreshDataIfNeeded( ePlayer:number )
	if ContextPtr:IsHidden() then return; end													-- Screen hidden
	if (m_ePlayer == PlayerTypes.NONE or m_ePlayer == PlayerTypes.OBSERVER) then return; end	-- Autoplay support.
	if m_ePlayer ~= ePlayer then return; end													-- Some other player
			
	m_kCurrentData = GetCurrentData( m_ePlayer, -1 );
	View( m_kCurrentData );
end

-- ===========================================================================
function OnUpdateDueToCity(ePlayer:number, cityID:number, plotX:number, plotY:number)
	RefreshDataIfNeeded(ePlayer);	
end

-- ===========================================================================
function UpdateLocalPlayer()
	RefreshDataIfNeeded( m_ePlayer );
end

-- ===========================================================================
function OnGovernmentChanged()
	UpdateLocalPlayer()
end

-- ===========================================================================
function OnGovernmentPolicyChanged()
	UpdateLocalPlayer()
end

-- ===========================================================================
function OnLocalPlayerTurnBegin()
	UpdateLocalPlayer()
end

-- ===========================================================================
--	EVENT
--	Player turn is ending
-- ===========================================================================
function OnLocalPlayerTurnEnd()
	-- If current data set is for the player, save back any changes into
	-- the table of player tables.
	local ePlayer :number = Game.GetLocalPlayer();
	if ePlayer ~= -1 then
		if m_kCurrentData[DATA_FIELD_PLAYERINFO].Player == ePlayer then
			m_kAllPlayersTechData[ePlayer] = m_kCurrentData;
		end
	end

	if(GameConfiguration.IsHotseat()) then
		Close();
	end
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnLocalPlayerChanged()
	local localPlayer:number =  Game.GetLocalPlayer();
	if  localPlayer ~= PlayerTypes.NONE then
		m_ePlayer = localPlayer;
		Controls.NodeScroller:SetScrollValue( 0 );
	end
end

-- ===========================================================================
function OnCivicChanged( ePlayer:number, eCivic:number )
	RefreshDataIfNeeded( ePlayer );	
end

-- ===========================================================================
function OnCivicComplete( ePlayer:number, eCivic:number)
	RefreshDataIfNeeded( ePlayer );
end

-- ===========================================================================
--	Initially size static UI elements 
--	(or re-size if screen resolution changed)
-- ===========================================================================
function Resize()
	m_width, m_height	= UIManager:GetScreenSizeVal();		-- Cache screen dimensions
	m_scrollWidth		= m_width - 80;						-- Scrollbar area (where markers are placed) slightly smaller than screen width

	-- Determine how far art will span.
	-- First obtain the size of the tree by taking the visible size and multiplying it by the ratio of the full content
	local scrollPanelX:number = (Controls.NodeScroller:GetSizeX() / Controls.NodeScroller:GetRatio());

	local artAndEraScrollWidth:number = math.max( scrollPanelX * (1/PARALLAX_SPEED), m_width ) 
		+ SIZE_ART_ERA_OFFSET_X 
		+ SIZE_ART_ERA_START_X;

	Controls.ArtParchmentDecoTop:SetSizeX( artAndEraScrollWidth );
	Controls.ArtParchmentDecoBottom:SetSizeX( artAndEraScrollWidth );
	Controls.ArtParchmentRippleTop:SetSizeX( artAndEraScrollWidth );
	Controls.ArtParchmentRippleBottom:SetSizeX( artAndEraScrollWidth );
	Controls.ForceSizeX:SetSizeX( artAndEraScrollWidth  );	
	Controls.ForceArtSizeX:SetSizeX( scrollPanelX * (1/PARALLAX_ART_SPEED) );
	Controls.LineForceSizeX:SetSizeX( scrollPanelX );
	Controls.LineScroller:CalculateSize();
	Controls.ArtScroller:CalculateSize();
	
	local backArtScrollWidth:number = scrollPanelX * (1/PARALLAX_ART_SPEED) + 100;
	Controls.Background:SetSizeX( math.max(backArtScrollWidth, m_width) );
	Controls.Background:SetSizeY( SIZE_WIDESCREEN_HEIGHT - (SIZE_TIMELINE_AREA_Y - 8) );	
	Controls.EraArtScroller:CalculateSize();

	local keyHeight:number = SIZE_WIDESCREEN_HEIGHT - (SIZE_OPTIONS_Y + SIZE_TIMELINE_AREA_Y + SIZE_TOP_AREA_Y);
	if not Controls.GovernmentPanel:IsHidden() then 
		keyHeight = keyHeight - SIZE_GOVTPANEL_HEIGHT;
	end
	Controls.KeyPanel:SetSizeY(keyHeight);
	Controls.KeyScroll:SetSizeY(keyHeight-20);
	if(Controls.KeyPanel:IsHidden()) then
		Controls.GovernmentPanel:SetOffsetY(-87);
	else
		Controls.GovernmentPanel:SetOffsetY(keyHeight - 90);
	end
	Controls.KeyScroll:CalculateSize();
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if type == SystemUpdateUI.ScreenResize then
		Resize();
	end
end

-- ===========================================================================
--	Obtain the data from the DB that doesn't change
--	Base costs and relationships (prerequisites)
--	RETURN: A table of node data (techs/civics/etc...) with a prereq for each entry.
-- ===========================================================================
function PopulateItemData() -- Note that we are overriding this function without calling its base version. This version requires no parameters.

	local kItemDefaults :table = {};		-- Table to return

	function GetHash(t)
		local r = GameInfo.Types[t];
		if(r) then
			return r.Hash;
		else
			return 0;
		end
	end

	local tCivicModCache:table = TechAndCivicSupport_BuildCivicModifierCache();

	local civicNodes:table = UITree.GetAvailableCivics();
	for _,civicNode in ipairs(civicNodes) do

		local row:table		= GameInfo.Civics[civicNode.CivicType];

		local kEntry:table	= {};
		kEntry.Type			= row.CivicType;
		kEntry.Name			= row.Name;
		kEntry.BoostText	= "";
		kEntry.Column		= -1;
		kEntry.Cost			= civicNode.Cost;
		kEntry.Description	= row.Description and Locale.Lookup( row.Description );
		kEntry.EraType		= row.EraType;
		kEntry.Hash			= GetHash(kEntry.Type);
		kEntry.Index		= civicNode.CivicType;
		kEntry.IsBoostable	= false;
		kEntry.IsRevealed	= false;
		kEntry.Prereqs		= {};				-- IDs for prerequisite item(s)
		kEntry.UITreeRow	= civicNode.TreeRow;
		kEntry.Unlocks		= {};				-- Each unlock has: unlockType, iconUnavail, iconAvail, tooltip

		-- Only add if not debugging or in debug range.
		if	(table.count(debugExplicitList) == 0 and debugFilterEraMaxIndex ==-1 ) or
			(table.count(debugExplicitList) == 0 and kEntry.Index < debugFilterEraMaxIndex) or
			(table.count(debugExplicitList) ~= 0 and debugExplicitList[kEntry.Index] ~= nil)  then

			kEntry.ModifierList = tCivicModCache[kEntry.Type];

			-- Boost?
			for boostRow in GameInfo.Boosts() do
				if boostRow.CivicType == kEntry.Type then
					kEntry.BoostText = Locale.Lookup( boostRow.TriggerDescription );
					kEntry.IsBoostable = true;
					kEntry.BoostAmount = boostRow.Boost;
					break;
				end
			end

			if (table.count(civicNode.PrereqCivicTypes) > 0) then
				for __,prereqCivicType in ipairs(civicNode.PrereqCivicTypes) do
					local prereqRow:table = GameInfo.Civics[prereqCivicType];
					if prereqRow ~= nil then
						table.insert( kEntry.Prereqs, prereqRow.CivicType );
					end
				end
			end
			-- If no prereqs were found, set item to special tree start value
			if table.count(kEntry.Prereqs) == 0 then
				table.insert(kEntry.Prereqs, PREREQ_ID_TREE_START);
			end

			-- Warn if DB has an out of bounds entry.
			if kEntry.UITreeRow < ROW_MIN or kEntry.UITreeRow > ROW_MAX then
				UI.DataError("UITreeRow for '"..kEntry.Type.."' has an out of bound UITreeRow="..tostring(kEntry.UITreeRow).."  MIN="..tostring(ROW_MIN).."  MAX="..tostring(ROW_MAX));
			end

			AddCivicToEra( kEntry );

			-- Save entry into master list.
			kItemDefaults[kEntry.Type] = kEntry;
		end
	end

	return kItemDefaults;
end


-- ===========================================================================
--	Create a hash table of EraType to its chronological index.
-- ===========================================================================
function PopulateEraData()
	g_kEras = {};
	for row:table in GameInfo.Eras() do
		if m_kEraCounter[row.EraType] and m_kEraCounter[row.EraType] > 0 and debugFilterEraMaxIndex < 1 or row.ChronologyIndex <= debugFilterEraMaxIndex then			
			table.insert(g_kEras, { 
				EraType				= row.EraType,
				BGTexture			= row.EraCivicBackgroundTexture,
				BGTextureOffsetX	= row.EraCivicBackgroundTextureOffsetX,
				Description			= Locale.Lookup(row.Name),
				NumColumns			= 0,				
				ChronologyIndex		= row.ChronologyIndex,
				Index				= -1,
				PriorColumns		= -1
			});
		end
	end	

	-- Correctly assign the index to be the index of the era sorted by chronology index.
	-- Also index
	table.sort(g_kEras, function(a,b) return a.ChronologyIndex < b.ChronologyIndex; end);
	for i,v in ipairs(g_kEras) do
		v.Index = i - 1;
		g_kEras[v.EraType] = v;		
	end
end


-- ===========================================================================
--
-- ===========================================================================
function PopulateFilterData()

	-- Filters.
	m_kFilters = {};
	table.insert( m_kFilters, { Func=nil,										Description="LOC_TECH_FILTER_NONE",			Icon=nil } );
	
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_FOOD"],			Description="LOC_TECH_FILTER_FOOD",			Icon="[ICON_FOOD]" });
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_SCIENCE"],		Description="LOC_TECH_FILTER_SCIENCE",		Icon="[ICON_SCIENCE]" });
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_PRODUCTION"],	Description="LOC_TECH_FILTER_PRODUCTION",	Icon="[ICON_PRODUCTION]" });
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_CULTURE"],		Description="LOC_TECH_FILTER_CULTURE",		Icon="[ICON_CULTURE]" });
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_GOLD"],			Description="LOC_TECH_FILTER_GOLD",			Icon="[ICON_GOLD]" });	
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_UNITS"],			Description="LOC_TECH_FILTER_UNITS",		Icon="[ICON_UNITS]" });
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_IMPROVEMENTS"],	Description="LOC_TECH_FILTER_IMPROVEMENTS",	Icon="[ICON_IMPROVEMENTS]" });
	table.insert( m_kFilters, { Func=g_TechFilters["TECHFILTER_WONDERS"],		Description="LOC_TECH_FILTER_WONDERS",		Icon="[ICON_WONDERS]" });
	
	for i,filter in ipairs(m_kFilters) do		
		local filterLabel	 = Locale.Lookup( filter.Description );
		local filterIconText = filter.Icon;
		local controlTable	 = {};       
		Controls.FilterPulldown:BuildEntry( "FilterItemInstance", controlTable );
		-- If a text icon exists, use it and bump the label in the button over.
		--[[ TODO: Uncomment if icons are added.
		if filterIconText ~= nil and filterIconText ~= "" then
			controlTable.IconText:SetText( Locale.Lookup(filterIconText) );
			controlTable.DescriptionText:SetOffsetX(24);
		else
			controlTable.IconText:SetText( "" );
			controlTable.DescriptionText:SetOffsetX(4);
		end
		]]
		controlTable.DescriptionText:SetOffsetX(8);
		controlTable.DescriptionText:SetText( filterLabel );

		-- Callback
		controlTable.Button:RegisterCallback( Mouse.eLClick,  function() OnFilterClicked(filter); end );
	end
	Controls.FilterPulldown:CalculateInternals();
end

-- ===========================================================================
-- Populate Full Text Search
-- ===========================================================================
function PopulateSearchData()
	local searchContext = "Civics";
	if(Search.CreateContext(searchContext, "[COLOR_LIGHTBLUE]", "[ENDCOLOR]", "...")) then
			
		-- Hash modifier types that grant envoys or spies.
		local envoyModifierTypes = {};
		local spyModifierTypes = {};

		for row in GameInfo.DynamicModifiers() do
			local effect = row.EffectType;
			if(effect == "EFFECT_GRANT_INFLUENCE_TOKEN") then
				envoyModifierTypes[row.ModifierType] = true;
			elseif(effect == "EFFECT_GRANT_SPY") then
				spyModifierTypes[row.ModifierType] = true;
			end
		end

		-- Hash civic types that grant envoys or spies via modifiers.
		local envoyCivics = {};
		local spyCivics = {};
		for row in GameInfo.CivicModifiers() do			
			local modifier = GameInfo.Modifiers[row.ModifierId];
			if(modifier) then
				local modifierType = modifier.ModifierType;
				if(envoyModifierTypes[modifierType]) then
					envoyCivics[row.CivicType] = true;
				end

				if(spyModifierTypes[modifierType]) then
					spyCivics[row.CivicType] = true;
				end
			end
		end

		local envoyTypeName = Locale.Lookup("LOC_ENVOY_NAME");
		local spyTypeName = Locale.Lookup("LOC_SPY_NAME");

		for row in GameInfo.Civics() do
			local civicType = row.CivicType;
			local description = row.Description and Locale.Lookup(row.Description) or "";
			local tags = {};
			if(envoyCivics[civicType]) then
				table.insert(tags, envoyTypeName);
			end

			if(spyCivics[civicType]) then
				table.insert(tags, spyTypeName);
			end

			Search.AddData(searchContext, civicType, Locale.Lookup(row.Name), description, tags);
		end

		local buildingTypeName = Locale.Lookup("LOC_BUILDING_NAME");
		local wonderTypeName = Locale.Lookup("LOC_WONDER_NAME");
		for row in GameInfo.Buildings() do
			if(row.PrereqCivic) then
				local tags = {buildingTypeName};
				if(row.IsWonder) then
					table.insert(tags, wonderTypeName);
				end

				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), tags);
			end
		end

		local districtTypeName = Locale.Lookup("LOC_DISTRICT_NAME");
		for row in GameInfo.Districts() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { districtTypeName });
			end
		end

		local governmentTypeName = Locale.Lookup("LOC_GOVERNMENT_NAME");
		for row in GameInfo.Governments() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { governmentTypeName });
			end
		end
		
		local improvementTypeName = Locale.Lookup("LOC_IMPROVEMENT_NAME");
		for row in GameInfo.Improvements() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { improvementTypeName });
			end
		end

		local policyTypeName = Locale.Lookup("LOC_POLICY_NAME");
		for row in GameInfo.Policies() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { policyTypeName });
			end
		end
		
		local projectTypeName = Locale.Lookup("LOC_PROJECT_NAME");
		for row in GameInfo.Projects() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { projectTypeName });
			end
		end

		local resourceTypeName = Locale.Lookup("LOC_RESOURCE_NAME");
		for row in GameInfo.Resources() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { resourceTypeName });
			end
		end

		local unitTypeName = Locale.Lookup("LOC_UNIT_NAME");
		for row in GameInfo.Units() do
			if(row.PrereqCivic) then
				Search.AddData(searchContext, row.PrereqCivic, Locale.Lookup(GameInfo.Civics[row.PrereqCivic].Name), Locale.Lookup(row.Name), { unitTypeName });
			end
		end

		Search.Optimize(searchContext);
	end
end

-- ===========================================================================
-- Update the Filter text with the current label.
-- ===========================================================================
function RealizeFilterPulldown()
	local pullDownButton = Controls.FilterPulldown:GetButton();	
	if m_kCurrentData[DATA_FIELD_UIOPTIONS].filter == nil or m_kCurrentData[DATA_FIELD_UIOPTIONS].filter.Func== nil then
		pullDownButton:SetText( "  "..Locale.Lookup("LOC_TREE_FILTER_W_DOTS"));
	else
		local description:string = m_kCurrentData[DATA_FIELD_UIOPTIONS].filter.Description;
		pullDownButton:SetText( "  "..Locale.Lookup( description ));
	end
end

-- ===========================================================================
--	filterLabel,	Readable lable of the current filter.
--	filterFunc,		The funciton filter to apply to each node as it's built,
--					nil will reset the filters to none.
-- ===========================================================================
function OnFilterClicked( filter )		  
	m_kCurrentData[DATA_FIELD_UIOPTIONS].filter = filter;
	View( m_kCurrentData )
end

-- ===========================================================================
function OnOpen()
	if (Game.GetLocalPlayer() == PlayerTypes.NONE) then
		return;
	end

	UI.PlaySound("UI_Screen_Open");

	m_kCurrentData = GetCurrentData( m_ePlayer );
	View( m_kCurrentData );
	ContextPtr:SetHide(false);

	-- From ModalScreen_PlayerYieldsHelper
	if not RefreshYields() then
		Controls.Vignette:SetSizeY(m_TopPanelConsideredHeight);
	end

	-- From Civ6_styles: FullScreenVignetteConsumer
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();
	
	LuaEvents.CivicsTree_OpenCivicsTree();
end

-- ===========================================================================
--	Show the Key panel based on the state
-- ===========================================================================
function RealizeKeyPanel()
	if UserConfiguration.GetShowCivicsTreeKey() then
		Controls.KeyPanel:SetHide( false );	
		UI.PlaySound("UI_TechTree_Filter_Open");	        
	else
		if Controls.KeyPanel:IsHidden() then
			UI.PlaySound("UI_TechTree_Filter_Closed");
		end
		Controls.KeyPanel:SetHide( true );
	end

	if Controls.KeyPanel:IsHidden() then
		Controls.ToggleKeyButton:SetText(Locale.Lookup("LOC_TREE_SHOW_KEY"));
		Controls.ToggleKeyButton:SetSelected(false);
	else
		Controls.ToggleKeyButton:SetText(Locale.Lookup("LOC_TREE_HIDE_KEY"));
		Controls.ToggleKeyButton:SetSelected(true);	
	end	
end

-- ===========================================================================
function OnClickCurrentPolicy(clickedPolicy:number)
	local percent:number = 0;
	local prereqCivic:string = GameInfo.Policies[clickedPolicy].PrereqCivic;

	percent = (g_uiNodes[prereqCivic].x)/((m_maxColumns * COLUMN_WIDTH)*2);
	--offset the scroll percent depending on the scroll value to better center the policy on the screen
	if percent < .25 then
		percent = percent - .025
	elseif percent >= .25 and percent < .5 then
		percent = percent;
	elseif percent >= .5 and percent < .75 then
		percent = percent + .025;
	elseif percent >= .75 then 
		percent = percent + .05;
	end

	Controls.NodeScroller:SetScrollValue(percent);

end

-- ===========================================================================
--	Show the Key panel based on the state
-- ===========================================================================
function RealizeGovernmentPanel()
	m_kDiplomaticPolicyIM:DestroyInstances();
	m_kEconomicPolicyIM:DestroyInstances();
	m_kMilitaryPolicyIM:DestroyInstances();
	m_kWildcardPolicyIM:DestroyInstances();

	if UserConfiguration.GetShowCivicsTreeGovernment() then
		Controls.GovernmentPanel:SetHide( false );	
		UI.PlaySound("UI_TechTree_Filter_Open");		
	else
		if Controls.GovernmentPanel:IsHidden() then
			UI.PlaySound("UI_TechTree_Filter_Closed");
		end
		Controls.GovernmentPanel:SetHide( true );
	end

	if Controls.GovernmentPanel:IsHidden() then
		Controls.ToggleGovernmentButton:SetText(Locale.Lookup("LOC_TREE_SHOW_GOVERNMENT"));
		Controls.ToggleGovernmentButton:SetSelected(false);
	else
		Controls.ToggleGovernmentButton:SetText(Locale.Lookup("LOC_TREE_HIDE_GOVERNMENT"));
		Controls.ToggleGovernmentButton:SetSelected(true);
	end	

	TruncateStringWithTooltip( Controls.GovernmentTitle, MAX_BEFORE_TRUNC_GOV_TITLE, Locale.ToUpper(m_kCurrentData[DATA_FIELD_GOVERNMENT]["NAMES"]));
	Controls.DiplomaticIconCount:SetText(tostring(m_kCurrentData[DATA_FIELD_GOVERNMENT]["DIPLOMATIC"]));
	Controls.EconomicIconCount:SetText(tostring(m_kCurrentData[DATA_FIELD_GOVERNMENT]["ECONOMIC"]));
	Controls.MilitaryIconCount:SetText(tostring(m_kCurrentData[DATA_FIELD_GOVERNMENT]["MILITARY"]));
	Controls.WildcardIconCount:SetText(tostring(m_kCurrentData[DATA_FIELD_GOVERNMENT]["WILDCARD"]));

	local int numDiploResults = #m_kCurrentData[DATA_FIELD_GOVERNMENT]["DIPLOMATICPOLICIES"];
	for i,policy in ipairs(m_kCurrentData[DATA_FIELD_GOVERNMENT]["DIPLOMATICPOLICIES"]) do
		if(policy ~= -1) then
			local diploInst:table = m_kDiplomaticPolicyIM:GetInstance();
			local policyType:string = GameInfo.Policies[policy].Name;
			if numDiploResults > 3 then
				diploInst.DiplomaticPolicy:SetSizeVal(111/numDiploResults, 44 * (3/numDiploResults));
			end
			diploInst.DiplomaticPolicy:SetToolTipString(m_kPolicyCatalogData[policyType].Name .. ": " .. m_kPolicyCatalogData[policyType].Description);
			diploInst.DiplomaticPolicy:RegisterCallback( Mouse.eLClick, function() OnClickCurrentPolicy(policy) end );
		end
	end

	local int numEcoResults = #m_kCurrentData[DATA_FIELD_GOVERNMENT]["ECONOMICPOLICIES"];
	for i,policy in ipairs(m_kCurrentData[DATA_FIELD_GOVERNMENT]["ECONOMICPOLICIES"]) do
		if(policy ~= -1) then
			local ecoInst:table = m_kEconomicPolicyIM:GetInstance();
			local policyType:string = GameInfo.Policies[policy].Name
			if numEcoResults > 3 then
				ecoInst.EconomicPolicy:SetSizeVal(111/numEcoResults, 44 * (3/numEcoResults));
			end
			local description:string = m_kPolicyCatalogData[policyType].Name .. ": " .. m_kPolicyCatalogData[policyType].Description
			ecoInst.EconomicPolicy:SetToolTipString(description);
			ecoInst.EconomicPolicy:RegisterCallback( Mouse.eLClick, function() OnClickCurrentPolicy(policy) end );
		end
	end

	local int numMilResults = #m_kCurrentData[DATA_FIELD_GOVERNMENT]["MILITARYPOLICIES"];
	for i,policy in ipairs(m_kCurrentData[DATA_FIELD_GOVERNMENT]["MILITARYPOLICIES"]) do
		if(policy ~= -1) then
			local milInst:table = m_kMilitaryPolicyIM:GetInstance();
			local policyType:string = GameInfo.Policies[policy].Name
			if numMilResults > 3 then
				milInst.MilitaryPolicy:SetSizeVal(111/numMilResults, 44 * (3/numMilResults));
			end
			milInst.MilitaryPolicy:SetToolTipString(m_kPolicyCatalogData[policyType].Name .. ": " .. m_kPolicyCatalogData[policyType].Description);
			milInst.MilitaryPolicy:RegisterCallback( Mouse.eLClick, function() OnClickCurrentPolicy(policy) end );
		end
	end

	local int numWildResults = #m_kCurrentData[DATA_FIELD_GOVERNMENT]["WILDCARDPOLICIES"];
	for i,policy in ipairs(m_kCurrentData[DATA_FIELD_GOVERNMENT]["WILDCARDPOLICIES"]) do
		if(policy ~= -1) then
			local wildInst:table = m_kWildcardPolicyIM:GetInstance();
			local policyType:string = GameInfo.Policies[policy].Name;
			local slotType:string =  GameInfo.Policies[policy].GovernmentSlotType;
			if slotType == "SLOT_DIPLOMATIC" then
				wildInst.WildcardPolicy:SetTexture("Governments_DiplomacyCard_Small");
			else
				if slotType == "SLOT_ECONOMIC" then
					wildInst.WildcardPolicy:SetTexture("Governments_EconomicCard_Small");
				else
					if slotType == "SLOT_MILITARY" then
						wildInst.WildcardPolicy:SetTexture("Governments_MilitaryCard_Small");
					end
				end
			end
			if numWildResults > 3 then
				wildInst.WildcardPolicy:SetSizeVal(111/numWildResults, 44 * (3/numWildResults));
			end
			wildInst.WildcardPolicy:SetToolTipString(m_kPolicyCatalogData[policyType].Name .. ": " .. m_kPolicyCatalogData[policyType].Description);
			wildInst.WildcardPolicy:RegisterCallback( Mouse.eLClick, function() OnClickCurrentPolicy(policy) end );
		end
	end

end

-- ===========================================================================
--	Fill the catalog with the static (unchanging) policy data used by
--	all players when viewing the screen.
-- ===========================================================================
function PopulateStaticData()

	-- Fill in the complete catalog of policies.
	m_kPolicyCatalogData = {};
	for row in GameInfo.Policies() do
		local policyTypeRow		:table	= GameInfo.Types[row.PolicyType];
		local policyName		:string = Locale.Lookup(row.Name);
		local policyTypeHash	:number = policyTypeRow.Hash;
		local slotType			:string = row.GovernmentSlotType;
		local description		:string = Locale.Lookup(row.Description);
		--local draftCost			:number = kPlayerCulture:GetEnactPolicyCost(policyTypeHash);	--Move to live data
	
		m_kPolicyCatalogData[row.Name] = {			
			Description = description, 
			Name		= policyName, 
			PolicyHash	= policyTypeHash, 
			SlotType	= slotType,			-- SLOT_MILITARY, SLOT_ECONOMIC, SLOT_DIPLOMATIC, SLOT_WILDCARD, (SLOT_GREAT_PERSON)
			UniqueID	= row.Index			-- the row this policy exists in, is guaranteed to be unique (as-is the house, but these are readable. ;) )
			};
	end	

	-- Fill in governments
	m_kGovernments = {};
	for row in GameInfo.Governments() do
		local government		:table	= GameInfo.Types[row.GovernmentType];
		local slotMilitary		:number = 0;
		local slotEconomic		:number = 0;
		local slotDiplomatic	:number = 0;
		local slotWildcard		:number = 0;
		for entry in GameInfo.Government_SlotCounts() do
			if row.GovernmentType == entry.GovernmentType then
				local slotType = entry.GovernmentSlotType;
				for i = 1, entry.NumSlots, 1 do
					if		slotType == "SLOT_MILITARY" then									slotMilitary	= slotMilitary + 1;
					elseif	slotType == "SLOT_ECONOMIC" then									slotEconomic	= slotEconomic + 1;
					elseif	slotType == "SLOT_DIPLOMATIC" then									slotDiplomatic	= slotDiplomatic + 1;
					elseif	slotType == "SLOT_WILDCARD" or slotType=="SLOT_GREAT_PERSON" then	slotWildcard	= slotWildcard + 1;
					end
				end
			end
		end

		m_kGovernments[row.Name] = {
			BonusAccumlatedText	= row.AccumulatedBonusDesc,
			BonusInherentText	= row.InherentBonusDesc,
			BonusType			= row.BonusType,
			Hash				= government.Hash,
			Index				= row.Index,
			Name				= row.Name,
			NumSlotMilitary		= slotMilitary,
			NumSlotEconomic		= slotEconomic,
			NumSlotDiplomatic	= slotDiplomatic,
			NumSlotWildcard		= slotWildcard
		}
	end

end

-- ===========================================================================
--	Show/Hide key panel
-- ===========================================================================
function OnClickToggleKey()
	if Controls.KeyPanel:IsHidden() then
		UserConfiguration.SetShowCivicsTreeKey(true);		
	else
        UI.PlaySound("UI_TechTree_Filter_Closed");
		UserConfiguration.SetShowCivicsTreeKey(false);		
	end
	RealizeKeyPanel();
end
Controls.ToggleKeyButton:RegisterCallback(Mouse.eLClick, OnClickToggleKey);

function OnClickToggleGovernment()
	if Controls.GovernmentPanel:IsHidden() then
		UserConfiguration.SetShowCivicsTreeGovernment(true);		
	else
        UI.PlaySound("UI_TechTree_Filter_Closed");
		UserConfiguration.SetShowCivicsTreeGovernment(false);		
	end
	RealizeGovernmentPanel();
end
Controls.ToggleGovernmentButton:RegisterCallback(Mouse.eLClick, OnClickToggleGovernment);

function OnClickToggleFilter()
    if Controls.FilterPulldown:IsOpen() then
        UI.PlaySound("UI_TechTree_Filter_Open");
    else
        UI.PlaySound("UI_TechTree_Filter_Closed");
    end             
end

-- ===========================================================================
--	Main close function all exit points should call.
-- ===========================================================================
function Close()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end
	ContextPtr:SetHide(true);
	LuaEvents.CivicsTree_CloseCivicsTree();
	Controls.SearchResultsPanelContainer:SetHide(true);
end
-- ===========================================================================
--	Close via click
-- ===========================================================================
function OnClose()
	Close();
end


-- ===========================================================================
--	Input
--	UI Event Handler
-- ===========================================================================
function KeyDownHandler( key:number )
	if key == Keys.VK_SHIFT then
		m_shiftDown = true;
		-- let it fall through
	end
	return false;
end
function KeyUpHandler( key:number )
	if key == Keys.VK_SHIFT then
		m_shiftDown = false;
		-- let it fall through
	end
    if key == Keys.VK_ESCAPE then
		Close();
		return true;
    end
	if key == Keys.VK_RETURN then
		-- Don't let enter propigate or it will hit action panel which will raise a screen (potentially this one again) tied to the action.
		return true;
	end
    return false;
end
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyDown then return KeyDownHandler( pInputStruct:GetKey() ); end
	if uiMsg == KeyEvents.KeyUp then return KeyUpHandler( pInputStruct:GetKey() ); end	
	return false;
end


-- ===========================================================================
--	UI Event Handler
-- ===========================================================================
function OnShutdown()
	-- Clean up events
	LuaEvents.CivicsPanel_RaiseCivicsTree.Remove( OnOpen );
	LuaEvents.LaunchBar_RaiseCivicsTree.Remove( OnOpen );
	LuaEvents.LaunchBar_CloseCivicsTree.Remove( OnClose );

	Events.BuildingChanged.Remove( OnBuildingChanged );
	Events.CityFocusChanged.Remove( OnUpdateDueToCity );
	Events.CityInitialized.Remove( OnCityInitialized );
	Events.CityWorkerChanged.Remove( OnUpdateDueToCity );
	Events.CivicChanged.Remove( OnCivicChanged );
	Events.CivicQueueChanged.Remove( OnCivicChanged );
	Events.CivicCompleted.Remove( OnCivicComplete );
	Events.GovernmentChanged.Remove( OnGovernmentChanged );
	Events.GovernmentPolicyChanged.Remove( OnGovernmentPolicyChanged );
	Events.GovernmentPolicyObsoleted.Remove( OnGovernmentPolicyChanged );
	Events.LocalPlayerChanged.Remove( OnLocalPlayerChanged );
	Events.LocalPlayerTurnBegin.Remove( OnLocalPlayerTurnBegin );
	Events.LocalPlayerTurnEnd.Remove( OnLocalPlayerTurnEnd );	
	Events.SystemUpdateUI.Remove( OnUpdateUI );

	Search.DestroyContext("Civics");
end

-- ===========================================================================
--	Centers scroll panel (if possible) on a specfic type.
-- ===========================================================================
function ScrollToNode( typeName:string )
	local percent:number = 0;
	local x		= g_uiNodes[typeName].x - ( m_width * 0.5);
	local size  = (m_width / Controls.NodeScroller:GetRatio()) - m_width;
	percent = math.clamp( x  / size, 0, 1);
	Controls.NodeScroller:SetScrollValue(percent);
	m_kSearchResultIM:DestroyInstances();	
	Controls.SearchResultsPanelContainer:SetHide(true);
end

-- ===========================================================================
--	Searching
-- ===========================================================================
function OnSearchCharCallback()
	local str = Controls.SearchEditBox:GetText();

	local defaultText = Locale.Lookup("LOC_TREE_SEARCH_W_DOTS")
	if(str == defaultText) then
		-- We cannot immediately clear the results..
		-- When the edit box loses focus, it resets the text which triggers this call back.
		-- if the user is in the process of clicking a result, wiping the results in this callback will make the user
		-- click whatever was underneath.
		-- Instead, trigger a timer will wipe the results.
		Controls.SearchResultsTimer:SetToBeginning();
		Controls.SearchResultsTimer:Play();

	elseif(str == nil or #str == 0) then
		-- Clear results.
		m_kSearchResultIM:DestroyInstances();
		Controls.SearchResultsStack:CalculateSize();
		Controls.SearchResultsPanel:CalculateSize();
		Controls.SearchResultsPanelContainer:SetHide(true);

	elseif(str and #str > 0) then
		local hasResults = false;
		m_kSearchResultIM:DestroyInstances();
		local results = Search.Search("Civics", str, 100);
		if (results and #results > 0) then
			hasResults = true;
			local has_found = {};
			for i, v in ipairs(results) do
				-- v[1] == Type
				-- v[2] == Name w/ search term highlighted.
				-- v[3] == Snippet description w/ search term highlighted.
				local civicType = v[1];
				if has_found[civicType] == nil and IsSearchable(civicType) then
					local instance = m_kSearchResultIM:GetInstance();

					-- Search results already localized.
					local name = v[2];
					instance.Name:SetText(name);
					local iconName = DATA_ICON_PREFIX .. civicType;
					instance.SearchIcon:SetIcon(iconName);

					instance.Button:RegisterCallback(Mouse.eLClick, function() 
						Controls.SearchEditBox:SetText(defaultText);
						ScrollToNode(civicType); 
					end);

					instance.Button:SetToolTipString(ToolTipHelper.GetToolTip(v[1], Game.GetLocalPlayer()));

					has_found[civicType] = true;
				end
			end
		end
		
		Controls.SearchResultsStack:CalculateSize();
		Controls.SearchResultsPanel:CalculateSize();
		Controls.SearchResultsPanelContainer:SetHide(not hasResults);
	end
end

-- ===========================================================================
--	Can a tech be searched.
--	Always true in base game, but may be overridden by a MOD.
-- ===========================================================================
function IsSearchable(techType)
	return true;
end

-- ===========================================================================
function OnSearchCommitCallback()
	local str = Controls.SearchEditBox:GetText();

	local defaultText = Locale.Lookup("LOC_TREE_SEARCH_W_DOTS")
	if(str and #str > 0 and str ~= defaultText) then
		local results = Search.Search("Civics", str, 1);
		if (results and #results > 0) then
			local result = results[1];
			if(result) then
				ScrollToNode(result[1]); 
			end
		end

		Controls.SearchEditBox:SetText(defaultText);
	end
end

-- ===========================================================================
function OnSearchBarGainFocus()
	Controls.SearchResultsTimer:Stop();
	Controls.SearchEditBox:ClearString();
end

-- ===========================================================================
function OnSearchBarLoseFocus()
	Controls.SearchEditBox:SetText(Locale.Lookup("LOC_TREE_SEARCH_W_DOTS"));
end

-- ===========================================================================
function OnSearchResultsTimerEnd()
	m_kSearchResultIM:DestroyInstances();
	Controls.SearchResultsStack:CalculateSize();
	Controls.SearchResultsPanel:CalculateSize();
	Controls.SearchResultsPanelContainer:SetHide(true);
end

function OnSearchResultsPanelContainerMouseEnter()
	Controls.SearchResultsTimer:Stop();
end

function OnSearchResultsPanelContainerMouseExit()
	if(not Controls.SearchEditBox:HasFocus()) then
		Controls.SearchResultsTimer:SetToBeginning();
		Controls.SearchResultsTimer:Play();
	end
end

-- ===========================================================================
function OnCityInitialized(owner, ID)
	RefreshDataIfNeeded( owner );
end

-- ===========================================================================
function OnBuildingChanged( plotX:number, plotY:number, buildingIndex:number, playerID:number, cityID:number, iPercentComplete:number )
	RefreshDataIfNeeded( playerID ); -- Buildings can change culture/science yield which can effect "turns to complete" values
end

-- ===========================================================================
function BuildTree()
	local kNodeGrid	:table = nil;
	local kPaths	:table = nil;			-- Recommended line pathing
	kNodeGrid, kPaths = LayoutNodeGrid();	-- Layout nodes. 
	AllocateUI( kNodeGrid, kPaths );
end

-- ===========================================================================
--	Initialize after the context is loaded
--	MODDERS:	If you need to change how the tech tree inits, this is a great
--				place to do it.
-- ===========================================================================
function LateInitialize()
	
	PopulateStaticData();
	g_kItemDefaults = PopulateItemData("Civics","CivicType","CivicPrereqs","Civic","PrereqCivic");
	PopulateEraData();
	PopulateFilterData();
	PopulateSearchData();	
	BuildTree();

	-- May be observation mode.
	m_ePlayer = Game.GetLocalPlayer();
	if (m_ePlayer == -1) then
		return;
	end

	Resize();
	
	m_kCurrentData = GetCurrentData( m_ePlayer );
	View( m_kCurrentData );
end

-- ===========================================================================
--	Load all static information as well as display information for the
--	current local player.
-- ===========================================================================
function OnInit( isReload:boolean )
	LateInitialize();
end

-- ===========================================================================
--	Load all static information as well as display information for the
--	current local player.
-- ===========================================================================
function Initialize()

	-- Debug: convert numbered list above to key indexes.
	if debugExplicitList == nil then debugExplicitList = {} end
	if table.count(debugExplicitList) ~= 0 then
		local temp:table = {};
		for i,v in ipairs(debugExplicitList) do
			temp[v] = true;
		end
		debugExplicitList = temp;
	end
	
	-- Is the randomized tree game mode (a delicious topping) active?
	m_isTreeRandomized = GameCapabilities.HasCapability("CAPABILITY_TREE_RANDOMIZER");	
	
	-- UI Events
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShutdown( OnShutdown );
	Controls.SearchEditBox:RegisterStringChangedCallback(OnSearchCharCallback);
	Controls.SearchEditBox:RegisterHasFocusCallback( OnSearchBarGainFocus);
	Controls.SearchEditBox:RegisterCommitCallback( OnSearchBarLoseFocus);
	Controls.SearchResultsTimer:RegisterEndCallback(OnSearchResultsTimerEnd);
	Controls.SearchResultsPanelContainer:RegisterMouseEnterCallback(OnSearchResultsPanelContainerMouseEnter);
	Controls.SearchResultsPanelContainer:RegisterMouseExitCallback(OnSearchResultsPanelContainerMouseExit);

	local pullDownButton = Controls.FilterPulldown:GetButton();	
	pullDownButton:RegisterCallback(Mouse.eLClick, OnClickToggleFilter);

	-- LUA Events
	LuaEvents.CivicsChooser_RaiseCivicsTree.Add( OnOpen );
	LuaEvents.LaunchBar_RaiseCivicsTree.Add( OnOpen );
	LuaEvents.LaunchBar_CloseCivicsTree.Add( OnClose );

	-- Game engine Event	
	Events.BuildingChanged.Add( OnBuildingChanged );
	Events.CityFocusChanged.Add( OnUpdateDueToCity );
	Events.CityInitialized.Add( OnCityInitialized );
	Events.CityWorkerChanged.Add( OnUpdateDueToCity );
	Events.CivicChanged.Add( OnCivicChanged );
	Events.CivicQueueChanged.Add( OnCivicChanged );
	Events.CivicCompleted.Add( OnCivicComplete );
	Events.GovernmentChanged.Add( OnGovernmentChanged );
	Events.GovernmentPolicyChanged.Add( OnGovernmentPolicyChanged );
	Events.GovernmentPolicyObsoleted.Add( OnGovernmentPolicyChanged );
	Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );
	Events.LocalPlayerTurnBegin.Add( OnLocalPlayerTurnBegin );
	Events.LocalPlayerTurnEnd.Add( OnLocalPlayerTurnEnd );
	Events.SystemUpdateUI.Add( OnUpdateUI );

	m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET;
end

if HasCapability("CAPABILITY_CIVICS_TREE") then
	Initialize();
end
