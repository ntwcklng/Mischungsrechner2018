//
//  ViewController.swift
//  Mischungsrechner
//
//  Created by Marvin Mieth on 15.08.18.
//  Copyright © 218 Marvin Mieth. All rights reserved.
//

import UIKit
extension UIView {
    func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = duration
        layer.add(animation, forKey: kCATransitionFade)
    }
}
class ViewController: UIViewController {
    
    @IBOutlet weak var Part1Input: UITextField!
    @IBOutlet weak var Part2Input: UITextField!
    @IBOutlet weak var BottleSize: UITextField!
    @IBOutlet weak var OutputLabel: UILabel!
    
    @IBOutlet weak var ContentView: UIView!
    
    
    //Part Buttons
    @IBOutlet weak var _11: UIButton!
    @IBOutlet weak var _12: UIButton!
    @IBOutlet weak var _14: UIButton!
    @IBOutlet weak var _110: UIButton!
    @IBOutlet weak var _115: UIButton!
    @IBOutlet weak var _1500p: UIButton!
    
    
    
    //Bottle Buttons
    @IBOutlet weak var _100: UIButton!
    @IBOutlet weak var _200: UIButton!
    @IBOutlet weak var _250: UIButton!
    @IBOutlet weak var _473: UIButton!
    @IBOutlet weak var _500: UIButton!
    @IBOutlet weak var _1000: UIButton!
    @IBOutlet weak var _1500: UIButton!
    
    @IBOutlet weak var HeaderLogo: UIImageView!
    
    

    
    
    func calcDil() {
        if let Part1 = Double(Part1Input.text!), let Part2 = Double(Part2Input.text!), let BottleSizeML = Double(BottleSize.text!) {
            let Parts = Double(Part1 + Part2)
            let PartPerMl = BottleSizeML / Parts
            let Part1Output: Double = Part1 * PartPerMl
            let Part2Output: Double = Part2 * PartPerMl
            OutputLabel.fadeTransition(0.4)
            OutputLabel.text = "\(Int(Part1Output.rounded()))ml : \(Int(Part2Output.rounded()))ml"
            print(Parts, PartPerMl, Part1, Part2)
        }
  
        
    }
    @objc  private func buttonClickedBottle(_ sender : UIButton) {
        if let bottle = sender.titleLabel?.text {
            BottleSize.text = bottle
            calcDil()
        }
    }
    @objc private func buttonClickedParts(_ sender : UIButton) {
        if let part1 = sender.titleLabel?.text {
            Part1Input.text = part1.components(separatedBy: ":")[0]
            Part2Input.text = part1.components(separatedBy: ":")[1]
            calcDil()
        }
    }
    
    @IBAction func Part1InputEdited(_ sender: Any) {
        calcDil()
    }
    @IBAction func Part2InputEdited(_ sender: Any) {
        calcDil()
    }
    
    @IBAction func BottleSizeEdited(_ sender: Any) {
        if Int(BottleSize.text!)! < 1000000 {
            calcDil()
        } else {
            let alert = UIAlertController(title: "Ernsthaft?", message: "Deine eingegebene Flaschengröße ist \(Int(BottleSize.text!)!/1000) Liter", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK...", comment: "Default action"), style: .default))
            self.present(alert, animated: true, completion: nil)
        }
        
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        ContentView.layer.masksToBounds = true
        ContentView.layer.cornerRadius = 25
        calcDil()
        
        // Assign Parts Button Actions
        _11.addTarget(self, action: #selector(self.buttonClickedParts), for: .touchUpInside)
        _14.addTarget(self, action: #selector(self.buttonClickedParts), for: .touchUpInside)
        _12.addTarget(self, action: #selector(self.buttonClickedParts), for: .touchUpInside)
        _110.addTarget(self, action: #selector(self.buttonClickedParts), for: .touchUpInside)
        _115.addTarget(self, action: #selector(self.buttonClickedParts), for: .touchUpInside)
        _1500p.addTarget(self, action: #selector(self.buttonClickedParts), for: .touchUpInside)
        
        // Assign Parts Button Actions
        _100.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
        _200.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
        _250.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
        _473.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
        _500.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
        _1000.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
        _1500.addTarget(self, action: #selector(self.buttonClickedBottle), for: .touchUpInside)
    }
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

