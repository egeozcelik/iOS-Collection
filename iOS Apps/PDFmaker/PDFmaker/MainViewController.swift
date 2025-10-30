import UIKit

class MainViewController: UIViewController, ViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func sharePDF(_ sender: Any) {
        // Storyboard'dan ViewController'ı yükle
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let pdfVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            
            // ViewController'ın view'ını yükle
            _ = pdfVC.view
            
            // Delegate'i ayarla
            pdfVC.delegate = self
            
            // PDF paylaşımını tetikle
            pdfVC.triggerPDFShare()
        }
    }

    // Delegate fonksiyonu (UIActivityViewController ile paylaşımı başlatır)
    func sharePDF() {
        let pdfFilename = ViewController().getDocumentsDirectory().appendingPathComponent("viewAsPDF.pdf")
        let activityViewController = UIActivityViewController(activityItems: [pdfFilename], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}
