/**
 * Created by chenbin on 18/7/17.
 */
myutl = {}

/*
 * 跨域调用
 * url:地址
 * params：参数
 * success：成功回调，（result, status, xhr）
 * error：失败回调，（jqXHR, textStatus, errorThrown）
 */
myutl.ajaxJSONP = function (url, params, success, error) {
    $.ajax({
            url: url,
            data: params,
            dataType: 'jsonp',
            crossDomain: true,
            // jsonp:"callback",  //Jquery生成验证参数的名称
            success: success,  //成功的回调函数,
            error: error
        }
    );
}

