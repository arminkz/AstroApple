import Cocoa
import Foundation
import AppKit

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

func getImage(url:String) {
    let image_url = URL(string: url)!
    var request = URLRequest(url: image_url)
    request.httpMethod = "GET"
    let task = URLSession.shared.downloadTask(with: image_url) { localURL, response, error in
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
            print("oh shit")
        }
        //save file
        do {
            try FileManager.default.copyItem(at: localURL, to: destinationFileUrl)
            //setWallpaper()
        } catch (let writeError) {
            print("Error creating a file \(destinationFileUrl) : \(writeError)")
        }
        setWallpaper()
    }
    task.resume()
}

//get nasa APOD image url
// create get request
let apod_url = URL(string: "https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY")!
var request = URLRequest(url: apod_url)
request.httpMethod = "GET"

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data, error == nil else {
        print(error?.localizedDescription ?? "No data")
        return
    }
    let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
    if let responseJSON = responseJSON as? [String: Any] {
        guard let hdurl = responseJSON["hdurl"] else {
            print("Invalid JSON response")
            return
        }
        getImage(url: hdurl as! String)
    }
}
task.resume()

