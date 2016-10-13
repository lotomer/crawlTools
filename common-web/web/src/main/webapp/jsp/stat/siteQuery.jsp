<%@page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>舆情更新内容查询</title>
<link rel="stylesheet" type="text/css"
	href='css/easyui/themes/${theme}/easyui.css'>
<link rel="stylesheet" type="text/css" href="css/easyui/themes/icon.css">
<link rel="stylesheet" type="text/css" href="css/main.css">
</head>
<body class="easyui-layout">
	<div data-options="region:'north',split:true"
		style="height: 72px;padding:5px 30px;">
		<table>
			<tr>
               <td style="width:65px"><label>站点类型：</label></td>
                <td style="width:140px"><input id="selSiteType" class="easyui-combobox"></input></td>
                <td style="width:65px"><label>站点：</label></td>
                <td style="width:140px"><input id="selSite" class="easyui-combobox"></input></td>
            <!-- </tr>
			<tr>
				<td><label>开始时间：</label></td>
				<td><input id="st" class="easyui-datebox"
					data-options="showSeconds:false"></td>
				<td><label>结束时间：</label></td>
				<td><input id="et" class="easyui-datebox"
					data-options="showSeconds:false"></td> -->
				<td><a href="#" id="btnQuery" class="easyui-linkbutton"
					data-options="iconCls:'icon-search'" style="width: 120px">查询</a></td>
			</tr>
		</table>
	</div>

	<div id="divSiteContent" data-options="region:'center',split:true">
	</div>
</body>
<!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
<!--[if lt IE 9]>
	  <script src="js/echarts/html5shiv.min.js"></script>
	  <script src="js/echarts/respond.min.js"></script>
	<![endif]-->
<script type="text/javascript" src="js/echarts/echarts.js"></script>
<script type="text/javascript" src="js/jquery.min.js"></script>
<script type="text/javascript" src="js/easyui/jquery.easyui.min.js"></script>
<script type="text/javascript"
	src="js/easyui/locale/easyui-lang-zh_CN.js"></script>
<script type="text/javascript" src="js/utils.js"></script>
<script type="text/javascript" src="js/myEcharts.js"></script>
<script type="text/javascript">
	// 面板与内容之间的差值
	var theme = '${theme}', key = '${user.key}',typeId='${typeId}';
	// 页面初始化
	$(function() {
		// 绑定事件
		$('#btnQuery').bind('click', query);
		initCombobox("selSiteType","crawl/selectSiteType.do",function(record){
			if (record.id == '*'){
				initCombobox("selSite","crawl/selectSite.do");
			}else{
				initCombobox("selSite","crawl/selectSite.do?siteTypeId=" + record.id);
			}
		});
		initCombobox("selSite","crawl/selectSite.do");
		//initCombobox("selWords","setting/words/select.do",query,false,"TYPE_ID","TYPE_NAME",typeId != '' ? typeId : undefined);
		//query();
	});
	
	
	/**
	 * 执行查询
	 */
	function query() {
		// 获取查询条件
		var containerId='divSiteContent',
		startTime = "",//$('#st').datetimebox('getValue'), // 开始时间
		endTime = "",//$('#et').datetimebox('getValue'), // 结束时间
		siteTypeId = $('#selSiteType').datetimebox('getValue'), // 站点类型
		siteId = $('#selSite').datetimebox('getValue') // 站点
		;
		var params = {
				key : key,
				startTime : startTime,
				endTime : endTime
			};
		
		if (siteTypeId && '*' != siteTypeId){
			params.siteTypeId = siteTypeId;
		}
		if (siteId && '*' != siteId){
			params.siteId = siteId;
		}
		
		$('#' + containerId).html('');
		showLoading(containerId);
		var url = "crawl/stat/siteQueryDetail.do";
		//for(var name in params){
			//url = url + "&" + name + "=" + encodeURIComponent(params[name]);
		//}
		doQueryDetail(containerId, url,params);
	}

	function doQueryDetail(containerId,url,params){
		
	//}
	//function processDetailData(datas) {
		var divMetric = $('#' + containerId);
		$('#' + containerId).html('');
		//if (!datas) {
		//	return;
		//}
		$('#' + containerId).append('<div id="divMetric" style="width:100%;height:100%"></div>');
		var divMetric = $('#divMetric');
		var pageSize = 15;
		divMetric.datagrid({
			//title:'${title}',
			fitColumns : true,
			rownumbers : true,
			singleSelect : true,
			url: url,
			queryParams: params,
			//data : datas,
			//remoteSort : false,
			idField : "url",
			//sortName : "status",
			//sortOrder : "asc",
			pagination : true,//pageSize < datas.length,
			pageSize : pageSize,
			pageList : getPageList(pageSize),
			columns : [ [ {
				field : 'title',
				title : '标题',
				align : 'left',
				width: 635,
				halign : 'center',
				formatter: function(value,row){
					return '<a href="' + row.url + '" target="_blank" title="' + value + '" style="display:block;overflow:hidden; text-overflow:ellipsis;">' + value + '</a>';
				}
			}, {
				field : 'author',
				title : '作者',
				align : 'center',
				width: 120,
				halign : 'center',
				formatter: function(value,row){
					value = value == undefined? '':value;
					return '<span title="' + value + '" style="display:block;overflow:hidden; text-overflow:ellipsis;">' + value + '</span>';
				}
			}, {
				field : 'crawl_time',
				title : '抓取时间',
				align : 'left',
				halign : 'center'
			}, {
				field : 'publish_time',
				title : '发布时间',
				align : 'left',
				halign : 'center'
			}, {
				field : 'source',
				title : '来源',
				align : 'center',
				width: 120,
				halign : 'center',
				formatter: function(value,row){
					value = value == undefined? '':value;
					return '<span title="' + value + '" style="display:block;overflow:hidden; text-overflow:ellipsis;">' + value + '</span>';
				}
			}, {
				field : 'content',
				title : '内容简要',
				align : 'center',
				width: 300,
				halign : 'center'
			} ] ]
		});//.datagrid('clientPaging');
	}
</script>
</html>
