import UIKit
import OnePasswordExtension

func getTransmissionProtectionSpace(host: String?) -> URLProtectionSpace {
    return URLProtectionSpace(
        host: host ?? "",
        port: 443,
        protocol: "https",
        realm: "Transmission Server",
        authenticationMethod: NSURLAuthenticationMethodHTTPBasic)
}

class SettingsField: UITextField {
    var padding = UIEdgeInsetsMake(2, 10, 0, 10)

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.borderStyle = UITextBorderStyle.none
        self.layer.backgroundColor = UIColor(red:0.93, green:0.94, blue:0.94, alpha:1.0).cgColor
        self.layer.cornerRadius = 4
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return UIEdgeInsetsInsetRect(bounds, self.padding)
    }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return self.textRect(forBounds: bounds)
    }
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var rect = self.textRect(forBounds: bounds)
        rect.size.width -= 16
        return rect
    }
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        var rect = super.clearButtonRect(forBounds: bounds)
        rect.origin.x -= self.padding.right - 6
        return rect
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var hostname: SettingsField!
    @IBOutlet weak var username: SettingsField!
    @IBOutlet weak var password: SettingsField!
    @IBOutlet weak var passButton: UIButton!

    @IBOutlet weak var settingsOffset: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UserDefaults.standard.value(forKey: "hostname") as? String

        let urlProtectionSpace = getTransmissionProtectionSpace(host: host)
        let creds = URLCredentialStorage.shared.defaultCredential(for: urlProtectionSpace)

        self.hostname.text = host
        self.username.text = creds?.user
        self.password.text = creds?.password

        self.password.isSecureTextEntry = true

        // TODO: Hide if extension is missing
        let border = CALayer()
        border.backgroundColor = UIColor.white.cgColor
        border.frame = CGRect(x: -2,y: 0, width: 2, height: self.passButton.frame.height)
        self.passButton.layer.addSublayer(border)
        self.passButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        self.password.padding = UIEdgeInsetsMake(2, 10, 0, 10 + self.passButton.frame.width)

        // TODO: Investigate why I have to do this
        self.passButton.setImage(
            UIImage.init(named: "onepassword-button", in: Bundle.init(for: OnePasswordExtension.self), compatibleWith: nil),
            for: UIControlState.normal)

        self.view.addGestureRecognizer(UITapGestureRecognizer(
            target: self.view,
            action: #selector(self.view.endEditing)))

        NotificationCenter.default.addObserver(self,
            selector: #selector(ViewController.keyboardWillChange),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil)

        NotificationCenter.default.addObserver(self,
            selector: #selector(ViewController.keyboardWillChange),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil)
    }

    @objc func keyboardWillChange(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let mult: CGFloat = notification.name == NSNotification.Name.UIKeyboardWillShow ? 1 : -1;
        self.settingsOffset.constant += mult * (keyboardSize.height - 60)

        UIView.animate(withDuration: 0.1) { self.view.layoutIfNeeded() }
    }

    @IBAction func updateHostname() {
        UserDefaults.standard.set(self.hostname.text, forKey: "hostname")
    }

    @IBAction func updateSettings(_ sender: Any?) {
        let protectionSpace = getTransmissionProtectionSpace(host: self.hostname.text)

        let userCredential = URLCredential(
            user: self.username.text!,
            password: self.password.text!,
            persistence: .permanent)

        URLCredentialStorage.shared.setDefaultCredential(
            userCredential,
            for: protectionSpace)
    }

    @IBAction func passwordAutofill(_ sender: UIButton) {
        let pw = OnePasswordExtension.shared()

        var url = URLComponents()
        url.host = self.hostname.text
        url.scheme = "https"

        let urlString = self.hostname.text != "" ? url.string! : "transmission"

        pw.findLogin(forURLString: urlString, for: self, sender: sender) { (loginDictionary, error) in
            guard let loginDictionary = loginDictionary else { return }

            self.username.text = loginDictionary[AppExtensionUsernameKey] as? String
            self.password.text = loginDictionary[AppExtensionPasswordKey] as? String
            self.updateSettings(sender)
        }
    }

    func torrentWasAdded(resp: TransmissionResponse) {
        DispatchQueue.main.async {
            let fb = UINotificationFeedbackGenerator()
            fb.notificationOccurred(.success)
        }
    }
}
