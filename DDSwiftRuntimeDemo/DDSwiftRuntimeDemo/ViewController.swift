//
//  ViewController.swift
//  DDSwiftRuntimeDemo
//
//  Created by dondong on 2022/2/27.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white;
        // all type
        let typeButton = UIButton(frame:CGRect(x:(self.view.frame.width - 150) * 0.5, y:100, width:150, height:44));
        typeButton.backgroundColor = .darkGray;
        typeButton.setTitle("get all type", for:.normal);
        typeButton.addTarget(self, action:#selector(getAllType), for:.touchUpInside);
        self.view.addSubview(typeButton);
        // class
        let classButton = UIButton(frame:CGRect(x:(self.view.frame.width - 150) * 0.5, y:200, width:150, height:44));
        classButton.backgroundColor = .darkGray;
        classButton.setTitle("test class", for:.normal);
        classButton.addTarget(self, action:#selector(testClass), for:.touchUpInside);
        self.view.addSubview(classButton);
        // generic class
        let genericClassButton = UIButton(frame:CGRect(x:(self.view.frame.width - 150) * 0.5, y:300, width:150, height:44));
        genericClassButton.backgroundColor = .darkGray;
        genericClassButton.setTitle("test generic class", for:.normal);
        genericClassButton.addTarget(self, action:#selector(testGenericClass), for:.touchUpInside);
        self.view.addSubview(genericClassButton);
    }
    
    @objc func getAllType() {
        printAllType();
    }

    @objc func testClass() {
        printClass();
    }
    
    @objc func testGenericClass() {
        printGenericClass();
    }
}

