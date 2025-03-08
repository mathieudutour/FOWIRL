import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

    // Register for background processing task
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "me.dutour.mathieu.fowirl.locationprocessing", using: nil) { task in
      self.handleLocationProcessing(task: task as! BGProcessingTask)
    }

    return true
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    scheduleLocationProcessing()
  }

  func scheduleLocationProcessing() {
    let request = BGProcessingTaskRequest(identifier: "me.dutour.mathieu.fowirl.locationprocessing")
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = false

    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule location processing: \(error)")
    }
  }

  func handleLocationProcessing(task: BGProcessingTask) {
    // Create a task assertion to keep the app running long enough to finish processing
    let processingTask = Task {
      // Perform any pending location processing here

      // Schedule the next background task
      self.scheduleLocationProcessing()
    }

    // Set up a task expiration handler
    task.expirationHandler = {
      processingTask.cancel()
    }

    // When the processing is complete, call task.setTaskCompleted()
    Task {
      await processingTask.value
      task.setTaskCompleted(success: true)
    }
  }
}
