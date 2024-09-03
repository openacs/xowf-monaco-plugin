var xowf = xowf || {};
xowf.monaco = xowf.monaco || {};

/* an empty array as docking bay for all editor instances */
xowf.monaco.editors = [];

xowf.monaco.utf8_to_b64 = function(str) {
    return window.btoa(unescape(encodeURIComponent(str)));
}

xowf.monaco.b64_to_utf8 = function(str) {
    return decodeURIComponent(escape(window.atob(str)));
}



