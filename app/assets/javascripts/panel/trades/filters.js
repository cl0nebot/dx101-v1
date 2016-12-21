$(function(){
  var balanceCurrenciesForm = $('#balance_currencies_form'),
      balanceCurrenciesSubmit = $('.balance_currencies_submit'),
      marketCurrenciesForm = $('#market_currencies_form'),
      marketCurrenciesSubmit = $('.market_currencies_submit');

      balanceCurrenciesForm.on('submit', function(e){
        e.preventDefault();
        var currencies = [],
            authenticity_token = balanceCurrenciesForm.find('input[name="authenticity_token"]').val();
        balanceCurrenciesSubmit.hide();
        balanceCurrenciesForm.find(':checkbox:checked').each(function(){
          var t = $(this);
          currencies.push(t.attr('name'));
        });
        $.post('/panel/trades/filters.json', {authenticity_token: authenticity_token, filter_type: 'balance_currencies', currencies: currencies}, function(d, status, jqXHR){
          if('error' in d){
            balanceCurrenciesSubmit.show();
            $.jGrowl(d.error, {sticky: !!1, theme: 'jGrowl-notification-error'});
          }
          else{
            $.jGrowl('Filter saved');
            setTimeout(function(){location.reload(!!1)}, 2000);
          }
        });
      });

      marketCurrenciesForm.on('submit', function(e){
        e.preventDefault();
        var currencies = [],
            authenticity_token = marketCurrenciesForm.find('input[name="authenticity_token"]').val();
        marketCurrenciesSubmit.hide();
        marketCurrenciesForm.find(':checkbox:checked').each(function(){
          var t = $(this);
          currencies.push(t.attr('name'));
        });
        $.post('/panel/trades/filters.json', {authenticity_token: authenticity_token, filter_type: 'market_currencies', currencies: currencies}, function(d, status, jqXHR){
          if('error' in d){
            marketCurrenciesSubmit.show();
            $.jGrowl(d.error, {sticky: !!1, theme: 'jGrowl-notification-error'});
          }
          else{
            $.jGrowl('Filter saved');
            setTimeout(function(){location.reload(!!1)}, 2000);
          }
        });
      });

});
