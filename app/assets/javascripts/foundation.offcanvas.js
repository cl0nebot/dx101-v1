;
(function ($, window, document, undefined) {
    'use strict';
    Foundation.libs.offcanvas = {
        name: 'offcanvas',
        version: '5.0.0',
        settings: {},
        init: function (scope, method, options) {
            this.events();
        },
        events: function () {
            $(this.scope).off('.offcanvas').on('click.fndtn.offcanvas', '.left-off-canvas-toggle', function (e) {
                e.preventDefault();
                $(this).closest('.off-canvas-wrap').toggleClass('move-right hold-canvas');
            }).on('click.fndtn.offcanvas', '.exit-off-canvas', function (e) {
                e.preventDefault();
                $(".off-canvas-wrap").removeClass("move-right");
                setTimeout(function(){
                  $(".off-canvas-wrap").removeClass("hold-canvas");
                },500);
            }).on('click.fndtn.offcanvas', '.right-off-canvas-toggle', function (e) {
                e.preventDefault();
                $(this).closest(".off-canvas-wrap").toggleClass("move-left hold-canvas");
            }).on('click.fndtn.offcanvas', '.exit-off-canvas', function (e) {
                e.preventDefault();
                $(".off-canvas-wrap").removeClass("move-left");
                setTimeout(function(){
                  $(".off-canvas-wrap").removeClass("hold-canvas");
                },500);
            });
        },
        reflow: function () {}
    };
}(jQuery, this, this.document));
