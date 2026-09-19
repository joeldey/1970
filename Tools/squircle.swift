import AppKit

// Masks a source image to the macOS icon squircle at a given size and margin.
// Usage: swift squircle.swift <src.png> <out.png> <size> <inset-fraction>
let a = CommandLine.arguments
guard a.count == 5, let size = Int(a[3]), let inset = Double(a[4]) else {
    FileHandle.standardError.write("usage: squircle.swift <src> <out> <size> <inset>\n".data(using: .utf8)!)
    exit(1)
}

guard let data = try? Data(contentsOf: URL(fileURLWithPath: a[1])),
      let rep = NSBitmapImageRep(data: data),
      let src = rep.cgImage else {
    fatalError("cannot load \(a[1])")
}

// Superellipse (n=5) — the continuous-corner "squircle" macOS uses.
func squircle(in rect: CGRect, n: Double = 5) -> CGPath {
    let path = CGMutablePath()
    let (cx, cy, ra, rb) = (rect.midX, rect.midY, rect.width / 2, rect.height / 2)
    for i in 0...720 {
        let t = Double(i) / 720 * 2 * .pi
        let x = cx + ra * copysign(pow(abs(cos(t)), 2 / n), cos(t))
        let y = cy + rb * copysign(pow(abs(sin(t)), 2 / n), sin(t))
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

let S = CGFloat(size)
guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                          bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
    fatalError("no context")
}
let margin = S * CGFloat(inset)
let content = CGRect(x: margin, y: margin, width: S - 2 * margin, height: S - 2 * margin)
ctx.clear(CGRect(x: 0, y: 0, width: S, height: S))
ctx.addPath(squircle(in: content))
ctx.clip()
ctx.interpolationQuality = .high
ctx.draw(src, in: content)

guard let out = ctx.makeImage(),
      let png = NSBitmapImageRep(cgImage: out).representation(using: .png, properties: [:]) else {
    fatalError("encode failed")
}
try! png.write(to: URL(fileURLWithPath: a[2]))
