import CallKit

@available(iOS 10.0, *)
class CallEventsMonitor:NSObject, CXCallObserverDelegate {
    
    var callObserver: CXCallObserver? = nil
    
    func start() {
        if callObserver == nil {
            callObserver = CXCallObserver()
            callObserver!.setDelegate(self, queue: nil)
        }
        VialerLogInfo("Monitoring call events started.")
    }
        
    func stop() {
        callObserver = nil
        VialerLogInfo("Monitoring call events stopped.")
    }

    func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        if call.hasEnded  == true && call.isOutgoing == false ||
            call.hasEnded  == true && call.isOutgoing == true {
            VialerLogInfo("Disconnected from call \(call.uuid).")
        }

        if call.isOutgoing == true && call.hasConnected == false && call.hasEnded == false {
            VialerLogInfo("Dailing to call uuid \(call.uuid).")
        }

        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            VialerLogInfo("Incoming call uuid \(call.uuid).")
        }

        if call.hasConnected == true && call.hasEnded == false {
            VialerLogInfo("Connected to call uuid \(call.uuid).")
        }
    }
}
