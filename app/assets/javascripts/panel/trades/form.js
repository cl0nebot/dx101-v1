$(function(){
  var transferTypeButton = $('#transfer_type_button'),
      transferTypeReaction = $('#transfer_type_reaction'),
      tradeTypeButton = $('#trade_type_button'),
      tradeCurrencyButton = $('#trade_currency_button'),
      tradeRateCurrencyButton = $('#trade_rate_currency_button'),
      tradeTypeList = $('#trade_type'),
      tradeCurrencyList = $('#trade_currency'),
      tradeRateCurrencyList = $('#trade_rate_currency'),
      currencyText = $('.trade_currency_text'),
      quantity = $('#trade_quantity'),
      reaction = $('#trade_reaction'),
      limit = $('#limit'),
      stop = $('#stop'),
      fok = $('#trade_fok'),
      ioc = $('#trade_ioc'),
      screens = $('.new_trade_step'),
      tradeScreen = $('.new_trade_step-1'),
      confirmScreen = $('.new_trade_step-2'),
      confirmTmpl = _.template($('#confirmation_template').html()),
      lastPriceData = JSON.parse($('#last_price_data').html()),
      Trade = Backbone.Model.extend({}),
      Form = Backbone.View.extend({
        el: '#new_trade_dialog',
        events: {
          'click #transfer_type_button': 'toggle_transfer_type',
          'click #trade_type > li > a': 'change_trade_type',
          'click #trade_currency > li > a': 'change_trade_currency',
          'click #trade_rate_currency > li > a': 'change_trade_rate_currency',
          'keydown #trade_quantity': 'change_quantity',
          'focusout #trade_quantity': 'change_quantity',
          'keydown #trade_lmt_amount': 'change_lmt_amount',
          'focusout #trade_lmt_amount': 'change_lmt_amount',
          'keydown #trade_stop_amount': 'change_stop_amount',
          'focusout #trade_stop_amount': 'change_stop_amount',
          'click #trade_fok': 'toggle_fok',
          'click #trade_ioc': 'toggle_ioc',
          'click .confirm_cancel': 'confirm_cancel',
          'click .confirm': 'confirm',
          'submit': 'submit'
        },
        initialize: function(){
          return this.init_trade()
                     .bind()
                     .reset_trade(),
                 this;
        },
        init_trade: function(){
          this.trade = new Trade({
            transfer_type: 'buy',
            trade_type: null,
            currency: tradeCurrencyButton.html(),
            rate_currency: tradeRateCurrencyButton.html(),
            quantity: null,
            lmt_amount: null,
            stop_amount: null,
            fok: 0,
            ioc: 0,
            authenticity_token: null
          });
          return this;
        },
        reset_trade: function(){
          this.trade.set('trade_type', 'Market');
          this.trade.set('quantity', '');
          this.trade.set('lmt_amount', '');
          this.trade.set('stop_amount', '');
          this.trade.set('fok', !1);
          this.trade.set('ioc', !1);
          return this;
        },
        toggle_transfer_type: function(e){
          return this.trade.set('transfer_type', (this.trade.get('transfer_type') == 'buy' ? 'sell' : 'buy')),
                 this;
        },
        change_trade_type: function(e){
          var type = $(e.currentTarget).attr('href').substr(1);
          tradeTypeButton.click();
          return this.trade.set('trade_type', type),
                 this;
        },
        change_trade_currency: function(e){
          var currency = $(e.currentTarget).attr('href').substr(1);
          tradeCurrencyButton.click();
          return this.trade.set('currency', currency),
                 this;
        },
        change_trade_rate_currency: function(e){
          var currency = $(e.currentTarget).attr('href').substr(1);
          tradeRateCurrencyButton.click();
          return this.trade.set('rate_currency', currency),
                 this;
        },
        change_quantity: function(e){
          var quantity = $(e.currentTarget).val();
          return this.trade.set('quantity', quantity),
                 this;
        },
        change_lmt_amount: function(e){
          var lmt_amount = $(e.currentTarget).val();
          return this.trade.set('lmt_amount', lmt_amount),
                 this;
        },
        change_stop_amount: function(e){
          var stop_amount = $(e.currentTarget).val();
          return this.trade.set('stop_amount', stop_amount),
                 this;
        },
        toggle_fok: function(){
          return this.trade.set('fok', fok.is(':checked')),
                 this;
        },
        toggle_ioc: function(){
          return this.trade.set('ioc', ioc.is(':checked')),
                 this;
        },
        submit: function(e){
          e.preventDefault();
          return this.to_confirm_screen(),
                 this;
        },
        confirm_cancel: function(e){
          e.preventDefault();
          return this.to_trade_screen(),
                 this;
        },
        to_trade_screen: function(){
          screens.hide();
          tradeScreen.show();
          return this;
        },
        to_confirm_screen: function(){
          var data = _.clone(this.trade.attributes);
          data.last_price = lastPriceData[data.currency.toLowerCase()+'/'+data.rate_currency.toLowerCase()];
          data.price_diff = (!!data.last_price && (data.trade_type == 'Limit' || data.trade_type == 'Stop Limit')) ? new BigNumber(data.lmt_amount).minus(data.last_price).dividedBy(data.last_price).times(100) : null;
          confirmScreen.html(confirmTmpl(data));
          screens.hide();
          confirmScreen.show();
          return this;
        },
        confirm: function(e){
          var t = this,
          confirmButton = $('.button.confirm'),
          confirmCancelButton = $('.button.confirm_cancel');
          confirmButton.hide();
          confirmCancelButton.hide();
          t.trade.set('authenticity_token', t.$el.find('input[name="authenticity_token"]').val());
          var data = t.trade.toJSON();
          $.post('/panel/trades.json', data, function(d, status, jqXHR){
            if('error' in d){
              confirmButton.show();
              confirmCancelButton.show();
              t.to_trade_screen();
              var error = ((d.error == 'No Market') ? 'Please submit a limit trade until we have established a market rate.' : d.error);
              $.jGrowl(error, {sticky: !!1, theme: 'jGrowl-notification-error'});
            }
            else{
              $.jGrowl('Your order has been successfully submitted.');
              //window.trades.unshift(t.trade.clone());
              //t.reset_trade();
              setTimeout(function(){location.reload(!!1)}, 2000);
            }
          });
          return this;
        },
        bind: function(){
          return this.bind_change_transfer_type()
                     .bind_change_trade_type()
                     .bind_change_trade_currency()
                     .bind_change_trade_rate_currency()
                     .bind_change_quantity()
                     .bind_change_lmt_amount()
                     .bind_change_stop_amount()
                     .bind_change_fok()
                     .bind_change_ioc(),
                 this;
        },
        bind_change_transfer_type: function(){
          this.trade.on('change:transfer_type', function(model, trade_type){
            transferTypeButton.toggleClass('buy sell');
            transferTypeReaction.toggleClass('buy sell');
          });
          return this;
        },
        bind_change_trade_type: function(){
          this.trade.on('change:trade_type', function(model, trade_type){
            tradeTypeButton.html(trade_type);
            tradeTypeList.find('.active-item').removeClass('active-item');
            tradeTypeList.find('a[href="#'+trade_type+'"]').parent().addClass('active-item');
            (trade_type == 'Limit' || trade_type == 'Stop Limit') ? limit.show() : limit.hide();
            (trade_type == 'Stop' || trade_type == 'Stop Limit') ? stop.show() : stop.hide();
          });
          return this;
        },
        bind_change_trade_currency: function(){
          this.trade.on('change:currency', function(model, currency){
            tradeCurrencyButton.html(currency);
            tradeCurrencyList.find('.active-item').removeClass('active-item');
            tradeCurrencyList.find('a[href="#'+currency+'"]').parent().addClass('active-item');
            if(currency == model.get('rate_currency')) model.set('rate_currency', model.previous('currency'));
          });
          return this;
        },
        bind_change_trade_rate_currency: function(){
          this.trade.on('change:rate_currency', function(model, rate_currency){
            tradeRateCurrencyButton.html(rate_currency);
            tradeRateCurrencyList.find('.active-item').removeClass('active-item');
            tradeRateCurrencyList.find('a[href="#'+rate_currency+'"]').parent().addClass('active-item');
            currencyText.html(rate_currency);
            if(rate_currency == model.get('currency')) model.set('currency', model.previous('rate_currency'));
          });
          return this;
        },
        bind_change_quantity: function(){
          this.trade.on('change:quantity', function(model, quan){
            quantity.val(quan);
          });
          return this;
        },
        bind_change_lmt_amount: function(){
          this.trade.on('change:lmt_amount', function(model, lmt_amount){
            limit.val(lmt_amount);
          });
          return this;
        },
        bind_change_stop_amount: function(){
          this.trade.on('change:stop_amount', function(model, stop_amount){
            stop.val(stop_amount);
          });
          return this;
        },
        bind_change_fok: function(){
          this.trade.on('change:fok', function(m,v){
            fok.prop('checked', v);
            if(v && m.get('ioc')) m.set('ioc', !1);
          });
          return this;
        },
        bind_change_ioc: function(){
          this.trade.on('change:ioc', function(m,v){
            ioc.prop('checked', v);
            if(v && m.get('fok')) m.set('fok', !1);
          });
          return this;
        }
      });

      new Form;

});
