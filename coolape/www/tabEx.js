var tabEx = {}

tabEx.tabsRoot = null
tabEx.tabContent = null

tabEx.init = function (tabsRootId, tabContentId) {
    tabEx.tabsRoot = $("#" + tabsRootId)
    tabEx.tabContent = $("#" + tabContentId)
}

//frame加载完成后设置父容器的高度，使iframe页面与父页面无缝对接
tabEx.frameLoad = function (frame) {
    var mainheight = $(frame).contents().find('body').height();
    $(frame).parent().height(mainheight);
}

//添加tab
tabEx.addTab = function (tabItem) { //tabItem = {id,name,url,closable}
    var id = "tab_seed_" + tabItem.id;
    var container = "tab_container_" + tabItem.id;

    // $("li[id^=tab_seed_]").removeClass("active");
    $("a[id^=tab_seed_]").removeClass("active");
    $("div[id^=tab_container_]").removeClass("active");

    if (!$('#' + id)[0]) {
        var li_tab = '<li class="nav-item" id="' + id + '">'
        li_tab = li_tab + '<a class="nav-link" id="' + id + '_a" href="#' + container + '" role="tab" data-toggle="tab">' + tabItem.name;
        if (tabItem.closable) {
            li_tab = li_tab + '<i class="text-secondary" data-feather="x" tabclose="' + id + '" onclick="tabEx.closeTab(this)"></i>';
        }
        li_tab = li_tab + '   </a>'
        li_tab = li_tab + '</li>'

        var tabpanel = '<div role="tabpanel" class="tab-pane" id="' + container + '" style="width: 100%;">' +
            '<iframe src="' + tabItem.url + '" id="tab_frame_2" style="width:100%; height:85vh;position:relative;top:8px" frameborder="0" scrolling="yes" onload="tabEx.frameLoad(this)"></iframe>' +
            '</div>';

        console.log(li_tab)
        tabEx.tabsRoot.append(li_tab);
        tabEx.tabContent.append(tabpanel);
    }
    // $("#" + id).addClass("active");
    $("#" + id + "_a").addClass("active");
    $("#" + container).addClass("active");
}

//关闭tab
tabEx.closeTab = function (item) {
    var val = $(item).attr('tabclose');
    var containerId = "tab_container_" + val.substring(9);

    if ($('#' + containerId).hasClass('active')) {
        $('#' + val).prev().addClass('active');
        $('#' + containerId).prev().addClass('active');
    }

    $("#" + val).remove();
    $("#" + containerId).remove();
}
