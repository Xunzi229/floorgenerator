require "fileutils"
module SDMD
	class ImportMaterial
		def initialize path,mal,maw
			@path = path
			@mal = mal
			@maw = maw
			@mod = Sketchup.active_model
			self.copy_file
		end

		def file_name
			File.basename(@path)
		end

=begin
# 导入图片到指定位置
		def  import_file_material
		  unless @path.nil?
			  ter = "ma"+File.basename(@path,".*").to_s
			  m = @mod.materials.add ter
			  m.texture = material_com_path
			  # @path.to_s
			  texture = m.texture
	      texture.size= [Format.mm_to_inches(@mal.to_i),Format.mm_to_inches(@maw.to_i)]
	    end
	    delete_material_file
	    return ter
		end
=end

		def copy_file
			port_dir = File.join(File.dirname(__FILE__),"BTW_Textures")
			FileUtils.cp @path,port_dir
			return port_dir
		end

		def material_com_path
			File.join(copy_file,file_name)
		end


		def delete_material_file
			File.delete(material_com_path)
		end

	end


	class Format
		MM = 25.4.freeze
    CM = 2.54.freeze
	  # 1英寸(in)=25.4毫米(mm)
    def self.mm_to_inches mm
      (mm/MM).to_f
    end

    def self.cm_to_inches cm
      (cm/CM).to_f
     end
  end
end