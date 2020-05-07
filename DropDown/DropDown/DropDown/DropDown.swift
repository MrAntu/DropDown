//
//  DropDown.swift
//  DropDown
//
//  Created by weiwei.li on 2020/5/6.
//  Copyright © 2020 dd01.leo. All rights reserved.
//

import Foundation
import UIKit

public struct DDIndexPath {
    var column: Int
    var row: Int
}

public protocol DropDownDataSource: NSObjectProtocol {
    func menu(_ menu: DropDownMenu, numberOfRows column: Int) -> Int;
    func menu(_ menu: DropDownMenu, titleForRow indexPath: DDIndexPath) -> String;
    func menu(_ menu: DropDownMenu, titleForMenu column: Int) -> String;
    func menu(_ menu: DropDownMenu, showCustomView column: Int) -> UIView?;

    func numberOfColumnsInMenu(_ menu:  DropDownMenu) -> Int
}

public extension DropDownDataSource {
    func numberOfColumnsInMenu(_ menu:  DropDownMenu) -> Int { 1 }
    func menu(_ menu: DropDownMenu, showCustomView column: Int) -> UIView? { nil}
}

public protocol DropDownDataDelegate: NSObjectProtocol {
    func menu(_ menu: DropDownMenu, didSelectRow indexPath: DDIndexPath);
}

public extension DropDownDataDelegate {
    func menu(_ menu: DropDownMenu, didSelectRow indexPath: DDIndexPath) {}
}


public class DropDownMenu: UIView {
    // Protocol
    public weak var delegate: DropDownDataDelegate?
    public weak var dataSource: DropDownDataSource? {
        didSet {
            configDataSource()
        }
    }
    
    // Color
    public var indicatorColor: UIColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    public var textColor: UIColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    
    // Private
    private var origin: CGPoint
    private var currentSelectedMenudIndex = -1
    private var isShow = false
    private var numOfMenu: Int = 1
    private var titleLayers = [CATextLayer]()
    private var bgLayers = [CALayer]()
    private var indicatorLayers = [CAShapeLayer]()

    private var tableView = UITableView()
    private let backgroundView: UIView = UIView()
    private let bottomShadow = UIView()
    
    public init(origin: CGPoint, height: CGFloat) {
        self.origin = origin
        let screenSize = UIScreen.main.bounds.size
        super.init(frame: CGRect(x: origin.x, y: origin.y, width: screenSize.width, height: height))
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 或者指定列的title
    public func titleForRow(indexPath: DDIndexPath) -> String {
        return dataSource?.menu(self, titleForRow: indexPath) ?? ""
    }
    
    // 收起dropdown
    public func dismiss() {
        backgroundTapped()
    }
    
    // 手动选择选中某列某行
    public func selectedRow(_ row: Int, component: Int) {
        currentSelectedMenudIndex = component
        configMenu(selected: row)
    }
    
    // 手动设置某列的标题
    public func menu(forTitle title: String, column: Int) {
        if column > numOfMenu {
            return
        }
        let titleLayer = titleLayers[column]
        titleLayer.string = title
    }
    
    //手动显示某列的下拉选项
    public func showMenu(column: Int) {
        animateShow(column)
     }
    
    deinit {
        print(self)
    }
}

extension DropDownMenu {
    
    private func configDataSource() {
        numOfMenu = dataSource?.numberOfColumnsInMenu(self) ?? 1
        
        let textLayerInterval: CGFloat = frame.size.width / CGFloat((numOfMenu * 2))
        let bgLayerInterval: CGFloat = frame.size.width / CGFloat(numOfMenu)
        
        var tempTitles = [CATextLayer]()
        var tempIndicators = [CAShapeLayer]()
        var tempBgLayers = [CALayer]()
        
        // 创建menu的title
        for index in 0..<numOfMenu {
            //bgLayer
            let bgLayerPosition = CGPoint(x: (CGFloat(index) + 0.5) * bgLayerInterval, y: frame.size.height / 2)
            let bglayer = createBgLayer(color: #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), position: bgLayerPosition)
            layer.addSublayer(bglayer)
            tempBgLayers.append(bglayer)
            // title
            let titlePosition = CGPoint(x: CGFloat(index * 2 + 1) * textLayerInterval, y: frame.size.height / 2)
//            let titleString = dataSource?.menu(self, titleForRow: DDIndexPath(column: index, row: 0)) ?? ""
            let titleString = dataSource?.menu(self, titleForMenu: index) ?? ""
            let titleLayer = createTextLayer(title: titleString, color: textColor, position: titlePosition)
            layer.addSublayer(titleLayer)
            tempTitles.append(titleLayer)
            // indicator
            let indicatorPosition: CGPoint = CGPoint(x: titlePosition.x + titleLayer.bounds.size.width / 2 + 8, y: frame.size.height / 2)
            let indicatorLayer = createIndicatorLayer(color: indicatorColor, position: indicatorPosition)
            layer.addSublayer(indicatorLayer)
            tempIndicators.append(indicatorLayer)
        }
        
        titleLayers = tempTitles
        indicatorLayers = tempIndicators
        bgLayers = tempBgLayers
    }
    
    private func createIndicatorLayer(color: UIColor, position: CGPoint) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 8, y: 0))
        path.addLine(to: CGPoint(x: 4, y: 5))
        path.close()
        
        layer.path = path.cgPath
        layer.lineWidth = 1.0
        layer.fillColor = color.cgColor
        
        if let bound = layer.path?.copy(strokingWithWidth: layer.lineWidth, lineCap: .butt, lineJoin: .miter, miterLimit: layer.miterLimit) {
            layer.bounds = bound.boundingBox
        }
        layer.position = position
        return layer
    }
    
    private func createTextLayer(title: String, color: UIColor, position: CGPoint) -> CATextLayer {
        let size = calculateTitleSize(title)
        let textLayer = CATextLayer()
        let sizeW: CGFloat = (size.width < (frame.size.width / CGFloat(numOfMenu)) - 25) ? size.width : frame.size.width / CGFloat(numOfMenu) - 25
        textLayer.bounds = CGRect(x: 0, y: 0, width: sizeW, height: size.height)
        textLayer.string = title
        textLayer.fontSize = 14.0
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = color.cgColor
        layer.contentsScale = UIScreen.main.scale
        textLayer.position = position
        return textLayer
    }
    
    private func calculateTitleSize(_ title: String) -> CGSize {
        let fontSize: CGFloat = 14
        let size = NSString(string: title).boundingRect(with: CGSize(width: 280, height: 0), options: [.truncatesLastVisibleLine, .usesLineFragmentOrigin], attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)], context: nil).size
        return size
    }
    
    private func createBgLayer(color: UIColor, position: CGPoint) -> CALayer {
        let layer = CALayer()
        layer.position = position
        layer.bounds = CGRect(x: 0, y: 0, width: frame.size.width / CGFloat(numOfMenu), height: frame.size.height - 1)
        layer.backgroundColor = color.cgColor
        return layer
    }
 
    static let identifier = "DropDownMenuCell";
    private func setupUI() {
        tableView = UITableView(frame: CGRect(x: origin.x, y: frame.origin.y + frame.size.height, width: frame.size.width, height: 0), style: .plain)
        tableView.rowHeight = 40
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: DropDownMenu.identifier)
        
        backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(menuTapped(_:)))
        addGestureRecognizer(tapGesture)
        
        let screenSize = UIScreen.main.bounds.size
        backgroundView.frame = CGRect(x: origin.x, y: origin.y, width: screenSize.width, height: screenSize.height)
        backgroundView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).withAlphaComponent(0)
        backgroundView.isOpaque = false
        let backTapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        backgroundView.addGestureRecognizer(backTapGesture)
        
        //bottom shadow
        bottomShadow.frame = CGRect(x: 0, y: frame.size.height - 0.5, width: screenSize.width, height: 0.5)
        bottomShadow.backgroundColor = UIColor.lightGray
        addSubview(bottomShadow)
        
    }
    
    @objc private func menuTapped(_ paramSender: UITapGestureRecognizer) {
        let touchPoint = paramSender.location(in: self)
        // 获取点击的menu的位置
        let tapIndex = Int(touchPoint.x / (frame.size.width / CGFloat(numOfMenu)))
        animateShow(tapIndex)
    }
    
    private func animateShow(_ tapIndex: Int) {
        for index in 0..<numOfMenu {
               if index != tapIndex {
                   animateIndicator(indicator: indicatorLayers[index], forward: false) {[weak self] in
                       if let wself = self {
                           wself.animateTitle(titleLayer: wself.titleLayers[index], show: false, complete: {
                                                 
                           })
                       }
                   }
                   bgLayers[index].backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
               }
           }
           
           if tapIndex == currentSelectedMenudIndex && isShow {
               animateIndicator(indicator: indicatorLayers[currentSelectedMenudIndex], background: backgroundView, tableView: tableView, titleLayer: titleLayers[currentSelectedMenudIndex], forward: false) {[weak self] in
                   self?.currentSelectedMenudIndex = tapIndex
                   self?.isShow = false
               }
               bgLayers[currentSelectedMenudIndex].backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
           } else {
               currentSelectedMenudIndex = tapIndex
               tableView.reloadData()
               animateIndicator(indicator: indicatorLayers[currentSelectedMenudIndex], background: backgroundView, tableView: tableView, titleLayer: titleLayers[currentSelectedMenudIndex], forward: true) {[weak self] in
                   self?.isShow = true
               }
               bgLayers[currentSelectedMenudIndex].backgroundColor = UIColor(white: 0.9, alpha: 1).cgColor
           }
    }
    
    @objc private func backgroundTapped() {
        animateIndicator(indicator: indicatorLayers[currentSelectedMenudIndex], background: backgroundView, tableView: tableView, titleLayer: titleLayers[currentSelectedMenudIndex], forward: false) {[weak self] in
            self?.isShow = false
        }
        bgLayers[currentSelectedMenudIndex].backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
    }
    
    private func animateTitle(titleLayer: CATextLayer, show: Bool, complete:@escaping (() -> ())) {
        let title = (titleLayer.string as? String) ?? ""
        let size = calculateTitleSize(title)
        let sizeW: CGFloat = (size.width < (frame.size.width / CGFloat(numOfMenu)) - 25) ? size.width : frame.size.width / CGFloat(numOfMenu) - 25
        titleLayer.bounds = CGRect(x: 0, y: 0, width: sizeW, height: size.height)
        complete()
    }
    
    private func animateIndicator(indicator: CAShapeLayer, forward: Bool, complete:@escaping (() -> ())) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0))
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
        animation.values = forward ? [0, Double.pi] : [Double.pi, 0]
        if !animation.isRemovedOnCompletion {
            indicator.add(animation, forKey: animation.keyPath)
        } else {
            indicator.add(animation, forKey: animation.keyPath)
            indicator.setValue(animation.values?.last, forKeyPath: animation.keyPath ?? "")
        }
        CATransaction.commit()
        complete()
    }
    
    private func animateIndicator(indicator: CAShapeLayer, background: UIView, tableView: UITableView, titleLayer: CATextLayer, forward: Bool, complete:@escaping (() -> ())) {
        animateIndicator(indicator: indicator, forward: forward) {[weak self] in
            self?.animateTitle(titleLayer: titleLayer, show: forward, complete: {[weak self] in
                self?.animateBackGroundView(background, show: forward, complete: {[weak self] in
                    self?.animateTableView(tableView, show: forward, complete: {
                        
                    })
                })
            })
        }
        complete()
    }
    
    private func animateTableView(_ tableView: UITableView, show: Bool, complete: @escaping (() -> ())) {
        if show {
            tableView.frame = CGRect(x: origin.x, y: frame.origin.y + frame.size.height, width:frame.size.width, height: 0)
            superview?.addSubview(tableView)
            
            var tableViewHeight = (tableView.numberOfRows(inSection: 0) > 5) ? (5.0 * tableView.rowHeight) : (CGFloat(tableView.numberOfRows(inSection: 0)) * tableView.rowHeight)
            if let customView = dataSource?.menu(self, showCustomView: currentSelectedMenudIndex) {
                tableViewHeight = customView.frame.size.height
            }
            UIView.animate(withDuration: 0.2) {[weak self] in
                if let wself = self {
                    wself.tableView.frame = CGRect(x: wself.origin.x, y: wself.frame.origin.y + wself.frame.size.height, width: wself.frame.size.width, height: tableViewHeight)
                }
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: self.origin.x, y: self.frame.origin.y + self.frame.size.height, width: self.frame.size.width, height: 0)
            }, completion: { _ in
                tableView.removeFromSuperview()
            })
        }
    }
    
    private func animateBackGroundView(_ backView: UIView, show: Bool, complete: @escaping (()->())) {
        if show {
            superview?.addSubview(backView)
            backView.superview?.addSubview(self)
            UIView.animate(withDuration: 0.2) {
                backView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).withAlphaComponent(0.3)
            }
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                backView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).withAlphaComponent(0)
            }, completion: { _ in
                backView.removeFromSuperview()
            })
        }
        complete()
    }
}

extension DropDownMenu: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.menu(self, numberOfRows: currentSelectedMenudIndex) ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: DropDownMenu.identifier) {
            cell.contentView.subviews.forEach { (sub) in
                sub.removeFromSuperview()
            }
            if let customView = dataSource?.menu(self, showCustomView: currentSelectedMenudIndex) {
                customView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: customView.frame.size.height)
                cell.contentView.addSubview(customView)
                cell.textLabel?.text = ""
                tableView.isScrollEnabled = false
                tableView.separatorStyle = .none
            } else {
                tableView.isScrollEnabled = true
                tableView.separatorStyle = .singleLine
                cell.textLabel?.text = dataSource?.menu(self, titleForRow: DDIndexPath(column: currentSelectedMenudIndex, row: indexPath.row))
                cell.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
                cell.separatorInset = UIEdgeInsets.zero
                if let titleLayerStr = titleLayers[currentSelectedMenudIndex].string as? String,
                    cell.textLabel?.text == titleLayerStr {
                    cell.backgroundColor = UIColor(white: 0.9, alpha: 1)
                }
            }
            
            return cell
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        configMenu(selected: indexPath.row)
        delegate?.menu(self, didSelectRow: DDIndexPath(column: currentSelectedMenudIndex, row: indexPath.row))
    }
    
    private func configMenu(selected row: Int) {
        let titleLayer = titleLayers[currentSelectedMenudIndex]
        let indicator = indicatorLayers[currentSelectedMenudIndex]
        titleLayer.string = dataSource?.menu(self, titleForRow: DDIndexPath(column: currentSelectedMenudIndex, row: row))
        animateIndicator(indicator: indicator, background: backgroundView, tableView: tableView, titleLayer: titleLayer, forward: false) {[weak self] in
            self?.isShow = false
        }
        bgLayers[currentSelectedMenudIndex].backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
        indicator.position = CGPoint(x: titleLayer.position.x + titleLayer.frame.size.width / 2.0 + 8, y: indicator.position.y)
    }
}
