//
//  ViewController.swift
//  DropDown
//
//  Created by weiwei.li on 2020/5/6.
//  Copyright © 2020 dd01.leo. All rights reserved.
//

import UIKit

class ViewController: UIViewController, DropDownDataSource, DropDownDataDelegate {
    let menu = DropDownMenu(origin: CGPoint(x: 0, y: 100), height: 40)

    
    func menu(_ menu: DropDownMenu, titleForRow indexPath: DDIndexPath) -> String {
        let arr = ["123aaaaaaaaaaaaa","456","789","asd", "asfds"]
        return arr[indexPath.row]
    }
    
    func menu(_ menu: DropDownMenu, showCustomView column: Int) -> UIView? {
        if column == 4 {
            let view = UIView()
           view.frame = CGRect(x: 0, y: 0, width: 100, height: 400)
           view.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
           return view
        }
       return nil
    }
    
    func  menu(_ menu: DropDownMenu, titleForMenu column: Int) -> String {
        if column == 0 {
            return "dfdf0"
        }
        if column == 1 {
            return "dfdf1"
        }
        if column == 2 {
            return "dfdf2"
        }
        if column == 3 {
            return "dfdf3"
        }
        if column == 4 {
            return "dfdf4"
        }
        return ""
    }
    
    func menu(_ menu: DropDownMenu, numberOfRows column: Int) -> Int {
        if column == 4 {
            return 1
        }
        return 5
    }
    
    func numberOfColumnsInMenu(_ menu: DropDownMenu) -> Int {
        return 5
    }
    
    func menu(_ menu: DropDownMenu, didSelectRow indexPath: DDIndexPath) {
        print(menu.titleForRow(indexPath: indexPath))
        print(indexPath.column, indexPath.row)
    
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        menu.delegate = self
        menu.dataSource = self
        view.addSubview(menu)
        
        menu.menu(forTitle: "123", column: 4)
        menu.selectedRow(2, component: 0)
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        menu.showMenu(column: 4)
    }


}

