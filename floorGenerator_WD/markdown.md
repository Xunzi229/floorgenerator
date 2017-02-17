
变量含义：
 @@opt 表示的当前的选择的网格类型 
 @@dlg Dialog

 @mod : Sketchup.active_model
 @sel : 当前选择的对象 
 @vue : 当前视图(画布)


 	@spt : 平面周线的交叉点集合
 	@cp  : 当前鼠标点击下去的坐标点
 	@cor : 距离@cp点的最近点的@spt中的点，这个点也是生成网格的起始点
 	@rot ：表示的网格的旋转的度数

 ---
  材质文件
  	@mad  当前选定的材质的路径
  	@mal  当前的材质文件的长度()
  	@maw  当前的材质文件的宽度
 ---

方法:

	grid_data(face): Corner


#生成逻辑
在角开始生成的话： 根据最近的点去生成
