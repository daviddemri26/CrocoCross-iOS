import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import CryptoKit

// Original vector artwork only. No source images, SF Symbols or external fonts.
// Usage: swift scripts/render-achievement-badges.swift [catalog.json] [output-directory]
struct Badge: Decodable {
    let id: String, category: String, title: String, proposedImageFilename: String
    let target: Int
}
struct Catalog: Decodable { let achievements: [Badge] }
let args = CommandLine.arguments
let input = URL(fileURLWithPath: args.count > 1 ? args[1] : "docs/achievements-game-center.json")
let output = URL(fileURLWithPath: args.count > 2 ? args[2] : "distribution/game-center/achievements")
let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: input))
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let ink = NSColor(srgbRed: 0.045, green: 0.105, blue: 0.12, alpha: 1).cgColor
let teal = NSColor(srgbRed: 0.09, green: 0.28, blue: 0.29, alpha: 1).cgColor
let lime = NSColor(srgbRed: 0.76, green: 0.97, blue: 0.31, alpha: 1).cgColor
let orange = NSColor(srgbRed: 1, green: 0.47, blue: 0.17, alpha: 1).cgColor
let cream = NSColor(srgbRed: 0.99, green: 0.94, blue: 0.76, alpha: 1).cgColor
let pale = NSColor(srgbRed: 0.52, green: 0.74, blue: 0.68, alpha: 1).cgColor
func context(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}
func circle(_ c: CGContext, _ x: Double, _ y: Double, _ r: Double, _ color: CGColor) {
    c.setFillColor(color); c.fillEllipse(in: CGRect(x: x-r, y: y-r, width: r*2, height: r*2))
}
func path(_ c: CGContext, _ points: [CGPoint], _ color: CGColor, width: Double = 0, close: Bool = false) {
    c.beginPath(); c.move(to: points[0]); for p in points.dropFirst() { c.addLine(to: p) }
    if close { c.closePath() }
    if width > 0 { c.setStrokeColor(color); c.setLineWidth(width); c.setLineCap(.round); c.setLineJoin(.round); c.strokePath() }
    else { c.setFillColor(color); c.fillPath() }
}
func star(_ c: CGContext, _ x: Double, _ y: Double, _ radius: Double, _ color: CGColor, points: Int = 5) {
    let vertices = (0..<points*2).map { i -> CGPoint in
        let angle = Double(i) * .pi / Double(points) + .pi / 2
        let r = i.isMultiple(of: 2) ? radius : radius * 0.44
        return CGPoint(x: x + cos(angle)*r, y: y + sin(angle)*r)
    }
    path(c, vertices, color, close: true)
}
func bezier(_ c: CGContext, _ start: CGPoint, _ end: CGPoint, _ a: CGPoint, _ b: CGPoint, _ color: CGColor, _ width: Double) {
    c.beginPath(); c.move(to: start); c.addCurve(to: end, control1: a, control2: b)
    c.setLineCap(.round); c.setLineWidth(width); c.setStrokeColor(color); c.strokePath()
}
func rank(_ badge: Badge) -> Int {
    if badge.category == "distance" { return (Array(1...15) + Array(stride(from: 20, through: 50, by: 5))).firstIndex(of: badge.target/1000) ?? 0 }
    return [10,50,100,250,500,1000,2500,5000,10000].firstIndex(of: badge.target) ?? 0
}
func tier(_ badge: Badge) -> Int {
    if badge.category == "distance" { return min(4, rank(badge) / 5) }
    if badge.id.contains("stunt.total") { return min(4, rank(badge) / 2) }
    if badge.id.contains("triple") || badge.target >= 100 { return 3 }
    if badge.id.contains("double") || badge.target >= 10 { return 2 }
    return badge.target >= 5 ? 1 : 0
}
func medal(_ c: CGContext, _ badge: Badge) {
    let accent = badge.category == "distance" ? orange : badge.category == "weekly" ? cream : lime
    c.setFillColor(ink); c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    circle(c,512,512,475,teal); circle(c,512,512,454,accent); circle(c,512,512,433,ink)
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [teal,ink] as CFArray, locations: [0,1])!
    c.saveGState(); c.addEllipse(in: CGRect(x: 102,y: 102,width: 820,height: 820)); c.clip()
    c.drawLinearGradient(gradient,start:CGPoint(x:250,y:900),end:CGPoint(x:800,y:130),options:[])
    c.restoreGState()
    // Broken inner track and progression studs survive a circular crop.
    for i in 0..<24 {
        let a = Double(i) / 24 * 2 * Double.pi
        let active = i <= min(23, 3 + tier(badge)*5)
        circle(c,512+cos(a)*395,512+sin(a)*395,active ? 9 : 5,active ? accent : teal)
    }
    for i in 0...tier(badge) {
        let x = 512 + Double(i-tier(badge)/2)*52 - (tier(badge).isMultiple(of: 2) ? 0 : 26)
        star(c,x,818,18,accent)
    }
    path(c,[CGPoint(x:365,y:206),CGPoint(x:512,y:180),CGPoint(x:659,y:206)],accent,width:12)
    if badge.category == "distance" {
        let n = max(1,badge.target/1000)
        let peaks = min(4,1+tier(badge))
        var ridge = [CGPoint(x:225,y:430)]
        for p in 0..<peaks {
            let x = 285 + Double(p)*450/Double(peaks)
            ridge.append(CGPoint(x:x,y:630+Double((n+p)%3)*35))
            ridge.append(CGPoint(x:x+130/Double(peaks),y:460))
        }
        ridge.append(CGPoint(x:795,y:400)); ridge.append(CGPoint(x:795,y:335)); ridge.append(CGPoint(x:225,y:335))
        path(c,ridge,pale,close:true)
        bezier(c,CGPoint(x:310,y:300),CGPoint(x:650,y:655),CGPoint(x:900,y:370),CGPoint(x:255,y:470),ink,125)
        bezier(c,CGPoint(x:310,y:300),CGPoint(x:650,y:655),CGPoint(x:900,y:370),CGPoint(x:255,y:470),orange,91)
        bezier(c,CGPoint(x:310,y:300),CGPoint(x:650,y:655),CGPoint(x:900,y:370),CGPoint(x:255,y:470),cream,10)
        for i in 0..<(rank(badge)%5+1) { circle(c,420+Double(i)*46,263,12,lime) }
        path(c,[CGPoint(x:650,y:635),CGPoint(x:650,y:745)],cream,width:14)
        path(c,[CGPoint(x:660,y:745),CGPoint(x:737,y:715),CGPoint(x:660,y:689)],lime,close:true)
    } else if badge.category == "stunts" {
        let count = badge.id.contains("triple") ? 3 : badge.id.contains("double") ? 2 : 1
        let reverse = badge.id.contains("backflip")
        for i in 0..<count {
            let r = 252.0-Double(i)*45
            c.beginPath(); c.addArc(center:CGPoint(x:512,y:510),radius:r,startAngle:reverse ? 5.60 : 0.32,endAngle:reverse ? 0.32 : 5.60,clockwise:reverse)
            c.setStrokeColor(i.isMultiple(of:2) ? lime : orange); c.setLineWidth(23);c.setLineCap(.round);c.strokePath()
            let a = reverse ? 0.32 : 5.60
            let x = 512+cos(a)*r, y = 510+sin(a)*r
            c.saveGState();c.translateBy(x:x,y:y);c.rotate(by:a+(reverse ? -.pi/2 : .pi/2))
            path(c,[CGPoint(x:27,y:0),CGPoint(x:-20,y:28),CGPoint(x:-20,y:-28)],i.isMultiple(of:2) ? lime : orange,close:true);c.restoreGState()
        }
        // A small, chunky original motorcycle silhouette.
        for x in [420.0,620.0] { circle(c,x,456,54,cream);circle(c,x,456,28,ink) }
        path(c,[CGPoint(x:420,y:456),CGPoint(x:468,y:550),CGPoint(x:553,y:456),CGPoint(x:420,y:456),CGPoint(x:530,y:530),CGPoint(x:590,y:530),CGPoint(x:620,y:456)],orange,width:24)
        path(c,[CGPoint(x:455,y:562),CGPoint(x:513,y:562)],cream,width:23)
        path(c,[CGPoint(x:578,y:567),CGPoint(x:600,y:585),CGPoint(x:630,y:585)],cream,width:18)
        if badge.id.contains("total") {
            star(c,512,674,38,cream)
            for i in 0..<(rank(badge)%2+1) {
                let x = rank(badge).isMultiple(of: 2) ? 512.0 : 484.0 + Double(i)*56
                star(c,x,266,21,orange)
            }
        }
    } else if badge.category == "weekly" {
        // Trophy / checkerboard hybrid, with increasingly strong laurels.
        bezier(c,CGPoint(x:361,y:637),CGPoint(x:458,y:430),CGPoint(x:222,y:663),CGPoint(x:291,y:442),orange,33)
        bezier(c,CGPoint(x:663,y:637),CGPoint(x:566,y:430),CGPoint(x:802,y:663),CGPoint(x:733,y:442),orange,33)
        let cup = CGMutablePath();cup.move(to:CGPoint(x:355,y:702));cup.addLine(to:CGPoint(x:669,y:702));cup.addCurve(to:CGPoint(x:512,y:430),control1:CGPoint(x:675,y:480),control2:CGPoint(x:614,y:430));cup.addCurve(to:CGPoint(x:355,y:702),control1:CGPoint(x:410,y:430),control2:CGPoint(x:349,y:480));cup.closeSubpath()
        c.addPath(cup);c.setFillColor(cream);c.fillPath()
        path(c,[CGPoint(x:512,y:437),CGPoint(x:512,y:332)],cream,width:40)
        path(c,[CGPoint(x:426,y:320),CGPoint(x:598,y:320)],orange,width:45)
        for row in 0..<3 { for col in 0..<4 where (row+col).isMultiple(of:2) { c.setFillColor(teal);c.fill(CGRect(x:412+col*50,y:533+row*44,width:50,height:44)) } }
        for i in 0...tier(badge) { let y=370+Double(i)*55;path(c,[CGPoint(x:298,y:y),CGPoint(x:320,y:y+42),CGPoint(x:345,y:y+17)],lime,close:true);path(c,[CGPoint(x:726,y:y),CGPoint(x:704,y:y+42),CGPoint(x:679,y:y+17)],lime,close:true) }
    } else if badge.id.contains("shiba") {
        path(c,[CGPoint(x:320,y:574),CGPoint(x:300,y:748),CGPoint(x:432,y:669),CGPoint(x:592,y:669),CGPoint(x:724,y:748),CGPoint(x:704,y:574),CGPoint(x:646,y:378),CGPoint(x:512,y:305),CGPoint(x:378,y:378)],orange,close:true)
        path(c,[CGPoint(x:328,y:699),CGPoint(x:337,y:592),CGPoint(x:400,y:656)],ink,close:true)
        path(c,[CGPoint(x:696,y:699),CGPoint(x:687,y:592),CGPoint(x:624,y:656)],ink,close:true)
        path(c,[CGPoint(x:358,y:474),CGPoint(x:441,y:518),CGPoint(x:512,y:432),CGPoint(x:583,y:518),CGPoint(x:666,y:474),CGPoint(x:612,y:379),CGPoint(x:512,y:329),CGPoint(x:412,y:379)],cream,close:true)
        path(c,[CGPoint(x:398,y:559),CGPoint(x:443,y:544)],ink,width:24);path(c,[CGPoint(x:626,y:559),CGPoint(x:581,y:544)],ink,width:24)
        path(c,[CGPoint(x:474,y:438),CGPoint(x:550,y:438),CGPoint(x:512,y:402)],ink,close:true)
        path(c,[CGPoint(x:512,y:411),CGPoint(x:512,y:382)],ink,width:12)
    } else {
        // Japanese torii gateway, with visible open centre and a rising sun.
        circle(c,512,637,107,cream)
        path(c,[CGPoint(x:302,y:280),CGPoint(x:350,y:693)],orange,width:58)
        path(c,[CGPoint(x:722,y:280),CGPoint(x:674,y:693)],orange,width:58)
        path(c,[CGPoint(x:271,y:553),CGPoint(x:753,y:553)],orange,width:48)
        bezier(c,CGPoint(x:258,y:725),CGPoint(x:766,y:725),CGPoint(x:391,y:670),CGPoint(x:633,y:670),orange,57)
        path(c,[CGPoint(x:512,y:552),CGPoint(x:512,y:692)],orange,width:38)
        path(c,[CGPoint(x:254,y:274),CGPoint(x:770,y:274)],pale,width:24)
    }
}
func save(_ image: CGImage, _ url: URL) throws {
    guard let destination=CGImageDestinationCreateWithURL(url as CFURL,UTType.png.identifier as CFString,1,nil) else { fatalError("PNG destination") }
    CGImageDestinationAddImage(destination,image,[kCGImagePropertyDPIWidth:72,kCGImagePropertyDPIHeight:72] as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { fatalError("PNG encoding") }
}
var images:[CGImage]=[];var records:[[String:Any]]=[]
for badge in catalog.achievements {
    precondition(badge.proposedImageFilename == URL(fileURLWithPath:badge.proposedImageFilename).lastPathComponent)
    let c=context(1024,1024);medal(c,badge);let image=c.makeImage()!
    let file=output.appendingPathComponent(badge.proposedImageFilename);try save(image,file)
    let digest=SHA256.hash(data:try Data(contentsOf:file)).map{String(format:"%02x",$0)}.joined()
    records.append(["id":badge.id,"filename":badge.proposedImageFilename,"sha256":digest,"width":1024,"height":1024,"dpi":72,"opaque":true,"colorSpace":"sRGB","source":"original CoreGraphics vector paths"])
    images.append(image)
}
let columns=8,cell=224,rows=(images.count+columns-1)/columns
let sheet=context(columns*cell,rows*260)
sheet.setFillColor(ink);sheet.fill(CGRect(x:0,y:0,width:columns*cell,height:rows*260))
let graphics=NSGraphicsContext(cgContext:sheet,flipped:false);NSGraphicsContext.saveGraphicsState();NSGraphicsContext.current=graphics
for (index,image) in images.enumerated() {
    let x=Double((index%columns)*cell),y=Double((rows-1-index/columns)*260)
    sheet.saveGState();sheet.addEllipse(in:CGRect(x:x+32,y:y+65,width:160,height:160));sheet.clip();sheet.draw(image,in:CGRect(x:x+32,y:y+65,width:160,height:160));sheet.restoreGState()
    // Actual 64px circular crop, separate from the larger inspection view.
    sheet.saveGState();sheet.addEllipse(in:CGRect(x:x+144,y:y+1,width:64,height:64));sheet.clip();sheet.draw(image,in:CGRect(x:x+144,y:y+1,width:64,height:64));sheet.restoreGState()
    let style=NSMutableParagraphStyle();style.alignment = .left
    (catalog.achievements[index].title as NSString).draw(in:CGRect(x:x+10,y:y+20,width:133,height:35),withAttributes:[.font:NSFont.systemFont(ofSize:11,weight:.semibold),.foregroundColor:NSColor.white,.paragraphStyle:style])
}
NSGraphicsContext.restoreGraphicsState()
try save(sheet.makeImage()!,output.appendingPathComponent("contact-sheet.png"))
let manifest:[String:Any] = ["status":"local artwork proposal; owner visual approval and App Store configuration remain separate","count":records.count,"sourceCatalog":input.lastPathComponent,"files":records]
try JSONSerialization.data(withJSONObject:manifest,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("manifest.json"))
print("Rendered \(images.count) original badges, contact-sheet.png and manifest.json")
