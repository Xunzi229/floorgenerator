module SDM_Extensions
	module SDM_FloorGenerator_Extension
		require 'sketchup'
		require 'extensions'
		SDM_Floor = SketchupExtension.new("FloorGenerator_WD", (File.join(File.dirname(__FILE__),"floorGenerator_WD","floor_init.rb")))
		SDM_Floor.version = '1.0.0'
		SDM_Floor.creator = '浙江数联云集团有限公司'
		SDM_Floor.copyright='数联中国'
		SDM_Floor.description = "一键生成网格"
		Sketchup.register_extension SDM_Floor, true
	end
end	