require 'Sketchup'
Sketchup::require File.join(File.dirname(__FILE__),"SDM_FloorGenerator_WD.rb")
# ------------------  MENU SETUP ---------------------- #
unless $sdm_tools_menu
	$sdm_tools_menu = UI.menu("Plugins").add_submenu("SDM Tools")
	$sdm_Edge_tools = $sdm_tools_menu.add_submenu("Edge Tool")
	$sdm_Face_tools = $sdm_tools_menu.add_submenu("Face Tool")
	$sdm_CorG_tools = $sdm_tools_menu.add_submenu("CorG Tool")
	$sdm_Misc_tools = $sdm_tools_menu.add_submenu("Misc Tool")
end
unless file_loaded?(__FILE__)
	$sdm_Face_tools.add_item('FloorGenerator') { Sketchup.active_model.select_tool SDM::SDM_FloorGenerator.new }
	tb=UI::Toolbar.new("FlrGen")
	cmd=UI::Command.new("FlrGen") { Sketchup.active_model.select_tool SDM::SDM_FloorGenerator.new }
	cmd.small_icon=cmd.large_icon=File.join(File.dirname(__FILE__).gsub('\\','/'),"FG_Icons/Brick.jpg")
	cmd.tooltip="Floor Generator";tb.add_item cmd;tb.show unless tb.get_last_state==0
	file_loaded(__FILE__)
end
# ------------------------------------------------------ #