var tabEx = {}

tabEx.tabsRoot = null;
tabEx.tabContent = null;
tabEx.iframeHight = "100vh"

/**
 * 初始化
 * @param tabsRootId tab标签页面的ul id
 * @param tabContentId 内容root id
 * @param iframeHight 内容相对高度百分比
 */
tabEx.init = function (tabsRootId, tabContentId, contentHight) {
    tabEx.tabsRoot = $("#" + tabsRootId);
    tabEx.tabContent = $("#" + tabContentId);
    tabEx.iframeHight = contentHight == null ? "100vh" : contentHight;
}

//frame加载完成后设置父容器的高度，使iframe页面与父页面无缝对接
tabEx.frameLoad = function (frame) {
    //todo:
}

//添加tab
/**
 * 添加tab
 * @param tabItem = {id,name,url,closable}
 */
tabEx.addTab = function (tabItem) {
    var id = "tab_seed_" + tabItem.id;
    var container = "tab_container_" + tabItem.id;

    $("a[id^=tab_seed_]").removeClass("active");
    $("div[id^=tab_container_]").removeClass("active");

    if (!$('#' + id)[0]) {
        var li_tab = '<li class="nav-item" >';
        li_tab = li_tab + '<a class="nav-link" id="' + id + '" href="#' + container + '" role="tab" data-toggle="tab">' + tabItem.name;
        if (tabItem.closable) {
            li_tab = li_tab + '<i class="text-secondary" data-feather="x" tabclose="' + tabItem.id + '" onclick="tabEx.closeTab(this)" style="position:relative;right:-4px;top:-4px"></i>';
        }
        li_tab = li_tab + '</a>';
        li_tab = li_tab + '</li>';

        var tabpanel = '<div role="tabpanel" class="tab-pane" id="' + container + '" style="width: 100%;">' +
            '<iframe src="' + tabItem.url + '" id="tab_frame_2" style="width:100%; height:' + tabEx.iframeHight + ';position:relative;top:8px" frameborder="0" scrolling="yes" onload="tabEx.frameLoad(this)"></iframe>' +
            '</div>';

        tabEx.tabsRoot.append(li_tab);
        tabEx.tabContent.append(tabpanel);
    }
    $("#" + id).addClass("active");
    $("#" + container).addClass("active");
}

//关闭tab
tabEx.closeTab = function (item) {
    var _id = $(item).attr('tabclose');
    var id = "tab_seed_" + _id;
    var containerId = "tab_container_" + _id;

    if ($('#' + containerId).hasClass('active')) {
        var prevobj = $('#' + id).parent().prev();
        if (prevobj != null) {
            prevobj.children().addClass("active");
            $('#' + containerId).prev().addClass('active');
        }
    }

    $("#" + id).remove();
    $("#" + containerId).remove();
}
