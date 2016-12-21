=begin
module Pubnub
  # Taken from http://www.hiringthing.com/2011/11/04/eventmachine-with-rails.html
  # Thanks Joshua!
  def self.start
    if defined?(PhusionPassenger)
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        # for passenger, we need to avoid orphaned threads

        $my_logger.debug "=> Starting worker process"

        if forked && EM.reactor_running?
          $my_logger.debug "=> EventMachine stopped fork"
          EM.stop
        end
        Thread.new {
          EM.run do
            $my_logger.debug "=> EventMachine started"
          end
        }
        die_gracefully_on_signal
      end
    end
  end

  def self.die_gracefully_on_signal
    $my_logger.debug "=> EventMachine stopped die"
    Signal.trap("INT")  { EM.stop }
    Signal.trap("TERM") { EM.stop }
  end
end
Pubnub.start
=end
