document.addEventListener("DOMContentLoaded", function() {
    var userLang = navigator.language || navigator.userLanguage;
    if ( location.href.indexOf("/en.html") > -1 ) {
        return;
    }
    if (userLang.indexOf("zh-CN") !== -1 || userLang.indexOf("zh") !== -1) {
        window.location.href = "zh.html";
    }
    // otherwise stay on the current page
});
