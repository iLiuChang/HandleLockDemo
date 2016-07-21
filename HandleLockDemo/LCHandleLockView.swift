//
//  LCHandleLockView.swift
//  HandleLockDemo
//
//  Created by 刘畅 on 16/7/8.
//  Copyright © 2016年 ifdoo. All rights reserved.
//

import UIKit

class LCHandleLockView: UIView {
    
    typealias LCHandleResultBlock = ((result: Bool) -> Void)
    // 结果
    var handleBlock: LCHandleResultBlock?
    
    // 绘制的按钮
    private var buttons: [UIButton]!
    private var movePoint: CGPoint!
    private var topLabel: UILabel!
    private let lockKey = "HandleLockKey"
    private var result = true
    
    /**
     移除手势
     */
    func removeHandle() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(lockKey)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(lockKey)
        initLabel()
        initButtons()
        buttons = []
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  

}

extension LCHandleLockView {
  
    // 绘制轨迹
    override func drawRect(rect: CGRect) {
        if self.buttons.count == 0 {
            return
        }
        let path = UIBezierPath()
        for i in 0 ..< self.buttons.count {
            let button = buttons[i]
            if i == 0 {
                path.moveToPoint(button.center)
            }else {
                path.addLineToPoint(button.center)
            }
        }
        path.addLineToPoint(movePoint)
        path.lineWidth = 8
        if result {
            UIColor.greenColor().set()
        }else {
            UIColor.redColor().set()
        }
        path.lineJoinStyle = .Round
        path.stroke()
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard result else {
            return
        }
        
        let point = pointWithTouch(touches)
        if let btn = buttonWithPoint(point) {
            if !btn.selected {
                btn.selected = true
                buttons.append(btn)
            }
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard result else {
            return
        }
        let point = pointWithTouch(touches)
        movePoint = point
        if let btn = buttonWithPoint(point) {
            if !btn.selected {
                btn.selected = true
                if !buttons.contains(btn) {
                    buttons.append(btn)
                }
            }
        }
        self.setNeedsDisplay()
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard result else {
            return
        }
        var str = ""
        for button in buttons {
            button.selected = false
            str += String(button.tag)
        }
        
        if handleResult(str) {
            result = true
            buttons.removeAll()
            self.setNeedsDisplay()
            handleBlock?(result: true)
        }else {
            for button in buttons {
                button.setBackgroundImage(UIImage(named: "handle_warning"), forState: .Normal)
            }
            result = false
            self.setNeedsDisplay()
            addAnimation()
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    self.result = true
                    for button in self.buttons {
                        button.setBackgroundImage(UIImage(named: "handle_normal"), forState: .Normal)
                    }
                    self.buttons.removeAll()
                    self.setNeedsDisplay()
            }
            handleBlock?(result: false)
        }
    }
}

private extension LCHandleLockView {
    
    func handleResult(str: String) -> Bool {
        if let key = NSUserDefaults.standardUserDefaults().objectForKey(lockKey) {
            let lockStr = key as! String
            if str != "" && lockStr == str {
                self.topLabel.text = "手势密码正确"
                return true
            }else {
                self.topLabel.text = "手势密码错误"
                return false
            }
            
        }else {
            NSUserDefaults.standardUserDefaults().setObject(str as NSString, forKey: lockKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            topLabel.text = "设置完成"
            return true
        }
    }
    func pointWithTouch(touches: Set<UITouch>) -> CGPoint {
        let point = touches.first?.locationInView(self)
        return point!
    }
    
    func buttonWithPoint(point: CGPoint) -> UIButton? {
        for v in self.subviews {
            if let button: UIView = v  where button.frame.contains(point) {
                return button as? UIButton
            }
        }
        return nil
    }
    
    // 添加动画
    func addAnimation() {
        
        let tX = topLabel.center.x
        let tY: CGFloat = topLabel.center.y
        // 间隔
        let interval: CGFloat = 8
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position"
        animation.values = [pointValue(tX + interval, y: tY), pointValue(tX, y: tY), pointValue(tX - interval, y: tY), pointValue(tX, y: tY), pointValue(tX + 3, y: tY), pointValue(tX, y: tY)]
        // 保留最新位置
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.duration = 0.5
        topLabel.layer.addAnimation(animation, forKey: nil)
    }
    
    func pointValue(x: CGFloat, y: CGFloat) -> NSValue {
        return NSValue.init(CGPoint: CGPointMake(x, y))
    }
    
    func initLabel() {
        let label = UILabel()
        label.frame = CGRectMake(0, 20, 200, 30)
        label.center.x = self.center.x
        label.textColor = UIColor.redColor()
        label.userInteractionEnabled = true
        label.text = "手势解锁"
        label.textAlignment = .Center
        self.addSubview(label)
        self.topLabel = label
    }
    
    func initButtons() {
        
        let btnW: CGFloat = 80
        let rowCount: CGFloat = 3
        let gap = (self.frame.width - btnW * rowCount) / (rowCount + 1)
        for i in 0 ..< 9 {
            let list = CGFloat(i % 3 ) // 列
            let row = CGFloat( i / 3 ) // 行
            let button = UIButton()
            button.frame = CGRectMake((btnW + gap) * list + gap, (btnW + gap) * row + 20 + topLabel.frame.maxY , btnW, btnW)
            button.tag = i
            button.setBackgroundImage(UIImage(named: "handle_normal"), forState: .Normal)
            button.setBackgroundImage(UIImage(named: "handle_selected"), forState: .Selected)
            button.userInteractionEnabled = false
            self.addSubview(button)
        }
        
    }
    

}
