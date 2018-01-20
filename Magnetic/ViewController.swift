import UIKit

func getTransmissionProtectionSpace(host: String?) -> URLProtectionSpace {
    return URLProtectionSpace(
        host: host ?? "",
        port: 443,
        protocol: "https",
        realm: "Transmission Server",
        authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
}

class ViewController: UIViewController {
    @IBOutlet weak var hostname: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UserDefaults.standard.value(forKey: "hostname") as? String

        let urlProtectionSpace = getTransmissionProtectionSpace(host: host)
        let creds = URLCredentialStorage.shared.defaultCredential(for: urlProtectionSpace)

        self.password.isSecureTextEntry = true
        self.hostname.text = host
        self.username.text = creds?.user
        self.password.text = creds?.password

        self.view.addGestureRecognizer(UITapGestureRecognizer(
            target: self.view,
            action: #selector(self.view.endEditing)))
    }

    func torrentWasAdded(resp: TransmissionResponse) {
        print(resp)
    }

    @IBAction func updateHostname() {
        UserDefaults.standard.set(self.hostname.text, forKey: "hostname")
    }

    @IBAction func updateSettings(_ sender: UITextField) {
        let protectionSpace = getTransmissionProtectionSpace(host: self.hostname.text)

        let userCredential = URLCredential(
            user: self.username.text!,
            password: self.password.text!,
            persistence: .permanent)

        URLCredentialStorage.shared.setDefaultCredential(
            userCredential,
            for: protectionSpace)
    }

}
