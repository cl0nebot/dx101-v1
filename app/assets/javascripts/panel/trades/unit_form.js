$(function(){
  var unitForm = $('#unit_form'),
      submitButton = $('.unit_form_submit'),
      otherAmountContainer = $('.other_amount'),
      amountField = $('#amount'),
      otherAmountField = $('#other_amount'),
      muCost = $('.mu_cost'),
      Order = Backbone.Model.extend({}),
      Form = Backbone.View.extend({
        el: '#unit_form',
        events: {
          'change #amount': 'change_amount',
          'keyup #other_amount': 'change_other_amount',
          'submit': 'submit'
        },
        initialize: function(){
          this.order = new Order({
            amount: 5,
            other_amount: null,
            currency: unitForm.attr('currency'),
            authenticity_token: null
          });
          return this.bind(),
                 this;
        },
        change_amount: function(e){
          var amount = $(e.currentTarget).val();
          return this.order.set('amount', amount),
                 this;
        },
        change_other_amount: function(e){
          var other_amount = $(e.currentTarget).val();
          return this.order.set('other_amount', other_amount),
                 this;
        },
        submit: function(e){
          e.preventDefault();
          submitButton.hide();
          var t = this;
          t.order.set('authenticity_token', t.$el.find('input[name="authenticity_token"]').val());
          var data = t.order.toJSON(),
              cleanData = {
                amount: ((data.other_amount || !1) ? data.other_amount : data.amount),
                currency: data.currency,
                authenticity_token: data.authenticity_token
              };
          if(cleanData.amount > 0){
            $.post('/panel/trades/units.json', cleanData, function(d, status, jqXHR){
              if('error' in d){
                submitButton.show();
                $.jGrowl(d.error, {sticky: !!1, theme: 'jGrowl-notification-error'});
              }
              else{
                $.jGrowl('Success - your order is complete.');
                setTimeout(function(){location.reload(!!1)}, 2000);
              }
            });
          }
          else{
            submitButton.show();
            $.jGrowl('Can not purchase 0 membership units.', {sticky: !!1, theme: 'jGrowl-notification-error'});
          }
        },
        update_cost: function(){
          var otherAmount = this.order.get('other_amount'),
              amount = (((otherAmount || !1) ? otherAmount : this.order.get('amount')) || 0);
          return muCost.html(BigNumber(amount).times(.01).toFixed(8)),
                 this;
        },
        bind: function(){
          return this.bind_change_amount()
                     .bind_change_other_amount(),
                 this;
        },
        bind_change_amount: function(){
          var t = this;
          this.order.on('change:amount', function(model, amount){
            if(amount || !1){
              t.order.set('other_amount', null);
              otherAmountContainer.hide();
            }
            else{
              otherAmountContainer.show();
            }
            amountField.val(amount);
            t.update_cost();
          });
          return this;
        },
        bind_change_other_amount: function(){
          var t = this;
          this.order.on('change:other_amount', function(model, other_amount){
            otherAmountField.val(other_amount);
            t.update_cost();
          });
          return this;
        }
      });

      new Form;

});
