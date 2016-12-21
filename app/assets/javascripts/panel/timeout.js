$(function(){
  var timeOutTimer = null,
      timeOutWarningTimer = null,
      timeOutInMins = 10,
      timeoutDialog = $('#timeout'),
      timeoutWarningDialog = $('#timeout_warning'),
      pingButton = $('.button-ping'),
      startTimeOutTimer = function(){
        timeOutTimer = setTimeout(function(){
          timeoutWarningDialog.foundation('reveal', 'close');
          timeoutDialog.foundation('reveal', 'open');
        }, 60000*timeOutInMins);
        timeOutWarningTimer = setTimeout(function(){
          timeoutWarningDialog.foundation('reveal', 'open');
        }, 60000*(timeOutInMins-1));
      },
      clearTimeOutTimer = function(){
        clearTimeout(timeOutTimer);
        clearTimeout(timeOutWarningTimer);
      },
      resetTimers = function(){
        clearTimeOutTimer();
        startTimeOutTimer();
      };
      
      timeoutWarningDialog.on('click', '.button-ping', function(e){
        e.preventDefault();
        timeoutWarningDialog.foundation('reveal', 'close');
      });

      timeoutDialog.on('close', function(){
        window.location = '/login';
      });

      timeoutWarningDialog.on('close', function(){
        $.getJSON(pingButton.attr('href')+'.json', function(){
          resetTimers();
        });
      });

      if(env != 'development') startTimeOutTimer();
});
