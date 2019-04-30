import Cocoa
import Foundation
import AppKit


//let activity = NSBackgroundActivityScheduler(identifier: "com.akp.astro")

// Create destination URL
let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first as URL!
let destinationFileUrl = documentsUrl.appendingPathComponent("nasa_apod.jpg")

func setWallpaper() {
    //set image as desktop background
    do {
        //let imgurl = NSURL.fileURL(withPath: destinationFileUrl)
        let workspace = NSWorkspace.shared
        if let screen = NSScreen.main  {
            try workspace.setDesktopImageURL(destinationFileUrl, for: screen, options: [:])
        }
    } catch {
        print(error)
    }
}

func start() {
    
    let semaphore = DispatchSemaphore(value: 0)
    //get nasa APOD image url
    // create get request
    let apod_url = URL(string: "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY")!
    var request = URLRequest(url: apod_url)
    request.httpMethod = "GET"

    print("Contacting NASA API ...")
    
    var pic_url = ""
    let task_geturl = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            //dispatchGroup.leave()
            return
        }
        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
        if let responseJSON = responseJSON as? [String: Any] {
            guard let hdurl = responseJSON["url"] else { //hdurl for HD
                print("Invalid JSON response")
                //dispatchGroup.leave()
                return
            }
            pic_url = hdurl as! String
            semaphore.signal()
        }
        //dispatchGroup.leave()
    }
    task_geturl.resume()
    semaphore.wait()
    
    print("Fetching Image ... (" + pic_url + ")")
    
    let image_url = URL(string: pic_url)!
    let task_download = URLSession.shared.downloadTask(with: image_url) { localURL, response, error in
        guard let localURL = localURL else {
            print("Download Failed")
            return
        }
        print(response?.suggestedFilename ?? image_url.lastPathComponent)
        print("Download Finished")
        //delete file if exists
        do {
            try FileManager.default.removeItem(at: destinationFileUrl)
        } catch {
            print("!")
        }
        //save file
        do {
            try FileManager.default.copyItem(at: localURL, to: destinationFileUrl)
        } catch (let writeError) {
            print("Error creating a file \(destinationFileUrl) : \(writeError)")
        }
        print("Setting Wallpaper ...")
        setWallpaper()
        semaphore.signal()
    }
    task_download.resume()
    semaphore.wait()
}

start()

/*activity.interval = 2
activity.tolerance = 1
activity.schedule() { (completion: NSBackgroundActivityScheduler.CompletionHandler) in
    // Perform the activity

    completion(NSBackgroundActivityScheduler.Result.finished)
}*/
