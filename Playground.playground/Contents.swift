import UIKit
import Network
import PlaygroundSupport

extension UIImage {
    class func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1000, height: 1000))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
}


let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 512, height: 128))
imageView.image = UIImage.imageWithColor(color: .red)
imageView.contentMode = .scaleAspectFill


imageView.setImage(URL(string: "https://placehold.it/512x512")!, animation: AnimationOptions(duration: 1, options: .transitionCurlDown)) { success in
}


//PlaygroundPage.current.liveView = imageView

let button = UIButton(frame: CGRect(x: 0, y: 0, width: 512, height: 512))
button.setImage(UIImage.imageWithColor(color: .black), for: .normal)
button.imageView?.contentMode = .scaleAspectFill

button.setImage(URL(string: "https://placehold.it/512")!,  for: .normal, animation: AnimationOptions(duration: 1, options: .transitionCrossDissolve))

button.setImage(URL(string: "https://placehold.it/1024")!,  for: .highlighted)

PlaygroundPage.current.liveView = button
