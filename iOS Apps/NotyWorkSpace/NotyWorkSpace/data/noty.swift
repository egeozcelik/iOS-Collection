import Foundation
import UIKit

class Noty {
    var id:String
    var author: String
    var lecture: String
    var subject: String
    var datePosted: String
    var images: [String]
    var pageCount: String
    
    init(id:String, author: String, lecture: String, subject: String, datePosted: String, images: [String], pageCount: String) {
        self.id = id
        self.author = author
        self.lecture = lecture
        self.subject = subject
        self.datePosted = datePosted
        self.images = images
        self.pageCount = pageCount
    }
}
