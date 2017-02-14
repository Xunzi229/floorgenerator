require 'Sketchup'
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
module SDM

	class SDM_FloorGenerator

		@@dlg=@@opt=nil
		
		def initialize
			@mod=Sketchup.active_model
			@ent=@mod.active_entities
			@sel=@mod.selection
			@vue=@mod.active_view
			@ip=Sketchup::InputPoint.new
			@colors=Sketchup::Color.names
			@icons = File.join(File.dirname(__FILE__).gsub('\\','/'),"FG_Icons/"); #puts @icons
			@images = Dir[File.join(File.dirname(__FILE__).gsub('\\','/'),"BTW_Textures/*.{jpg,png,tif,bmp,gif,tga,epx}")];
			@textures=[]; @images.each{|i| @textures<<File.basename(i,'.*')};
			self.add_default_materials
			@mod.commit_operation if @textures[0]
			self.system_environment
			@current_units=Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
			@@opt ||= "Tile"
			self.dialog
		end

		# Get current system type
		def system_environment
			RUBY_PLATFORM =~ /(darwin)/ ? @font="Helvetica" : @font="Arial"
		end

		def add_default_materials
			@mod.start_operation "Add Materials" if @textures[0]
			@textures.each_with_index{|name,i|
				unless @mod.materials[name]
					mat = @mod.materials.add(name)
					mat.texture = @images[i]
				end
			}
		end

		# 单独的处理 材质的问题：为需要的地板贴需要的材质(到时候有一个材质的选择框,提供设置材质大小选项)
		def material
		end

		def dialog
			if Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]>1
				Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]=2; #millimeters
				@defaults=["Corner","0","Current","No","No","50","No","No","0","No","No","30","150","50","6","6","3","No","Yes","0","0","3","6"] if @@opt=="Brick" || @@opt=="Wedge";
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","300","300","6","3","3","No","Yes","0","0","3","6"] if @@opt=="Tile" || @@opt=="HpScth4"; 
				@defaults=["Corner","0","Current","Yes","Yes","0","No","No","0","No","No","30","2000","100","3","3","3","No","Yes","0","0","3","6"] if @@opt=="Wood"; 
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","150","50","12","6","3","Yes","Yes","0","0","3","6"] if @@opt=="Tweed"
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","200","100","12","6","3","Yes","Yes","0","0","3","6"] if @@opt=="Hbone" || @@opt=="BsktWv" || @@opt=="I_Block" ; 
				@defaults=["Center","0","Current","No","No","0","No","No","0","No","No","30","300","300","12","6","3","Yes","Yes","0","0","3","6"] if @@opt=="HpScth1" || @@opt=="HpScth2"; 
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","600","600","6","3","3","No","Yes","0","0","3","6"] if @@opt=="HpScth3"; 
				@defaults=["Center","0","Current","No","No","0","No","No","0","No","No","30","300","0","12","6","3","No","Yes","0","0","3","6"] if @@opt=="Hexgon" || @@opt=="Octgon" || @@opt=="IrPoly" || @@opt=="Diamonds"; 
			else
				Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]=0; #inches
				@defaults=["Corner","0","Current","No","No","50","No","No","0","No","No","30","6.0","2.0","0.25","0.25","3","No","Yes","0","0","0.125","0.25"] if @@opt=="Brick" || @@opt=="Wedge"; 
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","12.0","12.0","0.25","0.125","3","No","Yes","0","0","0.125","0.25"] if @@opt=="Tile" || @@opt=="HpScth4"; 
				@defaults=["Corner","0","Current","Yes","Yes","0","No","No","0","No","No","30","60.0","3.0","0.125","0.125","3","No","Yes","0","0","0.125","0.25"] if @@opt=="Wood";
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","6.0","2.0","0.5","0.25","3","Yes","Yes","0","0","0.125","0.25"] if @@opt=="Tweed"; 
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","8.0","4.0","0.5","0.25","3","Yes","Yes","0","0","0.125","0.25"] if @@opt=="Hbone"  || @@opt=="BsktWv" || @@opt=="I_Block" ; 
				@defaults=["Center","0","Current","No","No","0","No","No","0","No","No","30","12.0","12.0","0.5","0.25","3","Yes","Yes","0","0","0.125","0.25"] if @@opt=="HpScth1" || @@opt=="HpScth2" || @@opt=='HpScth3'; 
				@defaults=["Corner","0","Current","No","No","0","No","No","0","No","No","30","24.0","24.0","0.25","0.125","3","No","Yes","0","0","0.125","0.25"] if @@opt=="HpScth3"; 
				@defaults=["Center","0","Current","No","No","0","No","No","0","No","No","30","12.0","0.0","0.5","0.25","3","No","Yes","0","0","0.125","0.25"] if @@opt=="Hexgon" || @@opt=="Octgon" || @@opt=="IrPoly" || @@opt=="Diamonds"; 
			end
			begin
				@spt,@rot,@app,@flw,@fww,r2r,@rtt,@rtr,txs,@rfr,@bev,twa,tbx,tby,gw,gd,bwb,@ate,@fwt,rds,rin,rix,bvs=Sketchup.read_default("FloorGenerator",@@opt,@defaults)
				@GX=tbx.to_l;@GY=tby.to_l;@GW=gw.to_l;@HW=@GW/2.0;@GD=gd.to_l;@bwb=bwb.to_i; @rds=rds.to_i; @rin = rin.to_l; @rix  = rix.to_l; @bvs = bvs.to_l;
				txw,txh=txs.split(","); if txh then @txs=[txw.to_l,txh.to_l] else @txs=txs.to_l end; @twa=twa.to_f;@r2r=r2r.to_f;
			rescue
				Sketchup.write_default("FloorGenerator",@@opt,@defaults)
				self.dialog
			end
			unless @@dlg
				@@dlg=UI::WebDialog.new("网格生成", false,"BTW",220,600,10,10,true)
				@@dlg.set_html(
					"<!DOCTYPE html>
						<html>
						<head>
							<META http-equiv='X-UA-Compatible' content='IE=9' />
							<meta charset='utf-8'>
						</head>
						<body style='background-color: rgb(119,136,153)' >
							<form style='font-family:#{@font};font-size:70%;color:black' >
								<fieldset>
									<legend style='font-size:125%;color:red'><b> 模式 </b></legend>
									<select onChange='patternchanged(value)'>
										<option value='Brick' #{@@opt=='Brick' ? 'selected' : ''}>Brick</option>
										<option value='Tile' #{@@opt=='Tile' ? 'selected' : ''}>Tile</option>
										<option value='Wood' #{@@opt=='Wood' ? 'selected' : ''}>Wood</option>
										<option value='Tweed' #{@@opt=='Tweed' ? 'selected' : ''}>Tweed</option>
										<option value='Hbone' #{@@opt=='Hbone' ? 'selected' : ''}>Herringbone</option>
										<option value='BsktWv' #{@@opt=='BsktWv' ? 'selected' : ''}>Basket Weave</option>
										<option value='HpScth1' #{@@opt=='HpScth1' ? 'selected' : ''}>Hopscotch1</option>
										<option value='HpScth2' #{@@opt=='HpScth2' ? 'selected' : ''}>HopScotch2</option>
										<option value='HpScth3' #{@@opt=='HpScth3' ? 'selected' : ''}>HopScotch3</option>
										<option value='HpScth4' #{@@opt=='HpScth4' ? 'selected' : ''}>HopScotch4</option>
										<option value='IrPoly' #{@@opt=='IrPoly' ? 'selected' : ''}>Irregular Polygons</option>
										<option value='Hexgon' #{@@opt=='Hexgon' ? 'selected' : ''}>Hexagons</option>
										<option value='Octgon' #{@@opt=='Octgon' ? 'selected' : ''}>Octagons</option>
										<option value='Wedge' #{@@opt=='Wedge' ? 'selected' : ''}>Wedges</option>
										<option value='I_Block' #{@@opt=='I_Block' ? 'selected' : ''}>I_Block</option>
										<option value='Diamonds' #{@@opt=='Diamonds' ? 'selected' : ''}>Diamonds</option>
										<option value='Reset'>Reset</option>
									</select>
									<!-- Pattern Icons -->
									#{@@opt=='Brick' ? "<img src='#{@icons}Brick.jpg' align='top'/>" : ''}
									#{@@opt=='Tile' ? "<img src='#{@icons}Tile.jpg' align='top'/>" : ''}
									#{@@opt=='Wood' ? "<img src='#{@icons}Wood.jpg' align='top'/>" : ''}
									#{@@opt=='Tweed' ? "<img src='#{@icons}Tweed.jpg' align='top'/>" : ''}
									#{@@opt=='Hbone' ? "<img src='#{@icons}Hbone.jpg' align='top'/>" : ''}
									#{@@opt=='BsktWv' ? "<img src='#{@icons}BsktWv.jpg' align='top'/>" : ''}
									#{@@opt=='HpScth1' ? "<img src='#{@icons}HpScth1.jpg' align='top'/>" : ''}
									#{@@opt=='HpScth2' ? "<img src='#{@icons}HpScth2.jpg' align='top'/>" : ''}
									#{@@opt=='HpScth3' ? "<img src='#{@icons}HpScth3.jpg' align='top'/>" : ''}
									#{@@opt=='HpScth4' ? "<img src='#{@icons}HpScth4.jpg' align='top'/>" : ''}
									#{@@opt=='IrPoly' ? "<img src='#{@icons}IrPoly.jpg' align='top'/>" : ''}
									#{@@opt=='Hexgon' ? "<img src='#{@icons}Hexgon.jpg' align='top'/>" : ''}
									#{@@opt=='Octgon' ? "<img src='#{@icons}Octgon.jpg' align='top'/>" : ''}
									#{@@opt=='Wedge' ? "<img src='#{@icons}Wedge.jpg' align='top'/>" : ''}
									#{@@opt=='I_Block' ? "<img src='#{@icons}I_Block.jpg' align='top'/>" : ''}
									#{@@opt=='Diamonds' ? "<img src='#{@icons}Diamonds.jpg' align='top'/>" : ''}
									<!-- Pattern Icons -->
								</fieldset>
							</form>
							<form style='font-family:#{@font};font-size:70%;color:black' >
								<fieldset>
									<legend style='font-size:125%;color:red'><b> 尺寸 </b></legend>
									#{((@@opt!='Hexgon' && @@opt!='Octgon' && @@opt!='Diamonds') || (@@opt=='IrPoly')) ? '<!--' : ''}
									<input type='text' name='BTL' value='#{@GX}' size=6 onChange='optionchanged(name,value)' /> : Length of Side <br>
									#{((@@opt!='Hexgon' && @@opt!='Octgon' && @@opt!='Diamonds') || (@@opt=='IrPoly')) ? '-->' : ''}
									#{(@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' || @@opt=='Diamonds') ? '<!--' : ''}
									<input type='text' name='BTL' value='#{@GX}' size=6 onChange='optionchanged(name,value)' /> : 长度 <br>
									<input type='text' name='BTW' value='#{@GY}' size=6 onChange='optionchanged(name,value)' /> : 宽度 <br>
									#{(@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' || @@opt=='Diamonds') ? '-->' : ''}
									<input type='text' name='BGW' value='#{@GW}' size=6 onChange='optionchanged(name,value)' /> : 间隙宽度 <br>
									<input type='text' name='BGD' value='#{@GD}' size=6 onChange='optionchanged(name,value)' /> : 间隙深度<br>
									#{@@opt!='BsktWv' ? '<!--' : ''}
									<input type='text' name='BWB' value='#{@bwb}' size=2 onChange='optionchanged(name,value)' /> : Weave Count(2-4)<br>
									#{@@opt!='BsktWv' ? '-->' : ''}
								</fieldset>
								<fieldset>
									<legend style='font-size:125%;color:red'><b> 选项 </b></legend>
									<select name='ORG' style='width:90px' onChange='optionchanged(name,value)'>
										<option value='Corner' #{@spt=='Corner' ? 'selected' : ''}>Corner</option>
										<option value='Center' #{@spt=='Center' ? 'selected' : ''}>Center</option>
									</select> : 网格的起源 <br>
									<select name='ROT' style='width:90px' onChange='optionchanged(name,value)'>
										<option value='0' #{@rot=='0' ? 'selected' : ''}>0</option>
										<option value='45' #{@rot=='45' ? 'selected' : ''}>45</option>
										<option value='90' #{@rot=='90' ? 'selected' : ''}>90</option>
									</select> : 网格旋转度<br>
									<select name='MAT' style='width:90px' onChange='optionchanged(name,value)'>
										<option value='Current' #{@app=='Current' ? 'selected' : ''}>Current</option>
										<option value='Rand_Clr' #{@app=='Rand_Clr' ? 'selected' : ''}>Rand_Clr</option>
										<option value='Rand_Tex' #{@app=='Rand_Tex' ? 'selected' : ''}>Rand_Tex</option><br>
									</select> : 材质文件<br><hr>
									#{@@opt!='Wood' ? '<!--' : ''}
									<input type='checkbox' name='FLW' value='Yes' #{@flw=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>Fixed Length<br>
									<input type='checkbox' name='FWW' value='Yes' #{@fww=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>Fixed Width<br>
									#{@@opt!='Wood' ? '-->' : ''}
									<input type='checkbox' name='FWT' value='Yes' #{@fwt=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>Fixed Depth
									<input type='text' name='RDS' value='#{rds}' size=2 onChange='optionchanged(name,value)'/> : Seed<br><hr>
									<input type='text' name='TSZ' value='#{txs}' size=5 onChange='optionchanged(name,value)'/> : 纹理大小 (w,h)<br>
									<select name='WIG' style='width:60px' onChange='optionchanged(name,value)'>
										<option value='No' #{@rtr=='No' ? 'selected' : ''}>No</option>
										<option value='90' #{@rtr=='90' ? 'selected' : ''}>90</option>
										<option value='180' #{@rtr=='180' ? 'selected' : ''}>180</option>
										<option value='Rand' #{@rtr=='Rand' ? 'selected' : ''}>Rand</option>
									</select> : 旋转纹理<br>
									#{@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' ? '<!--' : ''}
									<input type='checkbox' name='ATE' value='Yes' #{@ate=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>调整纹理边缘<br>   
									#{@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' ? '-->' : ''}
									<input type='checkbox' name='WAG' value='Yes' #{@rtt=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>随机位置纹理<br><hr>   
									<input type='checkbox' name='WOB' value='Yes' #{@rfr=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>随机缺陷<br> 
									#{@rfr!='Yes' ? '<!--' : ''}
									Min:<input type='text' name='RIn' value='#{@rin}' size=4 onChange='optionchanged(name,value)'/>
									Max:<input type='text' name='RIx' value='#{@rix}' size=4 onChange='optionchanged(name,value)'/> <br>
									#{@rfr!='Yes' ? '-->' : ''}
									<input type='checkbox' name='BVL' value='Yes' #{@bev=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>#{@@opt}增加 Bevel(斜角/斜面) <br>
									#{@bev!='Yes' ? '<!--' : ''}
									Size:<input type='text' name='BVS' value='#{@bvs}' size=4 onChange='optionchanged(name,value)'/>
									#{@bev!='Yes' ? '-->' : ''}
									#{@@opt!='Brick' && @@opt!='Tile' ? '<!--' : ''}
									<hr><input type='text' name='R2R' value='#{r2r}' size=4 onChange='optionchanged(name,value)' /> : Row2Row  (\%)<br>
									#{@@opt!='Brick' && @@opt!='Tile' ? '-->' : ''}
									#{@@opt!='Tweed' ? '<!--' : ''}
									<hr><input type='text' name='TWA' value='#{@twa}' size=4 onChange='optionchanged(name,value)' /> : Tweed Angle <br>
									#{@@opt!='Tweed' ? '-->' : ''}
								</fieldset>

								<fieldset>
									<legend style='font-size:125%;color:red'><b> 材质选项 </b></legend>
									<input type='file' accept='image/jpeg' size=6  /><br>
								  <input type='text' name='MAL' value=''   title='这里输入文字' size=6 onChange='optionchanged(name,value)' /> : 材质长度 <br>
									<input type='text' name='MAW' value='' size=6 onChange='optionchanged(name,value)' /> : 材质宽度 <br>
								</fieldset>


								<!--
								<br><input type='submit' name='submit' value='Update' />  #{@@opt} Options
								-->
							</form>
							<script type='text/javascript'>
								function patternchanged(value)
								{
									window.location='skp:PatternChanged@'+value;
								}
							</script>
							<script type='text/javascript'>
								function optionchanged(name,value)
								{
									window.location='skp:OptionChanged@'+name+'='+value;
								}
							</script>
						</body>
					</html>"
				)

				@@dlg.add_action_callback("OptionChanged") {|d,p|
					var,val = p.split("="); update=false; puts p
					case var
						when "BTL" then @GX = val.to_l
						when "BTW" then @GY = val.to_l
						when "BGW" then @GW = val.to_l;@HW = @GW/2.0
						when "BGD" then @GD = val.to_l
						when "BWB" then @bwb=val.to_i
						when "ORG" then @spt = val
						when "ROT" then @rot = val
						when "MAT" then @app = val
						when "FLW" then @flw=="Yes" ? @flw="No" : @flw="Yes";puts "flw=#{@flw}"
						when "FWW" then @fww=="Yes" ? @fww="No" : @fww="Yes";puts "fww=#{@fww}"
						when "FWT" then @fwt=="Yes" ? @fwt="No" : @fwt="Yes";puts "fwt=#{@fwt}"
						when "RDS" then @rds=val.to_i
						when "TSZ" then @tsz=val
						when "WIG" then @rtr=val
						when "ATE" then @ate=="Yes" ? @ate="No" : @ate="Yes";puts "ate=#{@ate}"
						when "WAG" then @rtt=="Yes" ? @rtt="No" : @rtt="Yes";puts "rtt=#{@rtt}"
						when "WOB" then @rfr=="Yes" ? @rfr="No" : @rfr="Yes";puts "rfr=#{@rfr}"; update=true
						when "BVL" then @bev=="Yes" ? @bev="No" : @bev="Yes";puts "bev=#{@bev}"; update=true
						when "R2R" then @r2r=val.to_f;r2r=val
						when "TWA" then @twa=val.to_f
						when "RIn" then @rin=val.to_l;@rin=[@rin,0].max
						when "RIx" then @rix=val.to_l;@rix=[@rix,@GD].min
						when "BVS" then @bvs=val.to_l;
					end
					tbx=@GX.to_s.gsub('"','\"'); tby=@GY.to_s.gsub('"','\"'); twa=@twa.to_s; @txs=nil;rds=@rds.to_s
					(txw,txh=@tsz.split(","); if txh then @txs=[txw.to_l,txh.to_l] else @txs=@tsz.to_l end) if @tsz && @tsz != "0"
					gw=@GW.to_s.gsub('"','\"'); gd=@GD.to_s.gsub('"','\"');txs=@tsz.gsub('"','\"') if @tsz;bwb=@bwb.to_s
					rin=@rin.to_s.gsub('"','\"'); rix=@rix.to_s.gsub('"','\"'); bvs=@bvs.to_s.gsub('"','\"')
					@defaults=[@spt,@rot,@app,@flw,@fww,r2r,@rtt,@rtr,txs,@rfr,@bev,twa,tbx,tby,gw,gd,bwb,@ate,@fwt,rds,rin,rix,bvs]
					Sketchup.write_default("FloorGenerator",@@opt,@defaults)
					(@dlg_update=true; @@dlg.close; @@dlg=nil; @dlg_update=false; self.dialog) if update
				}
				
				@@dlg.add_action_callback("PatternChanged") {|d,p|
					@@opt=p; puts p
					if @@opt=="Reset" then 
						["Brick","Tile","Wood","Tweed","Hbone","BsktWv","HpScth1","HpScth2"].each{|o| Sketchup.write_default("FloorGenerator",o,nil)};
						["HpScth3","HpScth4","IrPoly","Hexgon","Octgon","Wedge","I_Block","Diamonds"].each{|o| Sketchup.write_default("FloorGenerator",o,nil)};
						@@opt="Tile";
					end
					@dlg_update=true; @@dlg.close; @@dlg=nil; @dlg_update=false; self.dialog
				}
				
				@@dlg.set_on_close { onCancel(nil,nil) unless @dlg_update }
				
				RUBY_PLATFORM =~ /(darwin)/ ? @@dlg.show_modal() : @@dlg.show()
				
			end
		end
		
		# 当鼠标移动的时候调用这个方法
		def onMouseMove(flags, x, y, view)
			@ip.pick view,x,y; view.tooltip = @ip.tooltip; view.refresh
			Sketchup::set_status_text "选择网格模式,位置:#{x}:#{y}, change options or sizes if needed then select Face for #{@@opt} pattern"
		end
		
		#当按下鼠标左键时，SketchUp会调用onLButtonDown方法。
		# pick_helper方法用于检索视图的选取助手。有关拾取帮助程序的信息，请参阅PickHelper类。
		def onLButtonDown(flags, x, y, view)
			ph = view.pick_helper; 
			ph.do_pick x,y; 
			face=ph.best_picked; @cp=@ip.position;
			puts "@cp#{@cp}"
			if face.is_a?(Sketchup::Face)
				dmax = [@GX,@GY].max; 
				if (face.bounds.diagonal >= dmax*1.5); # 确保矩形是大到足以进行细分
					unless @@opt=="BsktWv" || @@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' || @@opt=='Diamonds'
						torb = (face.area/(@GX*@GY)).ceil
						if (@GX <= 1 || @GY <= 1) ||  ( torb > 500) then
							return if UI.messagebox("Tile demensions may be to small.  #{torb} #{@@opt} needed.  Continue?",MB_YESNO)==7
							view.refresh; 
						end
					end
					# 模型改变的开始，可用于撤销到当前的位置，参数提供了提示操作的作用
					@mod.start_operation "铺平地板",true
					eye = @vue.camera.eye; ctr=face.bounds.center;srand(@rds);
					face.reverse! if ((ctr.vector_to(eye)).angle_between(face.normal))>Math::PI/2.0
					@edges=face.edges;@norm=face.normal; l=0; fpts=[]; lpts=[]
					if @@opt=="Brick"
						for loop in face.loops
							for v in loop.vertices
								lpts<<v.position if v.position
							end
							fpts[l]=lpts; lpts=[]; l +=1
						end
					end
					
					if self.grid_data(face)
					
						begin
							@ent.erase_entities(face);
							existing_faces=@ent.grep(Sketchup::Face); dump=@egrp.explode
							dump.grep(Sketchup::Edge).each{|e| e.find_faces};
							created_faces=@ent.grep(Sketchup::Face) - existing_faces;
							# created_faces.reject!{|f| f.valid? && f.edges.length==4 && f.area.to_i==@d_area.to_i}; #remove diamonds from octagons
							cnt=0; max=created_faces.length;new_faces=[]; #d=[@GD/2,0.125].min; b = [@GD/2,0.5].min
							fgrp=@ent.add_group;@fge=fgrp.entities;srand(@rds)
							created_faces.each{|f| 
								cnt += 1; self.progress_bar(cnt,max,"#{@@opt} offsets");
								f.reverse! unless f.normal.samedirection? @norm; t=self.g_offset(f,@HW)
								(new_faces<<t; t.reverse! unless t.normal.samedirection? @norm; self.paint_it(t);
								@fwt=='Yes' ? gd=@GD : (gd=@GD+(@GD*rand*(rand<=>0.5))); t.pushpull(gd)) if t
							}
							faces = @fge.grep(Sketchup::Face).reject{|f| new_faces.include?(f) || !f.normal.samedirection?(@norm)};
							cnt=0; max=faces.length;srand(@rds);
							faces.each{|f|
								cnt += 1; self.progress_bar(cnt,max,"Added Options");
								self.wig(f) if @rtt=="Yes"
								self.wag(f) unless @rtr=="No"
								self.wob(f,-1) if @rfr=="Yes"
								self.bev(f,@bvs) if @bev=="Yes"
							}
							Sketchup.set_status_text "finishing and cleaning up"
							dump.each{|e| @ent.erase_entities(e) if e.valid? && e.is_a?(Sketchup::Edge)}
							if @@opt=="Brick"
								for  i in 0...fpts.length
									f=@fge.add_face(fpts[i])
									@fge.erase_entities(f) if i > 0
								end
							end
							@mod.commit_operation
						rescue Exception => e
							@o_pts.each{|p| @ent.add_cpoint(p)}
							# @mod.abort_operation
							# UI.messagebox("Error #<#{e.class.name}:#{e.message}.>")
						end
					end
				else
					UI.messagebox "This face is to small for a #{@GX} X #{@GY} #{@@opt} pattern.";return false
				end
			end
		end

		#当用户按下鼠标右键时，SketchUp会调用onRButtonDown方法。实现此方法，以及tool.getMenu方法		
		def onRButtonDown(flags, x, y, view)
			onCancel(flags,view)
		end
		
		#SketchUp调用onCancel方法来取消工具的当前操作。典型的响应是将工具复位到其初始状态。
		def onCancel(flags,view)
			Sketchup.send_action "selectSelectionTool:" 
		end
		
		def deactivate(view)
			@@dlg.close; @@dlg=nil
			Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]=@current_units
		end
		 
		def draw(view)
			if( @ip.valid? && @ip.display? )
				@ip.draw(view)
			end			
		end
		#
		##################################################
		#	Compute the data points of the grid
		##################################################
		#	
		def grid_data(face)
		
			pts=face.outer_loop.vertices.collect{|v| v.position}
			ndx=0; cp=1e6; ls=0.0; lp=pts.length-1; # assume regular 4 sided rectangle
			
			if @spt == "Corner"
				pts.each_with_index{|p,i| d=p.distance(@cp);ndx=i if d<cp; cp=[cp,d].min}; @cor=pts[ndx]
			else
				pts.each_with_index{|p,i| d=p.distance(pts[i-1])+p.distance(pts[i-lp]); ndx=i if d>ls; ls=[ls,d].max}
			end
			
				ctr=face.bounds.center; ctr=ctr.project_to_plane face.plane unless ctr.on_plane? face.plane
				d1=pts[ndx].distance(pts[ndx-lp]); d2=pts[ndx].distance(pts[ndx-1]);
				if d1 >= d2
					@v1=pts[ndx].vector_to(pts[ndx-lp]).normalize
					pol=ctr.project_to_line([pts[ndx],pts[ndx-lp]])
					rot = @rot.to_f
				else
					@v1=pts[ndx].vector_to(pts[ndx-1]).normalize
					pol=ctr.project_to_line([pts[ndx],pts[ndx-1]]);
					rot = -@rot.to_f
				end

				@v2=pol.vector_to(ctr).normalize;
				
				if @rot != "0"
					tr=Geom::Transformation.rotation(pts[ndx],@norm,rot.degrees)
					@v1.transform! tr; @v2.transform! tr
				end
				
				dx = @GX + @GW; dy = @GY + @GW;
				nx=(face.bounds.diagonal*1.5/dx).ceil;ny=(face.bounds.diagonal*1.5/dy).ceil;
				pt0 = ctr.offset(@v1,-dx*(nx/2)).offset(@v2,-dy*(ny/2))
				
				@data=[];row=[]; cnt=0; max=nx*ny; #@ent.add_cpoint(pt0)
				
				case @@opt
					when "Wood"
						yd = 0.0; nx *= 2 if @flw=="No"; ny *= 2 if @fww=="No"; srand(@rds)
						for i in 0..ny
							p0=row[0]=pt0.offset(@v2,yd)
							d = 0.0; ty = dy
							for j in 1..nx
								tx=dx
								if j==1
									begin
										tx=rand*dx
									end until tx>=dx*0.25 && tx<=dx*0.75
								else
									unless @flw=="Yes"
										begin
											tx=rand*dx
										end until tx>=dx*0.75
									end
								end
								d += tx; row[j]=p0.offset(@v1,d)
							end
							unless @fww=="Yes"
								begin
									ty=rand*dy
								end until ty>=dy*0.5
							end
							row.push ty; yd += ty
							@data[i]=row;row=[]
						end
					when "Tweed"
						dx=@GY + @GW;dy=@GX + @GW;
						xd=dx/Math.cos(@twa.degrees)
						yd=dy*Math.cos(@twa.degrees)
						xx=dy*Math.sin(@twa.degrees)
						ny=((face.bounds.diagonal*1.5)/yd).ceil;nx=((face.bounds.diagonal*1.5)/xd).ceil;
						pt0 = ctr.offset(@v1,-(xd*(nx/2))).offset(@v2,-(yd*(ny/2)))
						for i in 0..ny
							row[0]=pt0.offset(@v2,yd*i)
							if i%2==1 then row[0].offset!(@v1,-xx) end
							for j in 1..nx
								row[j]=row[j-1].offset(@v1,xd)
							end
							@data[i]=row;row=[]
						end
				end
								
				case @@opt
					when "Brick","Tile" ; self.brick_tile(face,dx,dy,nx,ny,pt0)
					when "Wood" ; self.wood(face,nx,ny)
					when "Tweed" ; self.tweed(face,nx,ny)
					when "Hbone" ; self.hbone(face)
					when "BsktWv" ; self.bsktwv(face,dx,dy) 
					when "HpScth1"; self.hopscotch(face,dx,dy)
					when "HpScth2" ; self.hopscotch2(face,dx,dy)
					when 'HpScth3' ; self.hopscotch3(face)
					when "HpScth4" ; self.hopscotch4(face,dx,dy)
					when "Hexgon" ; self.hexagon(face,@GX)
					when "Octgon" ; self.octagon(face,@GX)
					when "IrPoly" ; self.irpoly(face)
					when "Wedge" ; self.wedge(face,dx,dy)
					when "I_Block"; self.i_block(face,dx,dy)
					when "Diamonds" ; self.diamonds(face,@GX)
					else puts "#{@@opt} not found";return false
				end
				return true
		end
		#
		##################################################
		#	Create brick/tile pattern grid on selected face
		##################################################
		#
		def brick_tile(f,dx,dy,nx,ny,pt0)
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			fg=@ent.add_group f; cnt=0; max=nx*ny; md=1e9
			for i in 0..ny+1
				p0=pt0.offset(@v2,dy*i);p1=p0.offset(@v1,dx*nx)
				tge.add_face(self.makeaface(p0,p1,@norm))
				unless i>0
					p1=p0.offset(@v2,dy*ny)
					tge.add_face(self.makeaface(p0,p1,@norm))
				end
			 end
			 cnt=0; max=nx*ny
			for i in 0..ny
				p0=pt0.offset(@v2,dy*i)
				i>0 ? xd=((i*@r2r)%100/100.0)*dx : xd=dx
				for j in 0..nx
					cnt+=1;self.progress_bar(cnt,max,"#{@@opt} Grid")
					p1=p0.offset(@v1,xd);xd=dx;p2=p1.offset(@v2,dy)
					tge.add_face(self.makeaface(p1,p2,@norm))
					(d=@cor.distance(p0); (cpt=p0;md=d) if md>d) if @spt=="Corner" && i>0
					p0=p1
				end
			end
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with(true,tgt,@ege,@egt,false,fg)
			fg.explode; tg.erase! unless $sdm_debug; 
		end
		#
		##################################################
		#	Create wood pattern grid on selected face
		##################################################
		#	
		def wood(f,nx,ny)

			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			fg=@ent.add_group f; cnt=0; max=nx*ny; md=1e9
			for i in 0...ny
				dy = @data[i][-1]; 
				for j in 1..nx
					cnt += 1; self.progress_bar(cnt,max,"Wood grid")
					tge.add_face(self.makeaface(@data[i][j-1],@data[i][j],@norm))
					tge.add_face(self.makeaface(@data[i][j],@data[i][j].offset(@v2,dy),@norm))
					(d=@cor.distance(@data[i][j-1]); (cpt=@data[i][j-1];md=d) if md>d) if @spt=="Corner" && i>0
				end
			end
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with(true,tgt,@ege,@egt,false,fg)
			fg.explode; tg.erase! unless $sdm_debug; 
		end
		#
		##################################################
		#	Create Tweed pattern grid on selected face
		##################################################
		#	
		def tweed(f,nx,ny)
		
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			fg=@ent.add_group f; cnt=0; max=nx*ny; md=1e9
			for i in 1..ny
				for j in 1..nx
					cnt += 1; self.progress_bar(cnt,max,"Tweed grid")
					tge.add_face(self.makeaface(@data[i-1][j-1],@data[i][j-1],@norm))
					tge.add_face(self.makeaface(@data[i-1][j-1],@data[i-1][j],@norm))
					(d=@cor.distance(@data[i-1][j-1]); (cpt=@data[i-1][j-1];md=d) if md>d) if @spt=="Corner" && i>1
				end
				tge.add_face(self.makeaface(@data[i-1][nx],@data[i][nx],@norm))
			end
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with(true,tgt,@ege,@egt,false,fg)
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		##################################################
		#	Create Herringbone pattern grid on selected face
		##################################################
		#	
		def hbone(f)
			dx=@GY + @GW;dy=@GX + @GW;ctr=f.bounds.center
			ny=((f.bounds.diagonal*1.2)/(dy*0.707107)).ceil;nx=((f.bounds.diagonal*1.2)/(dx/0.707107)).ceil;
			pt = ctr.offset(@v1,-((dx/0.707107)*(nx/2))).offset(@v2,-((dy/0.707107)*(ny/2))/2);
			vup=@v1.transform Geom::Transformation.rotation(pt,@norm,45.degrees)
			vdn=@v1.transform Geom::Transformation.rotation(pt,@norm,-45.degrees)
			fg=@ent.add_group f; fgt=fg.transformation; fg.name="Face"
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			xv=@v1;xv.length=dx/0.707107; yv=@v2;yv.length=dy/0.707107
			cnt=0; max=nx*ny; md=1e9; gp=pt;
			p0=pt#.offset(Geom::Vector3d.new(0,0,-1))
			for i in 0..ny/2
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"H'bone grid")
					p1=p0.offset(vdn,dy);tge.add_face(self.makeaface(p0,p1,@norm))
					p2=p1.offset(vup,dx);tge.add_face(self.makeaface(p1,p2,@norm))
					p3=p2.offset(vdn,-dy);tge.add_face(self.makeaface(p2,p3,@norm))
					tge.add_face(self.makeaface(p3,p0,@norm))
					cnt += 1; self.progress_bar(cnt,max,"H'bone grid")
					p1=p0.offset(vup,dy);tge.add_face(self.makeaface(p0,p1,@norm))
					p2=p1.offset(vdn,-dx);tge.add_face(self.makeaface(p1,p2,@norm))
					p3=p2.offset(vup,-dy);tge.add_face(self.makeaface(p2,p3,@norm))
					tge.add_face(self.makeaface(p3,p0,@norm))
					(d=@cor.distance(gp);(cpt=gp;md=d) if md>d) if @spt=="Corner" && i>0
					p0 += xv; gp += xv
				end
					pt.offset!(yv); gp=pt
					p0=pt#.offset(Geom::Vector3d.new(0,0,-1))
			end
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		##################################################
		#	Create Basket Weave pattern on selected face
		##################################################
		#	
		def bsktwv (face,dx,dy)
			@bwb=3 unless [2,3,4].include?(@bwb)
			if dx==@GW then
				del=dy*@bwb*2
			elsif dy==@GW
				del=dx*2
			else
				del=[dx,dy*@bwb].max
				if del==dx then
					dy=dx/@bwb
					del=dx*2
				else
					dx=dy*@bwb
					del=dx*2
				end
			end
			name="BW-#{dx.to_l}X#{dy.to_l}X#{@bwb}"
			unless @mod.definitions[name]
				bw=@mod.definitions.add(name)
				be=bw.entities;pts=[];pts[0]=Geom::Point3d.new()
				v1=[1,0,0]; v2=[0,1,0]; norm=[0,0,1]
				tr=Geom::Transformation.new(pts[0],norm,90.degrees)
				for i in 0..@bwb-1
					pts<<pts[i].offset(v2,dy)
				end
				pts<<pts[@bwb].offset(v1,dx)
				for i in @bwb+1..@bwb*2
					pts<<pts[i].offset(v2,-dy)
				end
				for n in 1..4
					case @bwb
						when 2
							be.add_face(self.makeaface(pts[0],pts[2],norm))
							be.add_face(self.makeaface(pts[2],pts[3],norm))
							be.add_face(self.makeaface(pts[3],pts[5],norm))
							be.add_face(self.makeaface(pts[1],pts[4],norm))
						when 3
							be.add_face(self.makeaface(pts[0],pts[3],norm))
							be.add_face(self.makeaface(pts[3],pts[4],norm))
							be.add_face(self.makeaface(pts[4],pts[7],norm))
							be.add_face(self.makeaface(pts[1],pts[6],norm))
							be.add_face(self.makeaface(pts[2],pts[5],norm))
						when 4
							be.add_face(self.makeaface(pts[0],pts[4],norm))
							be.add_face(self.makeaface(pts[4],pts[5],norm))
							be.add_face(self.makeaface(pts[5],pts[9],norm))
							be.add_face(self.makeaface(pts[1],pts[8],norm))
							be.add_face(self.makeaface(pts[2],pts[7],norm))
							be.add_face(self.makeaface(pts[3],pts[6],norm))
					end
					pts.each{|p| p.transform! tr}
				end
				ci=@ent.add_instance(@mod.definitions[name],pts[0])
				ci.erase!
			end
			cmp = @mod.definitions[name]
			ctr=face.bounds.center
			diag=face.bounds.diagonal*1.5
			del=dx*2;ny=nx=(diag/del).ceil;md=1e9;cnt=0;max=nx*ny
			org=ctr.offset(@v1,-(del*(nx/2))).offset(@v2,-(del*(ny/2)));
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			for i in 0..ny
				p0=org.offset(@v2,del*i)
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"BasketWeave Grid")
					pt=p0.offset(@v1,del*j)
					(d=@cor.distance(pt);(cpt=pt;md=d) if md>d) if @spt=="Corner" && i>0
					ci=tge.add_instance(cmp,Geom::Transformation.axes(pt,@v1,@v2,@norm))
				end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		##################################################
		#	Create HopScotch1 pattern on selected face
		##################################################
		#	
		def hopscotch(face,dx,dy)
			hx=dx/2.0;hy=dy/2.0;
			name="HS1-#{dx.to_l}x#{dy.to_l}"
			cmp=@mod.definitions[name];
			unless cmp
				p0=Geom::Point3d.new(); v1=[1,0,0]; v2=[0,1,0]; norm=[0,0,1]
				cmp=@mod.definitions.add(name);cpe=cmp.entities
				p1=p0.offset(v2,dy);cpe.add_face(self.makeaface(p0,p1,norm))
				p2=p1.offset(v1,dx);cpe.add_face(self.makeaface(p1,p2,norm))
				p3=p2.offset(v1,hx);cpe.add_face(self.makeaface(p2,p3,norm))
				p4=p3.offset(v2,-hy);cpe.add_face(self.makeaface(p3,p4,norm))
				p5=p4.offset(v1,-hx);cpe.add_face(self.makeaface(p4,p5,norm))
				p6=p2.offset(v2,-dy);cpe.add_face(self.makeaface(p2,p6,norm))
				cpe.add_face(self.makeaface(p6,p0,@norm))
				ci=@ent.add_instance(cmp,p0);ci.erase!
			end
			ctr=face.bounds.center; dxx=dx+dx+hx
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			nx=(face.bounds.diagonal*1.2/dxx).ceil;ny=(face.bounds.diagonal*1.2/hy).ceil
			pt0=ctr.offset(@v1,-(dxx*(nx/2))).offset(@v2,-(hy*(ny/2)))
			cnt=0; max=nx*ny; md=1e9;pt=pt0.clone;
			for i in 0..ny
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"Hopscotch Grid")
					ci=tge.add_instance(cmp,Geom::Transformation.axes(pt,@v1,@v2,@norm))
					pt.offset!(@v1,dxx)
					(d=@cor.distance(pt);(cpt=pt.clone;md=d) if md>d) if @spt=="Corner" && i>0
				end
				case i%5
					when 0 then pt=pt0.offset(@v1,-dx).offset(@v2,hy);#v01
					when 1 then pt=pt0.offset(@v1,hx).offset(@v2,dy);#v02
					when 2 then pt=pt0.offset(@v1,-hx).offset(@v2,dy+hy);#v03
					when 3 then pt=pt0.offset(@v1,dx).offset(@v2,dy*2);#v04
					when 4 then pt=pt0.offset(@v2,dy*2+hy);	pt0.offset!(@v2,dy*2+hy);#v05
				end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		#######################################################
		#		Create HopScotch2 Pattern on selected face
		#######################################################
		#
		def hopscotch2(face,dx,dy)
			hx=dx/2.0;hy=dy/2.0;p0=Geom::Point3d.new();
			cpd = @mod.definitions;cid = "HS2-#{dx.to_l}x#{dy.to_l}"; cmp = cpd[cid]
			unless cmp
				cmp = cpd.add(cid);xa=[1,0,0];ya=[0,1,0];za=[0,0,1];
				p1=p0.offset(ya,dy);cmp.entities.add_face(self.makeaface(p0,p1,za))
				p2=p1.offset(xa,dx);cmp.entities.add_face(self.makeaface(p1,p2,za))
				p3=p2.offset(xa,hx);cmp.entities.add_face(self.makeaface(p2,p3,za))
				p4=p3.offset(ya,-hy);cmp.entities.add_face(self.makeaface(p3,p4,za))
				p5=p4.offset(ya,-hy);cmp.entities.add_face(self.makeaface(p4,p5,za))
				p6=p0.offset(xa,dx);p7=p6.offset(ya,hy)
				cmp.entities.add_face(self.makeaface(p5,p0,za))
				cmp.entities.add_face(self.makeaface(p6,p2,za))
				cmp.entities.add_face(self.makeaface(p7,p4,za))
				ci=@ent.add_instance(cmp,p0); ci.erase!
			end
			delx=dx+hx; diag=face.bounds.diagonal*1.2; ctr=face.bounds.center
			nx=(diag/delx).ceil;ny=(diag/dy).ceil
			pt0=ctr.offset(@v1,-(delx*(nx/2+1))).offset(@v2,-(dy*(ny/2+1)))
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9; p0=pt0.clone
			for i in 0..ny
				p0=pt0.offset(@v2,dy*i)
				p0.offset!(@v1,-hx) if i%2==1
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"No Name Grid")
					tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					(d=@cor.distance(p0);(cpt=p0.clone;md=d) if md>d) if @spt=="Corner" && j>0
					p0.offset!(@v1,delx)
				end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		#######################################################
		#		Create HopScotch3 Pattern on selected face
		#######################################################
		#
		def hopscotch3(face)
			cid="HS3-#{@GX}X#{@GY}"; cmp = @mod.definitions[cid]
			unless cmp
				cmp = @mod.definitions.add(cid);cde=cmp.entities; norm=[0,0,1]
				p0=[0.0,0.0,0.0];p1=[8.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[0.0,24.0,0.0];p1=[0.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[4.0,4.0,0.0];p1=[4.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[4.0,8.0,0.0];p1=[0.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[4.0,4.0,0.0];p1=[0.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,16.0,0.0];p1=[12.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,20.0,0.0];p1=[16.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,24.0,0.0];p1=[8.0,20.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,8.0,0.0];p1=[20.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,24.0,0.0];p1=[16.0,20.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[20.0,8.0,0.0];p1=[20.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,8.0,0.0];p1=[16.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[20.0,0.0,0.0];p1=[24.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,12.0,0.0];p1=[16.0,12.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,16.0,0.0];p1=[4.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[20.0,8.0,0.0];p1=[24.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[0.0,16.0,0.0];p1=[0.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,4.0,0.0];p1=[12.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,16.0,0.0];p1=[16.0,12.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,12.0,0.0];p1=[16.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,12.0,0.0];p1=[12.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,20.0,0.0];p1=[24.0,20.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,8.0,0.0];p1=[12.0,12.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,4.0,0.0];p1=[12.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[16.0,4.0,0.0];p1=[20.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,0.0,0.0];p1=[20.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,20.0,0.0];p1=[4.0,20.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[0.0,8.0,0.0];p1=[0.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[20.0,4.0,0.0];p1=[20.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,16.0,0.0];p1=[16.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,4.0,0.0];p1=[12.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[12.0,8.0,0.0];p1=[8.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,20.0,0.0];p1=[8.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,0.0,0.0];p1=[12.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,4.0,0.0];p1=[8.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,8.0,0.0];p1=[4.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[0.0,4.0,0.0];p1=[0.0,0.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,4.0,0.0];p1=[4.0,4.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[8.0,4.0,0.0];p1=[8.0,8.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[4.0,16.0,0.0];p1=[0.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[4.0,20.0,0.0];p1=[4.0,16.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				p0=[4.0,20.0,0.0];p1=[4.0,24.0,0.0];cde.add_face(self.makeaface(p0,p1,norm))
				unless @GX==24.0 && @GY==24.0
					xscl=@GX/24.0; yscl=@GY/24.0; zscl=1.0
					trs=Geom::Transformation.scaling(xscl,yscl,zscl)
					cde.transform_entities(trs,cde.to_a)
				end
			end
			dx = @GX; dy = @GY
			diag=face.bounds.diagonal*1.2;ctr=face.bounds.center
			nx=[(diag/dx).ceil,5].max;ny=[(diag/dy).ceil,5].max
			org=ctr.offset(@v1,-(dx*(nx/2))).offset(@v2,-(dy*(ny/2)));
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9;
			for i in 0...ny
				pt=org.offset(@v2,dy*i)
				 for j in 0...nx
					cnt += 1; self.progress_bar(cnt,max,"Irregular Polygon Grid")
					(d=@cor.distance(pt);(cpt=pt.clone;md=d) if md>d) if @spt=="Corner" && j>0
					ci=tge.add_instance(cmp,Geom::Transformation.axes(pt,@v1,@v2,@norm))
					pt.offset!(@v1,dx)
				 end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		#######################################################
		#		Create HopScotch4 Pattern on selected face
		#######################################################
		#
		def hopscotch4(face,dx,dy)
			cid="HS4-#{@GX}x#{@GY}"
			cmp=@mod.definitions[cid]
			unless cmp
				cmp=@mod.definitions.add(cid);cde=cmp.entities;	hx=dx/2;hy=dy/2
				vx=Geom::Vector3d.new(1,0,0);vy=Geom::Vector3d.new(0,1,0);
				vz=Geom::Vector3d.new(0,0,1); p0=Geom::Point3d.new(-hx,0,0);
				p1=p0.offset(vx,hx);cde.add_face(self.makeaface(p0,p1,vz))
				p2=p1.offset(vx,dx);cde.add_face(self.makeaface(p1,p2,vz))
				p3=p2.offset(vx,dx);cde.add_face(self.makeaface(p2,p3,vz))
				p4=p3.offset(vy,-hy);cde.add_face(self.makeaface(p3,p4,vz))
				p5=p1.offset(vy,hy);cde.add_face(self.makeaface(p1,p5,vz))
				p6=p5.offset(vx,-hx);cde.add_face(self.makeaface(p5,p6,vz))
				p7=p5.offset(vy,hy);cde.add_face(self.makeaface(p5,p7,vz))
				p8=p2.offset(vy,hy);cde.add_face(self.makeaface(p2,p8,vz))
				p9=p8.offset(vy,hy);cde.add_face(self.makeaface(p8,p9,vz))
				p10=p8.offset(vx,dx);cde.add_face(self.makeaface(p8,p10,vz));cde.add_face(self.makeaface(p10,p3,vz))
				p11=p10.offset(vx,dx);cde.add_face(self.makeaface(p10,p11,vz))
				p12=p11.offset(vy,-dy);cde.add_face(self.makeaface(p11,p12,vz))
			end
			diag=face.bounds.diagonal*1.2;ctr=face.bounds.center;dxx=dx*3+hx
			nx=[(diag/dxx).ceil,5].max;ny=[(diag/dy).ceil,5].max
			org=ctr.offset(@v1,-(dxx*(nx/2))).offset(@v2,-(dy*(ny/2)));
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9;p0=org.clone
			for i in 1..ny
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"Irregular Polygon Grid")
					(d=@cor.distance(p0);(cpt=p0.clone;md=d) if md>d) if @spt=="Corner" && j>0
					tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					p0.offset!(@v1,dxx)
				end
				p0=org.offset(@v2,dy*i).offset(@v1,-hx*(i%7));
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		##################################################
		#	Create Hexagon pattern on selected face
		##################################################
		#
		def hexagon(face,side)
			cpd = @mod.definitions
			ang=30.0.degrees; rad=side+@HW/Math.cos(ang);
			cid = "Hex-#{side.to_l}"; cmp = cpd[cid]
			unless cmp
				org = [0,-rad,0];xa=[1,0,0];ya=[0,1,0];za=[0,0,1];
				cmp = cpd.add(cid);ctb=rad*Math.cos(ang);vec=[0,-rad,0]
				hex = @ent.add_ngon org,za,rad,6
				pts = hex.each.collect{|e| e.end.position}
				tr1=Geom::Transformation.rotation(org,za,ang)
				pts.each{|p| p.transform! tr1}
				for i in 0...pts.length
					cmp.entities.add_face(self.makeaface(pts[i-1],pts[i],za))
				end
				hex.each{|e| @ent.erase_entities(e)}
			end
			cos=Math.cos(ang); 
			ctb=rad*cos; c2c=ctb*2.0; r2r=c2c*cos
			xo1=ctb; xo2=ctb*2.0;yo1=rad; 
			ctr=face.bounds.center;diag=face.bounds.diagonal*1.2
			nx=(diag/c2c).ceil;ny=(diag/r2r).ceil;
			pt0=ctr.offset(@v1,-(c2c*(nx/2))).offset(@v2,-(r2r*(ny/2)))
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9; #puts "nx=#{nx}, ny=#{ny}, max=#{max}"
			for j in 0..ny
				 if j%2==1
					p0=pt0.offset(@v1,xo1).offset(@v2,yo1)
				 else
					p0=pt0.offset(@v1,xo2).offset(@v2,yo1)
				 end
				 tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
				 for i in 0..nx 
					cnt += 1; self.progress_bar(cnt,max,"Hexagon Grid")
					tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					(d=@cor.distance(p0);(cpt=p0.clone;md=d) if md>d) if @spt=="Corner" && j>0
					p0.offset!(@v1,c2c);
				 end 
				 pt0.offset!(@v2,r2r); 
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		##################################################
		#	Create Diamond pattern on selected face
		##################################################
		#
		def diamonds(face,side)
			rad=side+@HW/Math.cos(30.degrees);
			cid="Dia-#{side}";cmp=@mod.definitions[cid]
			unless cmp
				cmp=@mod.definitions.add(cid)
				p0=[0,0,0];za=[0,0,1]
				hex=@ent.add_ngon(p0,za,rad,6)
				pts=hex.each.collect{|e|e.start.position}
				for i in 0...pts.length
					cmp.entities.add_face(self.makeaface(pts[i-1],pts[i],za))
				end
				for i in 0...pts.length
					p1=p0.offset(p0.vector_to(pts[i-1]),p0.distance(pts[i-1])/2)
					cmp.entities.add_face(self.makeaface(p0,p1,za))
					p2=pts[i-1].offset(pts[i-1].vector_to(pts[i]),rad/2.0)
					cmp.entities.add_face(self.makeaface(p1,p2,za))
					p3=pts[i-2].offset(pts[i-2].vector_to(pts[i-1]),rad/2.0)
					cmp.entities.add_face(self.makeaface(p1,p3,za))
				end
				hex.each{|e| @ent.erase_entities(e)}
			end
			ctb=rad*Math.cos(30.degrees); c2c=rad*3.0;r2r=ctb*2.0
			ctr=face.bounds.center;diag=face.bounds.diagonal*1.2
			nx=(diag/c2c).ceil;ny=(diag/r2r).ceil;
			pt0=ctr.offset(@v1,-(c2c*(nx/2))).offset(@v2,-(r2r*(ny/2)))
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9;p0=pt0.clone
			for j in 0..ny
				for i in 0..nx 
					cnt += 1; self.progress_bar(cnt,max,"Hexagon Grid")
					tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					(d=@cor.distance(p0);(cpt=p0.clone;md=d) if md>d) if @spt=="Corner" && j>0
					p1=p0.offset(@v1,c2c/2.0).offset(@v2,-ctb);
					tge.add_instance(cmp,Geom::Transformation.axes(p1,@v1,@v2,@norm))
					(d=@cor.distance(p1);(cpt=p1.clone;md=d) if md>d) if @spt=="Corner" && j>0
					p0.offset!(@v1,c2c);
				end 
				pt0.offset!(@v2,r2r); p0=pt0.clone
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		##################################################
		#	Create Octagon pattern on selected face
		##################################################
		#
		def octagon(face,side)
			half=side/2.0; ang=22.5.degrees; rad=half/Math.sin(ang); rad += @HW/Math.cos(ang)
			@d_area=(side+(Math.tan(ang)*@HW)*2)**2
			cpd = @mod.definitions;cid = "Oct-#{side.to_l}"; cmp = cpd[cid]
			unless cmp
				org = [@GW-half,@GW-half,0];xa=[1,0,0];ya=[0,1,0];za=[0,0,1];
				cmp = cpd.add(cid);
				hex = @ent.add_ngon org,za,rad,8
				pts = hex.each.collect{|e| e.end.position}
				tr1=Geom::Transformation.rotation(org,za,ang)
				pts.each{|p| p.transform! tr1}
				for i in 0...pts.length
					cmp.entities.add_face(self.makeaface(pts[i-1],pts[i],za))
				end
				hex.each{|e| @ent.erase_entities(e)}
			end
			ctb=half/Math.tan(ang); r2r=c2c=ctb*2.0+@GW;
			ctr=face.bounds.center;diag=face.bounds.diagonal*1.2
			nx=(diag/c2c).ceil;ny=(diag/r2r).ceil;
			pt0=ctr.offset(@v1,-(c2c*(nx/2))).offset(@v2,-(r2r*(ny/2)))
			tg=@ent.add_group;tge=tg.entities;tgt=tg.transformation
			p0=pt0.clone; cnt=0; max=nx*ny; md=1e9;
			for j in 0..ny
				 for i in 0..nx 
					cnt += 1; self.progress_bar(cnt,max,"Hexagon Grid")
					tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					(d=@cor.distance(p0);(cpt=p0.clone;md=d) if md>d) if @spt=="Corner" && j>0
					p0.offset!(@v1,c2c);
				 end 
				 p0=pt0.offset(@v2,r2r); pt0.offset!(@v2,r2r);
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		#######################################################
		#		Create Irregular Polygon Pattern on selected face
		#######################################################
		#
		def irpoly(face)
			cpd = @mod.definitions;cid = "IR_POLY"; cmp = cpd[cid]; norm=[0,0,1]
			unless cmp
				cmp = cpd.add(cid);cde=cmp.entities
				p1=[7.7490,20.5455,0.0];	p2=[7.7672,24.2380,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-4.1512,15.8757,0.0];	p2=[0.8687,15.8714,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-10.7304,12.4466,0.0];	p2=[-13.5358,17.0484,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-10.7304,12.4466,0.0];	p2=[-4.1512,15.8757,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-4.1512,15.8757,0.0];	p2=[-1.8039,24.7443,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[2.5539,6.1219,0.0];	p2=[0.0,0.0,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-4.6466,0.0,0.0];	p2=[0.0,0.0,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-10.7453,9.4268,0.0];	p2=[-10.7304,12.4466,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-4.8812,9.5743,0.0];	p2=[-0.9112,10.0812,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-2.8964,32.8542,0.0];	p2=[4.9816,32.8542,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-2.8964,32.8542,0.0];	p2=[-5.1694,26.5064,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-5.1694,26.5064,0.0];	p2=[-10.9819,23.1703,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-10.9819,23.1703,0.0];	p2=[-13.5358,17.0484,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[7.7721,25.2326,0.0];	p2=[7.7870,28.2525,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[4.9816,32.8542,0.0];	p2=[7.7870,28.2525,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-0.9112,10.0812,0.0];	p2=[0.8687,15.8714,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-5.1694,26.5064,0.0];	p2=[-1.8039,24.7443,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-1.8039,24.7443,0.0];	p2=[7.7672,24.2380,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[7.7672,24.2380,0.0];	p2=[7.7721,25.2326,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[10.6395,15.8058,0.0];	p2=[8.3664,9.4580,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[10.6395,15.8058,0.0];	p2=[7.7490,20.5455,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-0.9112,10.0812,0.0];	p2=[2.5539,6.1219,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[8.3664,9.4580,0.0];	p2=[2.5539,6.1219,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-7.8779,-0.0,0.0];	p2=[-4.6466,0.0,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-4.6466,0.0,0.0];	p2=[-4.8812,9.5743,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-10.7453,9.4268,0.0];	p2=[-4.8812,9.5743,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[0.8687,15.8714,0.0];	p2=[7.7490,20.5455,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-10.7684,4.7396,0.0];	p2=[-10.7453,9.4268,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
				p1=[-7.8779,-0.0,0.0];	p2=[-10.7684,4.7396,0.0];	cde.add_face(self.makeaface(p1,p2,norm))
			end
			dx1=13.5360;dy1=17.0484;dx2=32.0519;dy2=-1.2427; dy3=32.8542
			diag=face.bounds.diagonal*1.2;ctr=face.bounds.center
			nx=[(diag/dx2).ceil,5].max;ny=[(diag/dy3).ceil,5].max
			org=ctr.offset(@v1,-(dx2*(nx/2))).offset(@v2,-(dy3*(ny/2-1)));
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9; pt=org.clone
			for i in 0...ny
				 for j in 0...nx
					cnt += 1; self.progress_bar(cnt,max,"Irregular Polygon Grid")
					(d=@cor.distance(pt);(cpt=pt.clone;md=d) if md>d) if @spt=="Corner" && j>0
					tge.add_instance(cmp,Geom::Transformation.axes(pt,@v1,@v2,@norm))
					p0=pt.offset(@v1,dx1).offset(@v2,-dy1)
					tge.add_instance(cmp,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					p0=pt.offset(@v1,dx2).offset(@v2,dy2); pt=p0
				 end
				 if i%2==0
					pt=org.offset(@v2,dy1).offset(@v1,-13.5356);org=pt
				 else
					pt=org.offset(@v2,dy3).offset(@v1,4.9816);org=pt
				 end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		#######################################################
		#		Create Wedge Pattern on selected face
		#######################################################
		#
		def wedge(face,dx,dy)
			cid="Wedge-#{dx.to_l}x#{dy.to_l}"
			cmp=@mod.definitions[cid]
			unless cmp
				cmp=@mod.definitions.add(cid);cde=cmp.entities
				p0=Geom::Point3d.new(); v1=[1,0,0];v2=[0,1,0];norm=[0,0,1]
				p1=p0.offset(v1,-dx/2).offset(v2,dy/4);cde.add_face(self.makeaface(p0,p1,norm))
				p2=p1.offset(v2,dy/2);cde.add_face(self.makeaface(p1,p2,norm))
				p3=p2.offset(v2,dy/4).offset(v1,dx/2);cde.add_face(self.makeaface(p2,p3,norm))
				p4=p3.offset(v1,dx/2).offset(v2,-dy/4);cde.add_face(self.makeaface(p3,p4,norm))
				p5=p4.offset(v2,-dy/2);cde.add_face(self.makeaface(p4,p5,norm))
				cde.add_face(self.makeaface(p5,p0,norm))
			end
			diag=face.bounds.diagonal*1.2;ctr=face.bounds.center
			nx=[(diag/dx).ceil,5].max;ny=[(diag/dy).ceil,5].max
			org=ctr.offset(@v1,-(dx*(nx/2))).offset(@v2,-(dy*(ny/2)));
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9; p0=org.clone
			for i in 0..ny
				pt=p0.offset(@v2,dy*0.75*i)
				pt.offset!(@v1,dx/2) if i%2==1
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"Wedge Grid")
					(d=@cor.distance(pt);(cpt=pt.clone;md=d) if md>d) if @spt=="Corner" && j>0
					tge.add_instance(cmp,Geom::Transformation.axes(pt,@v1,@v2,@norm))
					pt.offset!(@v1,dx)
				end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		#######################################################
		#		Create I_Block Pattern on selected face
		#######################################################
		#
		def i_block(face,dx,dy)
			cid="I_Block-#{@GX}x#{@GY}"
			cpd=@mod.definitions[cid]
			unless cpd
				cpd=@mod.definitions.add(cid);cde=cpd.entities
				p0=[0,0,0];v1=[-1,0,0];v2=[0,1,0]; v3=[0,0,1];
				d1=dx*0.1875;d2=dx*0.125;d3=dx-((d1+d2)*2);dy=[dy,(d2+@GW)*2].max
				p1=p0.offset(v1,d1);cde.add_face(self.makeaface(p0,p1,v3));p0=p1
				p1=p0.offset(v1,d2).offset(v2,d2);cde.add_face(self.makeaface(p0,p1,v3));p0=p1
				p1=p0.offset(v1,d3);cde.add_face(self.makeaface(p0,p1,v3));p0=p1
				p1=p0.offset(v1,d2).offset(v2,-d2);cde.add_face(self.makeaface(p0,p1,v3));p0=p1
				p1=p0.offset(v1,d1);cde.add_face(self.makeaface(p0,p1,v3));p0=p1
				p1=p0.offset(v2,dy);cde.add_face(self.makeaface(p0,p1,v3));p0=p1
			end
			diag=face.bounds.diagonal*1.2; ctr=face.bounds.center
			nx=(diag/dx).ceil;dy-=dx*0.125;ny=(diag/dy).ceil
			org=ctr.offset(@v1,-(dx*(nx/2))).offset(@v2,-(dy*(ny/2)))
			tg=@ent.add_group; tge=tg.entities; tgt=tg.transformation
			cnt=0; max=nx*ny; md=1e9
			for i in 0..ny
				p0=org.offset(@v2,dy*i);p0.offset!(@v1,dx/2.0) if i%2==1
				for j in 0..nx
					cnt += 1; self.progress_bar(cnt,max,"I_Block Grid")
					(d=@cor.distance(p0);(cpt=p0.clone;md=d) if md>d) if @spt=="Corner" && j>0
					tge.add_instance(cpd,Geom::Transformation.axes(p0,@v1,@v2,@norm))
					p0.offset!(@v1,dx)
				end
			end
			fg=@ent.add_group face;
			(tr = Geom::Transformation.new(cpt.vector_to(@cor)); 
			tge.transform_entities(tr,tge.to_a )) if @spt=="Corner"
			@egrp=@ent.add_group;@ege=@egrp.entities;@egt=@egrp.transformation
			Sketchup::set_status_text "Intersecting Grid and Face"
			tge.intersect_with true,tgt,@ege,@egt,false,fg
			fg.explode; tg.erase! unless $sdm_debug;
		end
		#
		########################################################
		#	Common sub-routines
		########################################################
		#	
		def paint_it(f)
			if @app=="Current"
				f.material = @mod.materials.current		
				f.material.texture.size = @txs if f.material && f.material.texture && @txs && @txs != 0
				self.ate(f)
			elsif @app=="Rand_Clr"
				name = @colors[rand(@colors.length)]
				unless @mod.materials[name]
					mat = @mod.materials.add(name) 
					mat.color = name
				end
				f.material = @mod.materials[name]
			elsif @app=="Rand_Tex"
				i=rand(@textures.length);name = @textures[i]
				unless @mod.materials[name]
					mat = @mod.materials.add(name)
					mat.texture = @images[i]
					mat.texture.size = @txs if @txs && @txs != 0
				end
				f.material = @mod.materials[name]
				self.ate(f)
			end
		end
		
		def ate(f) #Align Texture to Edge
			if @ate=="Yes" && f.material && f.material.texture
				case @@opt
					when "Tweed","BsktWv"
						l=n=0;
						f.outer_loop.edges.each_with_index{|e,i| d=e.length;(n=i;l=d) if d>l}
						vector = f.edges[n].line[1]	# Align to longest bounding edge
					when "HpScth1","HpScth2","HpScth4"
						n=0; @GX>=@GY ? vector=@v1 : vector=@v2;
					when 'HpScth3',"Hbone"
						edges=f.outer_loop.edges
						j=edges.length-1;l=d=0
						for i in 0..j
							d+=edges[i].length;
							unless edges[i].line[1].parallel?(edges[i-j].line[1])
								(l=d;n=i;d=0)if l<d
							end
						end
						vector=edges[n].line[1]
					else
						n=0;vector = @v1	# Align to longest face edge
				end
				return unless f.normal.perpendicular? vector		# Skip if vector isn't in the plane of the face
				achorPoint = f.edges[n].line[0]					# Define point to rotate around
				textureWidth = f.material.texture.width
				vector.length = textureWidth					# Change vector's length to materials width
				points = [achorPoint, [0,0,0], [achorPoint[0]+vector[0],achorPoint[1]+vector[1],achorPoint[2]+vector[2]], [1,0,0]]	# Reposition material
				f.position_material(f.material, points, true)
			end
		end
		
		def wig(f)#Random Texture Translation
			if f.material && f.material.texture
				tw = Sketchup.create_texture_writer	# Create uv helper to get current material position
				uvh = f.get_UVHelper true, false, tw; pointPairs = []; #puts "rtt"
				vector = f.edges[0].line[1]	# Get a vector in the face's plane
				vector.length = rand(f.material.texture.height+f.material.texture.width)	# Set random length (between 0 and materials height + width)
				trans = Geom::Transformation.rotation f.outer_loop.vertices[0].position, f.normal, rand(360).degrees	# Rotate vector randomly in plane
				vector.transform! trans; trans = Geom::Transformation.translation vector		# Create translation, move point by vector
				(0..1).each do |j|									# Loop some points around face
					point3d = f.outer_loop.vertices[j].position		#  Select a 3d point
					point3dRotated = point3d.transform(trans)		#  Move 3d point
					pointPairs << point3dRotated					#  Save model's 3d point to array
					point2d = uvh.get_front_UVQ(point3d)
					pointPairs << point2d							#  Save material's corresponding 2d point to array
				end#each
				f.position_material(f.material, pointPairs, true)	#Set material position (pair up model 3d points with texture 2d point)
			end
		end
		
		def wag(f)#Random Texture Rotation
			if f.material && f.material.texture
				tw = Sketchup.create_texture_writer					# Create uv helper to get current material position
				uvh = f.get_UVHelper true, false, tw;
				angle=90*rand(4) if @rtr=="90"; angle=180*rand(2) if @rtr=="180"; angle=rand(360) if @rtr=="Rand"
				trans = Geom::Transformation.rotation f.outer_loop.vertices[0].position, f.normal, angle.degrees	#Define rotation
				pointPairs = []; #puts "rtr angle=#{angle}"
				(0..1).each do |j|									# Loop some points around face
					point3d = f.outer_loop.vertices[j].position		#  Selet a 3d point
					point3dRotated = point3d.transform(trans)		#  Rotate 3d pont
					pointPairs << point3dRotated					#  Save model's 3d point to array
					point2d = uvh.get_front_UVQ(point3d)
					pointPairs << point2d							#  Save material's corresponding 2d point to array
				end#each
				f.position_material(f.material, pointPairs, true)	#Set material position (pair up model 3d points with texture 2d point)
			end
		end
		
		def wob(f,d)#Random Face Rotation
			i = rand(2); axis = [@v1,@v2][i];
			while d<@rin || d>@rix
				d = rand*@GD
			end
			case @@opt
				when "Brick","Tile","Wood"
					angle=Math.atan(d/[@GY,@GX][i])*(rand<=>0.5)
				else
					angle=Math.atan(d/(([[f.bounds.height,f.bounds.depth].max,f.bounds.width].max)/2))*(rand<=>0.5)
			end
			tr=Geom::Transformation.rotation(f.bounds.center,axis,angle)
			@fge.transform_entities(tr,f)
		end
		
		def bev(f,d)#Add Bevel to Face Edge
			b=self.g_offset(f,d)
			if b
				v=b.normal;v.length=d
				tr=Geom::Transformation.translation(v)
				@fge.transform_entities(tr,b)
			end
		end
		
		def edge_to_close(f,p)
			return true if p[0].distance(p[1]) <= @GW
			for loop in f.loops
				loop.edges.each{|e| 
					if e.line[1].parallel?(p[0].vector_to(p[1]))
						for i in 0..1
							pp=p[i].project_to_line(e.line)
							if e.bounds.contains?(pp)
								if p[i].distance(pp) <= @GW
									return true
								end
							end
						end
					end
				}
			end
			return false
		end
	
		def g_offset(face,dist)
			return nil unless (dist.class==Fixnum || dist.class==Float || dist.class==Length)
			return nil if (@@opt != "I_Block" && !self.ctr_to_edge(face));
			@c_pts=face.outer_loop.vertices.collect{|v|v.position};
			unless dist==0
				edges=face.outer_loop.edges;last=edges.length-1
				0.upto(last) do |i|
					unless edges[i].length > @GW
						if edges[i].line[1].perpendicular?(edges[i-1].line[1])
							if edges[i].line[1].perpendicular?(edges[i-last].line[1])
								@c_pts -= [edges[i].start,edges[i].end]; #remove short edge between square corners
							end
						end
					end
				end
				last = @c_pts.length-1;@o_pts = []
				0.upto(last) do |a|
					 vec1 = (@c_pts[a]-@c_pts[a-last]).normalize
					 vec2 = (@c_pts[a]-@c_pts[a-1]).normalize
					 if vec1.parallel? vec2
						ctr = face.bounds.center; 
						poe = ctr.project_to_line([@c_pts[a],vec1])
						vec3 = poe.vector_to(ctr); ang = 90.degrees
					 else
						vec3=(vec1+vec2).normalize
						ang = vec1.angle_between(vec2)/2;
					 end
					 vec3.length = -dist/Math::sin(ang);
					 t = Geom::Transformation.new(vec3)
					 if face.classify_point(@c_pts[a].transform(t))==16
						t = Geom::Transformation.new(vec3.reverse);
					 end
					 @o_pts << @c_pts[a].transform(t)
				end
				(@o_pts.length > 2) ? (@fge.add_face(@o_pts)) : (return nil)
			else
				@fge.add_face(@c_pts)
			end
			
		end
		
		def progress_bar(cnt,max,opt)
			pct = (cnt*100)/max; pct=[pct,100].min; @pb = "|"*pct
			Sketchup::set_status_text(@pb + " #{pct}% of #{opt} done.")
		end
	
		def makeaface(p1,p2,fn)
			pts=[];
			pts<<p1.offset(fn, 1)
			pts<<p2.offset(fn, 1)
			pts<<p2.offset(fn,-1)
			pts<<p1.offset(fn,-1)
		end
		
		def ctr_to_edge(f)
			edges=f.edges; c=self.calc_centroid(f);
			edges.each{|e| return false if c.distance_to_line(e.line) <= @HW}
			return true
		end
		
		def calc_centroid(f)
			tx=0.0;ty=0.0;tz=0.0;
			p=f.outer_loop.vertices.collect{|v|v.position}
			p.each{|v| tx+=v.x;ty+=v.y;tz+=v.z}
			ax=tx/p.length;ay=ty/p.length;az=tz/p.length
			c=Geom::Point3d.new(ax,ay,az);#ent.add_cpoint(c)
			area = 0.0;cx = 0.0;cy = 0.0;cz = 0.0;
			for i in 0...p.length
				areat = (p[i].distance(p[i-1])*(c.distance_to_line([p[i],p[i].vector_to(p[i-1])])))/2.0
				area = area + areat;
				cx = cx + areat * ( p[i].x + p[i-1].x + c.x ) / 3.0;
				cy = cy + areat * ( p[i].y + p[i-1].y + c.y ) / 3.0;
				cz = cz + areat * ( p[i].z + p[i-1].z + c.z ) / 3.0;
			end
			cx = cx / area;cy = cy / area;cz = cz / area;
			Geom::Point3d.new(cx,cy,cz)
		end
	end
	
end
