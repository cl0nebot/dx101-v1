$(function(){
  var layout = $('body').layout({
        north:{
          resizable: !1,
          closable: !1
        },
        west:{
          minSize: 300
        },
        east:{
          minSize: 100
        }
      });
      layout.allowOverflow('north');
});
