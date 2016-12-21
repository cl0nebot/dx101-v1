$(function(){
  $( ".accordion" ).accordion({
      header: '> div > h3',
      heightStyle: 'content',
      collapsible: !!1
    });
    /*
    .sortable({
      axis: "y",
      handle: "h3",
      stop: function( event, ui ) {
      // IE doesn't register the blur when sorting
      // so trigger focusout handlers to remove .ui-state-focus
      ui.item.children( "h3" ).triggerHandler( "focusout" );
    }
  });
  */
 $('.markets-accordion').accordion('option', 'active', $('.markets-accordion .group.active').index());
});
