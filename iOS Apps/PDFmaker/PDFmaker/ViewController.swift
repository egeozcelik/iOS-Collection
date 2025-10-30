import UIKit

protocol ViewControllerDelegate: AnyObject {
    func sharePDF()
}

class ViewController: UIViewController {

    @IBOutlet weak var viewToConvert: UIView!
    weak var delegate: ViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func triggerPDFShare() {
        guard let viewToConvert = viewToConvert else {
            print("viewToConvert yüklenemedi")
            return
        }
        
        // PDF oluşturma
        let pdfData = createPDF(from: viewToConvert)
        
        // Dosya yolunu oluştur
        let pdfFilename = getDocumentsDirectory().appendingPathComponent("viewAsPDF.pdf")
        do {
            try pdfData.write(to: pdfFilename)
        } catch {
            print("PDF yazma hatası: \(error)")
        }
        
        // Delegate üzerinden paylaşımı tetikleme
        delegate?.sharePDF()
    }

    func createPDF(from view: UIView) -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: view.bounds)
        let data = pdfRenderer.pdfData { (context) in
            context.beginPage()
            view.layer.render(in: context.cgContext)
        }
        return data
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
