import CallKit

class CallEventsMonitor:NSObject, CXCallObserverDelegate {

    private let appDelegate: AppDelegate
    var callObserver: CXCallObserver? = nil
    private var originalRootVc: UIViewController?

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        self.originalRootVc = appDelegate.window?.rootViewController
        super.init()
    }

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
            if call.isOnHold {
                VialerLogInfo("Pausing call uuid \(call.uuid).")
            } else {
                VialerLogInfo("Dialing to call uuid \(call.uuid).")
            }
        }

        if call.isOutgoing == false && call.hasConnected == false && call.hasEnded == false {
            VialerLogInfo("Incoming call uuid \(call.uuid).")
        }

        if call.hasConnected == true && call.hasEnded == false {
            VialerLogInfo("Connected to call uuid \(call.uuid).")
            let vc = UIStoryboard(name: "SIPCallingStoryboard", bundle: nil)
                    .instantiateViewController(withIdentifier: "SIPCallingViewController") as! SIPCallingViewController

            appDelegate.window?.rootViewController = vc
        }

        if call.hasEnded == true {
            appDelegate.window?.rootViewController = originalRootVc
        }
    }
}
