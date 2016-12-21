$(function(){
  var form = $('.withdraw-form'),
      submitButton = $('.submit'),
      idsField = $('#ids'),
      allCheckbox = $('.check-all'),
      sectionCheckboxes = $('.check-section'),
      withdrawCheckboxes = $('.withdraw-checkbox'),
      checkAll = function(){
        allCheckbox.prop('checked', !!1);
        sectionCheckboxes.prop('checked', !!1);
        withdrawCheckboxes.prop('checked', !!1);
      },
      uncheckAll = function(){
        allCheckbox.prop('checked', !1);
        sectionCheckboxes.prop('checked', !1);
        withdrawCheckboxes.prop('checked', !1);
      },
      checkSection = function(currency){
        withdrawCheckboxes.filter('[currency="'+currency+'"]').prop('checked', !!1);
      },
      uncheckSection = function(currency){
        withdrawCheckboxes.filter('[currency="'+currency+'"]').prop('checked', !1);
      };

      // Bindings
      form.on('change', '.check-all', function(){
        allCheckbox.is(':checked') ? checkAll() : uncheckAll();
      });

      form.on('change', '.check-section', function(){
        var t = $(this),
            currency = t.attr('currency');
        t.is(':checked') ? checkSection(currency) : uncheckSection(currency);
      });
      
      form.on('click', '.submit', function(){
        idsField.val(_.map(withdrawCheckboxes.filter(':checked'), function(checkbox){
          var checkbox = $(checkbox);
          return checkbox.val();
        }).join(','));
        form.submit();
      });

      uncheckAll();

});
