_.templateSettings = {
    interpolate: /\{\{=(.+?)\}\}/g,
    evaluate: /\{\{(.+?)\}\}/g,
};
_.mixin({
  capitalize: function(string) {
    return string.charAt(0).toUpperCase() + string.substring(1).toLowerCase();
  }
});

$(function(){
  $(document).foundation();
  $('time.timeago').timeago();
  $(document).on('click', '[confirm]', function(e){
    e.preventDefault();
    var t = $(this),
        c = confirm(t.attr('confirm'));
    if(c) window.location = t.attr('href');
  });
});
