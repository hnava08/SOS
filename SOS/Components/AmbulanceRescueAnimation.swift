import SwiftUI

/// Ciudad + ambulancia (ilustración) + humanos suaves sin contorno negro.
/// La carrocería y la rueda son los PNG transparentes del catálogo.
struct AmbulanceRescueAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale
    @State private var frames = RescueFrames()

    private let cycle: TimeInterval = 6.0

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas(rendersAsynchronously: false) { context, canvasSize in
                    drawCityLayer(context: context, size: canvasSize)
                }
                TimelineView(.animation(minimumInterval: reduceMotion ? 0.25 : 1.0 / 30.0, paused: false)) { timeline in
                    let t = reduceMotion ? 0.42 : progress(at: timeline.date)
                    Canvas(rendersAsynchronously: false) { context, canvasSize in
                        drawScene(context: context, size: canvasSize, t: t)
                    }
                }
            }
            .onAppear { prepareFrames(size: size) }
            .onChange(of: size) { _, newSize in
                prepareFrames(size: newSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityHidden(true)
    }

    private func progress(at date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: cycle) / cycle)
    }

    private func drawScene(context: GraphicsContext, size: CGSize, t: CGFloat) {
        let w = size.width
        let h = size.height
        let s = min(w / 340, h / 230)
        let people = s * 0.68
        let groundY = h * 0.78
        let length = ambulanceLength(width: w, height: h, groundY: groundY)
        let speed = (t >= 0.68 && t < 0.96) ? min(1, (t - 0.68) / 0.28) : 0

        drawRoad(context: context, width: w, groundY: groundY, t: t + speed * 8, s: s)

        // La ilustración mira a la izquierda. Al frenar, el centro de la furgoneta queda en el medio.
        let stopX = w * 0.5
        let patientX = max(28 * people, stopX - length * 0.5 - 34 * people)
        let offRight = w + length * 0.55
        let offLeft = -length * 0.72

        let vanX: CGFloat
        let stretcherT: CGFloat
        let patientOnStretcher: Bool
        let showGroundPatient: Bool
        let lightsOn: Bool

        if t < 0.30 {
            let p = easeOut(t / 0.30)
            vanX = offRight + p * (stopX - offRight)
            stretcherT = 0
            patientOnStretcher = false
            showGroundPatient = true
            lightsOn = true
        } else if t < 0.42 {
            vanX = stopX
            stretcherT = easeInOut((t - 0.30) / 0.12)
            patientOnStretcher = false
            showGroundPatient = true
            lightsOn = true
        } else if t < 0.52 {
            vanX = stopX
            stretcherT = 1
            patientOnStretcher = true
            showGroundPatient = false
            lightsOn = true
        } else if t < 0.68 {
            vanX = stopX
            stretcherT = 1 - easeInOut((t - 0.52) / 0.16)
            patientOnStretcher = true
            showGroundPatient = false
            lightsOn = true
        } else if t < 0.96 {
            let cruise = w * 0.40
            if speed < 0.32 {
                let p = easeIn(speed / 0.32)
                vanX = stopX + p * (cruise - stopX)
            } else if speed < 0.76 {
                vanX = cruise
            } else {
                let p = easeIn((speed - 0.76) / 0.24)
                vanX = cruise + p * (offLeft - cruise)
            }
            stretcherT = 0
            patientOnStretcher = true
            showGroundPatient = false
            lightsOn = true
        } else {
            vanX = offRight
            stretcherT = 0
            patientOnStretcher = false
            showGroundPatient = (t - 0.96) / 0.04 > 0.45
            lightsOn = false
        }

        let doorX = vanX - length * 0.22
        let stretcherX = doorX + (patientX + 6 * people - doorX) * stretcherT
        let showStretcher = stretcherT > 0.02 && t < 0.68

        let arrive = min(t, 0.30) / 0.30
        let leave = speed
        let wheelSpin = -(arrive * 8 + leave * 20) * .pi

        if speed > 0.02 {
            drawSpeedStreaks(context: context, width: w, groundY: groundY, s: s, amount: speed, t: t)
            drawShadowTraffic(context: context, vanX: vanX, ambulanceLength: length, groundY: groundY, amount: speed)
        }

        if showGroundPatient {
            drawSoftHuman(
                context: context,
                at: CGPoint(x: patientX, y: groundY),
                pose: .sittingHelp(wave: sin(t * .pi * 7)),
                s: people
            )
        }

        if showStretcher {
            let box = stretcherSnapshotBox(s: people)
            let image = patientOnStretcher ? frames.stretcherFull : frames.stretcherEmpty
            if let image, abs(frames.people - people) < 0.5 {
                context.draw(
                    image,
                    in: CGRect(
                        x: stretcherX - box.anchor.x,
                        y: groundY - box.anchor.y,
                        width: box.size.width,
                        height: box.size.height
                    )
                )
            } else {
                drawStretcher(
                    context: context,
                    at: CGPoint(x: stretcherX, y: groundY),
                    withPatient: patientOnStretcher,
                    s: people
                )
            }
        }

        drawCarAmbulance(
            context: context,
            centerX: vanX,
            groundY: groundY,
            length: length,
            spin: wheelSpin,
            lightsOn: lightsOn,
            t: t
        )
    }

    /// Largo de la furgoneta. Un poco más alta que las personas, sin tapar la ciudad.
    private func ambulanceLength(width w: CGFloat, height h: CGFloat, groundY: CGFloat) -> CGFloat {
        let maxByWidth = w * 0.44
        let maxByHeight = min(groundY, h) * 0.34 / 0.42
        return min(maxByWidth, maxByHeight)
    }

    // MARK: - Ambulancia (mismo volumen que las personas)

    private func drawCarAmbulance(
        context: GraphicsContext,
        centerX: CGFloat,
        groundY: CGFloat,
        length L: CGFloat,
        spin: CGFloat,
        lightsOn: Bool,
        t: CGFloat
    ) {
        let left = centerX - L * 0.5
        let roof = groundY - L * 0.40
        let wheelR = L * 0.078
        let front = CGPoint(x: left + L * 0.24, y: groundY - wheelR * 0.92)
        let rear = CGPoint(x: left + L * 0.78, y: groundY - wheelR * 0.92)

        castShadow(context, CGRect(x: left + L * 0.06, y: groundY - L * 0.02, width: L * 0.88, height: L * 0.045))
        drawVolumeWheel(context: context, center: front, radius: wheelR, angle: spin)
        drawVolumeWheel(context: context, center: rear, radius: wheelR, angle: spin)

        if let body = frames.body, abs(frames.bodyLength - L) < 0.5 {
            context.draw(
                body,
                in: CGRect(x: left, y: groundY - frames.bodyTop, width: L, height: frames.bodyHeight)
            )
        } else {
            drawAmbulanceChassis(context: context, centerX: centerX, groundY: groundY, length: L)
        }

        guard lightsOn else { return }
        let red = CGPoint(x: left + L * 0.34, y: roof - L * 0.012)
        let blue = CGPoint(x: left + L * 0.44, y: roof - L * 0.012)
        drawPatrolLight(context: context, at: red, side: L * 0.58, t: t, isRed: true)
        drawPatrolLight(context: context, at: blue, side: L * 0.58, t: t, isRed: false)
        let washOn = sin(t * .pi * 16) > 0
        fillOval(
            context,
            CGRect(x: centerX - L * 0.22, y: groundY - L * 0.03, width: L * 0.44, height: L * 0.05),
            (washOn ? Color.red : Color(red: 0.35, green: 0.55, blue: 1)).opacity(0.28)
        )
    }

    private func drawAmbulanceChassis(
        context: GraphicsContext,
        centerX: CGFloat,
        groundY: CGFloat,
        length L: CGFloat
    ) {
        let left = centerX - L * 0.5
        let roof = groundY - L * 0.40
        let belt = groundY - L * 0.07
        let wheelR = L * 0.078
        let front = CGPoint(x: left + L * 0.24, y: groundY - wheelR * 0.92)
        let rear = CGPoint(x: left + L * 0.78, y: groundY - wheelR * 0.92)
        let bodyTone = Tone(light: .white, base: Color(white: 0.93), shade: Color(white: 0.74))
        let skirtTone = Tone(light: Color(white: 0.42), base: Color(white: 0.22), shade: Color(white: 0.08))
        let glass = Tone(
            light: Color(red: 0.82, green: 0.92, blue: 0.98),
            base: Color(red: 0.45, green: 0.64, blue: 0.80),
            shade: Color(red: 0.20, green: 0.34, blue: 0.50)
        )
        let stripe = Tone(
            light: Color(red: 1, green: 0.45, blue: 0.42),
            base: SOSTheme.primaryRed,
            shade: Color(red: 0.55, green: 0.06, blue: 0.08)
        )

        var body = Path()
        body.move(to: CGPoint(x: left + L * 0.03, y: belt))
        body.addQuadCurve(to: CGPoint(x: left + L * 0.10, y: groundY - L * 0.20), control: CGPoint(x: left, y: groundY - L * 0.16))
        body.addQuadCurve(to: CGPoint(x: left + L * 0.24, y: roof + L * 0.03), control: CGPoint(x: left + L * 0.14, y: roof + L * 0.10))
        body.addQuadCurve(to: CGPoint(x: left + L * 0.32, y: roof), control: CGPoint(x: left + L * 0.26, y: roof))
        body.addLine(to: CGPoint(x: left + L * 0.96, y: roof))
        body.addQuadCurve(to: CGPoint(x: left + L * 0.99, y: roof + L * 0.05), control: CGPoint(x: left + L, y: roof))
        body.addLine(to: CGPoint(x: left + L * 0.985, y: belt))
        body.addLine(to: CGPoint(x: rear.x + wheelR * 1.25, y: belt))
        body.addQuadCurve(to: CGPoint(x: rear.x - wheelR * 1.25, y: belt), control: CGPoint(x: rear.x, y: belt - wheelR * 1.55))
        body.addLine(to: CGPoint(x: front.x + wheelR * 1.25, y: belt))
        body.addQuadCurve(to: CGPoint(x: front.x - wheelR * 1.15, y: belt), control: CGPoint(x: front.x, y: belt - wheelR * 1.55))
        body.closeSubpath()
        fillShaded(context, body, tone: bodyTone, from: CGPoint(x: left, y: roof), to: CGPoint(x: left + L, y: groundY))
        fillOval(context, CGRect(x: left + L * 0.30, y: roof + L * 0.015, width: L * 0.42, height: L * 0.06), Color.white.opacity(0.35))

        let bumperH = L * 0.04
        let bumperY = belt - L * 0.004
        fillCapsule(context, CGRect(x: left + L * 0.05, y: bumperY, width: front.x - wheelR * 1.3 - (left + L * 0.05), height: bumperH), tone: skirtTone, vertical: false)
        fillCapsule(context, CGRect(x: front.x + wheelR * 1.3, y: bumperY, width: (rear.x - wheelR * 1.3) - (front.x + wheelR * 1.3), height: bumperH), tone: skirtTone, vertical: false)
        fillCapsule(context, CGRect(x: rear.x + wheelR * 1.3, y: bumperY, width: left + L * 0.97 - (rear.x + wheelR * 1.3), height: bumperH), tone: skirtTone, vertical: false)

        var windshield = Path()
        windshield.move(to: CGPoint(x: left + L * 0.115, y: groundY - L * 0.20))
        windshield.addQuadCurve(to: CGPoint(x: left + L * 0.235, y: roof + L * 0.045), control: CGPoint(x: left + L * 0.15, y: roof + L * 0.08))
        windshield.addLine(to: CGPoint(x: left + L * 0.255, y: roof + L * 0.055))
        windshield.addQuadCurve(to: CGPoint(x: left + L * 0.145, y: groundY - L * 0.175), control: CGPoint(x: left + L * 0.18, y: roof + L * 0.10))
        windshield.closeSubpath()
        fillShaded(context, windshield, tone: glass, from: CGPoint(x: left, y: roof), to: CGPoint(x: left + L * 0.3, y: belt))

        fillCapsule(context, CGRect(x: left + L * 0.275, y: roof + L * 0.055, width: L * 0.09, height: L * 0.11), tone: glass, vertical: true)
        fillCapsule(context, CGRect(x: left + L * 0.40, y: roof + L * 0.05, width: L * 0.30, height: L * 0.125), tone: glass, vertical: false)
        fillOval(context, CGRect(x: left + L * 0.43, y: roof + L * 0.065, width: L * 0.12, height: L * 0.03), Color.white.opacity(0.45))
        fillCapsule(context, CGRect(x: left + L * 0.18, y: groundY - L * 0.205, width: L * 0.74, height: L * 0.048), tone: stripe, vertical: false)
        context.draw(
            Text("911")
                .font(.system(size: L * 0.04, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.10, green: 0.28, blue: 0.55)),
            at: CGPoint(x: left + L * 0.15, y: groundY - L * 0.145)
        )
        drawLifeStar(context: context, center: CGPoint(x: left + L * 0.84, y: roof + L * 0.16), radius: L * 0.055)
        fillSphere(context, CGRect(x: left + L * 0.01, y: groundY - L * 0.17, width: L * 0.035, height: L * 0.028), tone: Tone(light: Color(red: 1, green: 0.95, blue: 0.7), base: Color(red: 1, green: 0.78, blue: 0.25), shade: Color(red: 0.75, green: 0.45, blue: 0.05)))
        fillSphere(context, CGRect(x: left + L * 0.955, y: roof + L * 0.08, width: L * 0.022, height: L * 0.04), tone: stripe)
    }

    private func drawVolumeWheel(context: GraphicsContext, center: CGPoint, radius: CGFloat, angle: CGFloat) {
        if let base = frames.wheelBase, let lugs = frames.wheelLugs, abs(frames.wheelRadius - radius) < 0.5 {
            let side = radius * 2
            context.draw(base, in: CGRect(x: center.x - radius, y: center.y - radius, width: side, height: side))
            var spun = context
            spun.translateBy(x: center.x, y: center.y)
            spun.rotate(by: .radians(angle))
            spun.draw(lugs, in: CGRect(x: -radius, y: -radius, width: side, height: side))
            return
        }
        drawWheelBase(context: context, center: center, radius: radius)
        var ctx = context
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: .radians(angle))
        ctx.translateBy(x: -center.x, y: -center.y)
        drawWheelLugs(context: ctx, center: center, radius: radius)
    }

    private func drawWheelBase(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let tire = Tone(light: Color(white: 0.32), base: Color(white: 0.12), shade: Color(white: 0.03))
        let rim = Tone(light: Color(white: 0.95), base: Color(white: 0.72), shade: Color(white: 0.40))
        fillSphere(context, CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2), tone: tire)
        let inner = radius * 0.58
        fillSphere(context, CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2), tone: rim)
    }

    private func drawWheelLugs(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let hub = Tone(light: Color(white: 0.78), base: Color(white: 0.5), shade: Color(white: 0.28))
        for i in 0..<5 {
            let a = CGFloat(i) * (.pi * 2 / 5)
            let lug = radius * 0.16
            let d = radius * 0.32
            fillSphere(context, CGRect(x: center.x + cos(a) * d - lug / 2, y: center.y + sin(a) * d - lug / 2, width: lug, height: lug), tone: hub)
        }
        let cap = radius * 0.14
        fillSphere(context, CGRect(x: center.x - cap, y: center.y - cap, width: cap * 2, height: cap * 2), tone: hub)
    }

    private func drawLifeStar(context: GraphicsContext, center: CGPoint, radius: CGFloat) {
        var star = Path()
        for i in 0..<12 {
            let angle = CGFloat(i) * (.pi / 6) - .pi / 2
            let r = i % 2 == 0 ? radius : radius * 0.48
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { star.move(to: point) } else { star.addLine(to: point) }
        }
        star.closeSubpath()
        context.fill(star, with: .color(SOSTheme.primaryRed))
        fillRound(context, CGRect(x: center.x - radius * 0.08, y: center.y - radius * 0.42, width: radius * 0.16, height: radius * 0.84), radius * 0.08, .white)
        fillRound(context, CGRect(x: center.x - radius * 0.28, y: center.y - radius * 0.08, width: radius * 0.56, height: radius * 0.16), radius * 0.08, .white)
    }

    private func fillShaded(_ context: GraphicsContext, _ path: Path, tone: Tone, from: CGPoint, to: CGPoint) {
        context.fill(
            path,
            with: .linearGradient(Gradient(colors: [tone.light, tone.base, tone.shade]), startPoint: from, endPoint: to)
        )
    }

    private func drawPatrolLight(
        context: GraphicsContext,
        at center: CGPoint,
        side: CGFloat,
        t: CGFloat,
        isRed: Bool
    ) {
        let on = isRed ? sin(t * .pi * 16) > 0 : sin(t * .pi * 16) <= 0
        let power: CGFloat = on ? 1 : 0.28
        let color: Color = isRed
            ? Color(red: 1, green: 0.18, blue: 0.16)
            : Color(red: 0.25, green: 0.48, blue: 1)
        let glowW = side * (on ? 0.36 : 0.18)
        let glowH = side * (on ? 0.24 : 0.12)
        fillOval(
            context,
            CGRect(x: center.x - glowW / 2, y: center.y - glowH * 0.78, width: glowW, height: glowH),
            color.opacity(0.42 * power)
        )
        let beamW = side * 0.07
        let beamH = side * (on ? 0.20 : 0.08)
        fillOval(
            context,
            CGRect(x: center.x - beamW / 2, y: center.y - beamH, width: beamW, height: beamH),
            color.opacity(0.34 * power)
        )
        let midW = side * 0.13
        let midH = side * 0.05
        fillOval(
            context,
            CGRect(x: center.x - midW / 2, y: center.y - midH / 2, width: midW, height: midH),
            color.opacity(0.95 * power)
        )
        let coreW = side * 0.055
        let coreH = side * 0.026
        fillOval(
            context,
            CGRect(x: center.x - coreW / 2, y: center.y - coreH / 2, width: coreW, height: coreH),
            Color.white.opacity(0.95 * power)
        )
    }

    // MARK: - Ciudad / calle

    private func drawCityLayer(context: GraphicsContext, size: CGSize) {
        let s = min(size.width / 340, size.height / 230)
        drawCityBackdrop(context: context, width: size.width, groundY: size.height * 0.78, s: s)
    }

    private func drawCityBackdrop(
        context: GraphicsContext,
        width w: CGFloat,
        groundY: CGFloat,
        s: CGFloat
    ) {
        let c = s * 1.42
        fillOval(context, CGRect(x: w * 0.08, y: groundY - 210 * c, width: w * 0.84, height: 120 * c), .white.opacity(0.07))

        let distant: [(CGFloat, CGFloat, CGFloat)] = [
            (-0.02, 0.18, 150), (0.16, 0.17, 188), (0.33, 0.16, 162),
            (0.48, 0.18, 200), (0.66, 0.15, 154), (0.80, 0.22, 176)
        ]
        for b in distant {
            let rect = CGRect(x: w * b.0, y: groundY - b.2 * c, width: w * b.1, height: b.2 * c)
            context.fill(Path(roundedRect: rect, cornerRadius: 4 * c), with: .color(Color.black.opacity(0.14)))
        }

        let buildings: [(CGFloat, CGFloat, CGFloat)] = [
            (0.00, 0.11, 108), (0.10, 0.13, 142), (0.22, 0.10, 96),
            (0.31, 0.15, 168), (0.45, 0.11, 122), (0.55, 0.13, 150),
            (0.67, 0.09, 90), (0.75, 0.12, 134), (0.86, 0.10, 112), (0.95, 0.08, 128)
        ]

        for (i, b) in buildings.enumerated() {
            let x = w * b.0
            let bw = w * b.1
            let bh = b.2 * c
            let rect = CGRect(x: x, y: groundY - bh, width: bw - 2 * c, height: bh)
            context.fill(Path(roundedRect: rect, cornerRadius: 5 * c), with: .color(Color.black.opacity(0.22)))
            context.fill(
                Path(roundedRect: rect.insetBy(dx: 2 * c, dy: 2 * c), cornerRadius: 4 * c),
                with: .color(Color.white.opacity(0.08))
            )
            let cols = max(2, Int(bw / (12 * c)))
            let rows = max(4, Int(bh / (16 * c)))
            var windows = Path()
            for row in 0..<rows {
                for col in 0..<cols where (row + col + i) % 3 != 0 {
                    let wx = rect.minX + 4 * c + CGFloat(col) * (bw / CGFloat(cols + 1))
                    let wy = rect.minY + 8 * c + CGFloat(row) * (bh / CGFloat(rows + 1))
                    windows.addEllipse(in: CGRect(x: wx, y: wy, width: 4.2 * c, height: 5.6 * c))
                }
            }
            context.fill(windows, with: .color(Color.yellow.opacity(0.34)))
        }

        for fxRel: CGFloat in [0.08, 0.38, 0.68, 0.92] {
            let fx = w * fxRel
            var pole = Path()
            pole.move(to: CGPoint(x: fx, y: groundY))
            pole.addLine(to: CGPoint(x: fx, y: groundY - 52 * c))
            context.stroke(pole, with: .color(Color.white.opacity(0.28)), lineWidth: 1.8 * c)
            fillOval(context, CGRect(x: fx - 5 * c, y: groundY - 60 * c, width: 10 * c, height: 10 * c), Color.yellow.opacity(0.45))
            fillOval(context, CGRect(x: fx - 16 * c, y: groundY - 54 * c, width: 32 * c, height: 20 * c), Color.yellow.opacity(0.10))
        }
    }

    private func drawRoad(context: GraphicsContext, width w: CGFloat, groundY: CGFloat, t: CGFloat, s: CGFloat) {
        context.fill(Path(CGRect(x: 0, y: groundY - 4 * s, width: w, height: 4 * s)), with: .color(Color.white.opacity(0.08)))
        var ground = Path()
        ground.move(to: CGPoint(x: 0, y: groundY))
        ground.addLine(to: CGPoint(x: w, y: groundY))
        context.stroke(ground, with: .color(.white.opacity(0.35)), lineWidth: 2.5 * s)

        let dash: CGFloat = 20 * s
        let gap: CGFloat = 14 * s
        var x = -dash + (t * (dash + gap) * 6).truncatingRemainder(dividingBy: dash + gap)
        while x < w {
            var d = Path()
            d.move(to: CGPoint(x: x, y: groundY + 10 * s))
            d.addLine(to: CGPoint(x: x + dash, y: groundY + 10 * s))
            context.stroke(d, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 3.2 * s, lineCap: .round))
            x += dash + gap
        }
    }

    private func drawSpeedStreaks(
        context: GraphicsContext,
        width w: CGFloat,
        groundY: CGFloat,
        s: CGFloat,
        amount: CGFloat,
        t: CGFloat
    ) {
        let rows = 8
        for i in 0..<rows {
            let y = groundY - CGFloat(16 + i * 18) * s
            let len = (28 + CGFloat((i * 3) % 5) * 18) * s * (0.35 + amount)
            let span = w + len + 40
            let shift = (t * (180 + amount * 520) + CGFloat(i) * 90).truncatingRemainder(dividingBy: span)
            let x = w - shift
            var line = Path()
            line.move(to: CGPoint(x: x, y: y))
            line.addLine(to: CGPoint(x: x - len, y: y))
            context.stroke(
                line,
                with: .color(Color.white.opacity(0.16 * amount)),
                style: StrokeStyle(lineWidth: (1.2 + CGFloat(i % 2)) * s, lineCap: .round)
            )
        }
    }

    /// Autos sin color, solo sombra, que la ambulancia deja atrás.
    private func drawShadowTraffic(
        context: GraphicsContext,
        vanX: CGFloat,
        ambulanceLength: CGFloat,
        groundY: CGFloat,
        amount: CGFloat
    ) {
        let cars: [(delay: CGFloat, scale: CGFloat, opacity: CGFloat)] = [
            (0.00, 0.70, 0.30),
            (0.16, 0.52, 0.18),
            (0.30, 0.62, 0.24)
        ]
        for car in cars {
            let local = min(1, max(0, (amount - car.delay) / 0.58))
            let pass = local * local * (3 - 2 * local)
            let carLen = ambulanceLength * car.scale
            let x = vanX - ambulanceLength * 1.35 + pass * (ambulanceLength * 2.7 + carLen)
            drawShadowCar(
                context: context,
                centerX: x,
                groundY: groundY,
                length: carLen,
                opacity: car.opacity
            )
        }
    }

    private func drawShadowCar(
        context: GraphicsContext,
        centerX: CGFloat,
        groundY: CGFloat,
        length: CGFloat,
        opacity: CGFloat
    ) {
        let h = length * 0.40
        let left = centerX - length / 2
        let floor = groundY - h * 0.08
        var body = Path()
        body.move(to: CGPoint(x: left + length * 0.04, y: floor - h * 0.22))
        body.addQuadCurve(
            to: CGPoint(x: left + length * 0.26, y: floor - h * 0.88),
            control: CGPoint(x: left + length * 0.10, y: floor - h * 0.42)
        )
        body.addLine(to: CGPoint(x: left + length * 0.58, y: floor - h * 0.90))
        body.addQuadCurve(
            to: CGPoint(x: left + length * 0.78, y: floor - h * 0.42),
            control: CGPoint(x: left + length * 0.74, y: floor - h * 0.88)
        )
        body.addLine(to: CGPoint(x: left + length * 0.96, y: floor - h * 0.34))
        body.addQuadCurve(
            to: CGPoint(x: left + length * 0.94, y: floor),
            control: CGPoint(x: left + length, y: floor - h * 0.12)
        )
        body.addLine(to: CGPoint(x: left + length * 0.06, y: floor))
        body.closeSubpath()
        context.fill(body, with: .color(Color.black.opacity(opacity)))

        let wheel = h * 0.22
        fillOval(
            context,
            CGRect(x: left + length * 0.18, y: floor - wheel * 0.55, width: wheel, height: wheel),
            Color.black.opacity(min(0.55, opacity + 0.12))
        )
        fillOval(
            context,
            CGRect(x: left + length * 0.68, y: floor - wheel * 0.55, width: wheel, height: wheel),
            Color.black.opacity(min(0.55, opacity + 0.12))
        )
    }

    // MARK: - Humanos con volumen (luz y sombra, sin contorno negro)

    private enum HumanPose {
        case sittingHelp(wave: CGFloat)
        case lying
        case standingMedic
    }


    private struct Tone {
        var light: Color
        var base: Color
        var shade: Color
    }

    private func drawSoftHuman(
        context: GraphicsContext,
        at ground: CGPoint,
        pose: HumanPose,
        s: CGFloat
    ) {
        let skin = Tone(
            light: Color(red: 1.0, green: 0.88, blue: 0.78),
            base: Color(red: 0.93, green: 0.72, blue: 0.58),
            shade: Color(red: 0.70, green: 0.46, blue: 0.36)
        )
        let hair = Tone(
            light: Color(red: 0.58, green: 0.38, blue: 0.24),
            base: Color(red: 0.33, green: 0.19, blue: 0.12),
            shade: Color(red: 0.14, green: 0.08, blue: 0.06)
        )
        let shirt = Tone(
            light: Color(red: 0.78, green: 0.90, blue: 0.98),
            base: Color(red: 0.36, green: 0.62, blue: 0.84),
            shade: Color(red: 0.18, green: 0.36, blue: 0.56)
        )
        let pants = Tone(
            light: Color(red: 0.48, green: 0.58, blue: 0.76),
            base: Color(red: 0.24, green: 0.34, blue: 0.54),
            shade: Color(red: 0.12, green: 0.18, blue: 0.32)
        )
        let shoe = Tone(
            light: Color(red: 0.62, green: 0.48, blue: 0.38),
            base: Color(red: 0.34, green: 0.22, blue: 0.16),
            shade: Color(red: 0.14, green: 0.08, blue: 0.06)
        )
        let bandage = Tone(light: .white, base: Color(white: 0.93), shade: Color(white: 0.74))

        switch pose {
        case .sittingHelp(let wave):
            castShadow(context, CGRect(x: ground.x - 18 * s, y: ground.y - 5 * s, width: 42 * s, height: 8 * s))
            drawVolumeLimb(context, from: CGPoint(x: ground.x - 2 * s, y: ground.y - 16 * s), to: CGPoint(x: ground.x - 14 * s, y: ground.y - 6 * s), thickness: 7.2 * s, tone: pants)
            drawShoe(context, at: CGPoint(x: ground.x - 16 * s, y: ground.y - 4 * s), s: s, tone: shoe)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 2 * s, y: ground.y - 15 * s), to: CGPoint(x: ground.x + 16 * s, y: ground.y - 13 * s), thickness: 7.6 * s, tone: pants)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 14 * s, y: ground.y - 13 * s), to: CGPoint(x: ground.x + 26 * s, y: ground.y - 11 * s), thickness: 7 * s, tone: bandage)
            fillRound(context, CGRect(x: ground.x + 18 * s, y: ground.y - 13.2 * s, width: 5 * s, height: 2.4 * s), 1 * s, SOSTheme.primaryRed.opacity(0.75))
            drawShoe(context, at: CGPoint(x: ground.x + 28 * s, y: ground.y - 8 * s), s: s, tone: shoe)

            fillTorso(context, CGRect(x: ground.x - 12 * s, y: ground.y - 40 * s, width: 24 * s, height: 26 * s), tone: shirt)
            fillSphere(context, CGRect(x: ground.x - 4 * s, y: ground.y - 42 * s, width: 8 * s, height: 7 * s), tone: skin)

            drawVolumeLimb(context, from: CGPoint(x: ground.x - 8 * s, y: ground.y - 34 * s), to: CGPoint(x: ground.x - 16 * s, y: ground.y - 24 * s), thickness: 6.2 * s, tone: shirt)
            drawVolumeLimb(context, from: CGPoint(x: ground.x - 16 * s, y: ground.y - 24 * s), to: CGPoint(x: ground.x - 18 * s, y: ground.y - 15 * s), thickness: 5 * s, tone: skin)
            fillSphere(context, CGRect(x: ground.x - 21 * s, y: ground.y - 18 * s, width: 6.2 * s, height: 6.2 * s), tone: skin)

            let lift = wave * 2 * s
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 8 * s, y: ground.y - 34 * s), to: CGPoint(x: ground.x + 14 * s, y: ground.y - 44 * s + lift), thickness: 6.2 * s, tone: shirt)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 14 * s, y: ground.y - 44 * s + lift), to: CGPoint(x: ground.x + 16 * s, y: ground.y - 52 * s + lift), thickness: 4.6 * s, tone: skin)
            fillSphere(context, CGRect(x: ground.x + 13 * s, y: ground.y - 55 * s + lift, width: 6 * s, height: 6 * s), tone: skin)

            drawSoftHead(context: context, center: CGPoint(x: ground.x, y: ground.y - 50 * s), s: s, skin: skin, hair: hair, tilt: 0)

        case .lying:
            fillTorso(context, CGRect(x: ground.x - 6 * s, y: ground.y - 18 * s, width: 24 * s, height: 14 * s), tone: shirt)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 14 * s, y: ground.y - 12 * s), to: CGPoint(x: ground.x + 28 * s, y: ground.y - 11 * s), thickness: 7 * s, tone: pants)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 24 * s, y: ground.y - 12 * s), to: CGPoint(x: ground.x + 34 * s, y: ground.y - 10 * s), thickness: 6.4 * s, tone: bandage)
            drawShoe(context, at: CGPoint(x: ground.x + 36 * s, y: ground.y - 8 * s), s: s * 0.9, tone: shoe)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 2 * s, y: ground.y - 14 * s), to: CGPoint(x: ground.x + 14 * s, y: ground.y - 8 * s), thickness: 4.4 * s, tone: skin)
            fillSphere(context, CGRect(x: ground.x + 12 * s, y: ground.y - 10 * s, width: 5 * s, height: 5 * s), tone: skin)
            drawSoftHead(context: context, center: CGPoint(x: ground.x - 16 * s, y: ground.y - 14 * s), s: s, skin: skin, hair: hair, tilt: -72)

        case .standingMedic:
            let coat = Tone(
                light: .white,
                base: Color(red: 0.90, green: 0.93, blue: 0.95),
                shade: Color(red: 0.68, green: 0.74, blue: 0.80)
            )
            let medicHair = Tone(
                light: Color(red: 0.42, green: 0.30, blue: 0.24),
                base: Color(red: 0.20, green: 0.13, blue: 0.11),
                shade: Color(red: 0.08, green: 0.05, blue: 0.05)
            )
            castShadow(context, CGRect(x: ground.x - 14 * s, y: ground.y - 5 * s, width: 28 * s, height: 8 * s))
            drawVolumeLimb(context, from: CGPoint(x: ground.x - 4 * s, y: ground.y - 30 * s), to: CGPoint(x: ground.x - 5 * s, y: ground.y - 4 * s), thickness: 6.6 * s, tone: pants)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 4 * s, y: ground.y - 30 * s), to: CGPoint(x: ground.x + 6 * s, y: ground.y - 4 * s), thickness: 6.6 * s, tone: pants)
            drawShoe(context, at: CGPoint(x: ground.x - 8 * s, y: ground.y - 3 * s), s: s, tone: shoe)
            drawShoe(context, at: CGPoint(x: ground.x + 3 * s, y: ground.y - 3 * s), s: s, tone: shoe)
            fillTorso(context, CGRect(x: ground.x - 13 * s, y: ground.y - 52 * s, width: 26 * s, height: 32 * s), tone: coat)
            fillRound(context, CGRect(x: ground.x - 1.5 * s, y: ground.y - 42 * s, width: 3 * s, height: 12 * s), 1.2 * s, SOSTheme.primaryRed)
            fillRound(context, CGRect(x: ground.x - 6 * s, y: ground.y - 38.2 * s, width: 12 * s, height: 3 * s), 1.2 * s, SOSTheme.primaryRed)
            drawVolumeLimb(context, from: CGPoint(x: ground.x - 10 * s, y: ground.y - 46 * s), to: CGPoint(x: ground.x - 18 * s, y: ground.y - 34 * s), thickness: 6.2 * s, tone: coat)
            drawVolumeLimb(context, from: CGPoint(x: ground.x - 18 * s, y: ground.y - 34 * s), to: CGPoint(x: ground.x - 22 * s, y: ground.y - 24 * s), thickness: 4.8 * s, tone: skin)
            fillSphere(context, CGRect(x: ground.x - 25 * s, y: ground.y - 26.5 * s, width: 6.2 * s, height: 6.2 * s), tone: skin)
            drawVolumeLimb(context, from: CGPoint(x: ground.x + 10 * s, y: ground.y - 46 * s), to: CGPoint(x: ground.x + 16 * s, y: ground.y - 32 * s), thickness: 6.2 * s, tone: coat)
            fillCapsule(context, CGRect(x: ground.x - 3.5 * s, y: ground.y - 64 * s, width: 7 * s, height: 20 * s), tone: skin, vertical: true)
            fillCapsule(context, CGRect(x: ground.x - 7 * s, y: ground.y - 50 * s, width: 14 * s, height: 8 * s), tone: coat, vertical: false)
            drawSoftHead(context: context, center: CGPoint(x: ground.x, y: ground.y - 62 * s), s: s, skin: skin, hair: medicHair, tilt: 0)
        }
    }

    private func drawSoftHead(
        context: GraphicsContext,
        center: CGPoint,
        s: CGFloat,
        skin: Tone,
        hair: Tone,
        tilt: CGFloat
    ) {
        var ctx = context
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: .degrees(tilt))
        ctx.translateBy(x: -center.x, y: -center.y)

        let r = 8.2 * s
        fillSphere(ctx, CGRect(x: center.x - r * 1.15, y: center.y - r * 1.25, width: r * 2.15, height: r * 1.7), tone: hair)
        fillSphere(ctx, CGRect(x: center.x - r, y: center.y - r * 0.95, width: r * 2.05, height: r * 2.2), tone: skin)
        fillSphere(ctx, CGRect(x: center.x - r * 1.05, y: center.y - r * 1.35, width: r * 2.1, height: r * 1.35), tone: hair)
        fillSphere(ctx, CGRect(x: center.x - r * 0.2, y: center.y - r * 1.05, width: r * 0.85, height: r * 0.55), tone: hair)
        fillOval(ctx, CGRect(x: center.x - r * 0.55, y: center.y - r * 1.15, width: r * 0.7, height: r * 0.28), hair.light.opacity(0.55))
    }

    private func drawStretcher(
        context: GraphicsContext,
        at point: CGPoint,
        withPatient: Bool,
        s: CGFloat
    ) {
        let pad = Tone(
            light: Color(red: 0.98, green: 0.99, blue: 1),
            base: Color(red: 0.86, green: 0.90, blue: 0.94),
            shade: Color(red: 0.62, green: 0.68, blue: 0.74)
        )
        let metal = Tone(
            light: Color(white: 0.82),
            base: Color(white: 0.55),
            shade: Color(white: 0.32)
        )
        castShadow(context, CGRect(x: point.x - 36 * s, y: point.y - 5 * s, width: 72 * s, height: 8 * s))
        fillCapsule(context, CGRect(x: point.x - 36 * s, y: point.y - 16 * s, width: 70 * s, height: 12 * s), tone: pad, vertical: false)
        fillSphere(context, CGRect(x: point.x - 34 * s, y: point.y - 20 * s, width: 16 * s, height: 10 * s), tone: pad)
        fillSphere(context, CGRect(x: point.x - 22 * s, y: point.y - 7 * s, width: 8 * s, height: 8 * s), tone: metal)
        fillSphere(context, CGRect(x: point.x + 14 * s, y: point.y - 7 * s, width: 8 * s, height: 8 * s), tone: metal)

        if withPatient {
            drawSoftHuman(context: context, at: CGPoint(x: point.x - 2 * s, y: point.y - 6 * s), pose: .lying, s: s)
        }

        drawSoftHuman(context: context, at: CGPoint(x: point.x + 42 * s, y: point.y), pose: .standingMedic, s: s)
    }

    // MARK: - Helpers

    private func fillOval(_ context: GraphicsContext, _ rect: CGRect, _ color: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private func fillRound(_ context: GraphicsContext, _ rect: CGRect, _ radius: CGFloat, _ color: Color) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
    }

    private func fillSphere(_ context: GraphicsContext, _ rect: CGRect, tone: Tone) {
        let path = Path(ellipseIn: rect)
        context.fill(
            path,
            with: .radialGradient(
                Gradient(colors: [tone.light, tone.base, tone.shade]),
                center: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY - rect.height * 0.22),
                startRadius: 0,
                endRadius: max(rect.width, rect.height) * 0.72
            )
        )
    }

    private func fillCapsule(_ context: GraphicsContext, _ rect: CGRect, tone: Tone, vertical: Bool) {
        let radius = min(rect.width, rect.height) / 2
        let path = Path(roundedRect: rect, cornerRadius: radius)
        let start = vertical
            ? CGPoint(x: rect.minX, y: rect.midY)
            : CGPoint(x: rect.midX, y: rect.minY)
        let end = vertical
            ? CGPoint(x: rect.maxX, y: rect.midY)
            : CGPoint(x: rect.midX, y: rect.maxY)
        context.fill(
            path,
            with: .linearGradient(Gradient(colors: [tone.light, tone.base, tone.shade]), startPoint: start, endPoint: end)
        )
    }

    private func fillTorso(_ context: GraphicsContext, _ rect: CGRect, tone: Tone) {
        let x = rect.minX
        let y = rect.minY
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: x + w * 0.12, y: y + h * 0.16))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.88, y: y + h * 0.16), control: CGPoint(x: x + w * 0.5, y: y))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.76, y: y + h), control: CGPoint(x: x + w, y: y + h * 0.55))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.24, y: y + h), control: CGPoint(x: x + w * 0.5, y: y + h * 1.08))
        path.addQuadCurve(to: CGPoint(x: x + w * 0.12, y: y + h * 0.16), control: CGPoint(x: x, y: y + h * 0.55))
        path.closeSubpath()
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [tone.light, tone.base, tone.shade]),
                startPoint: CGPoint(x: x, y: y),
                endPoint: CGPoint(x: x + w, y: y + h)
            )
        )
        fillOval(context, CGRect(x: x + w * 0.18, y: y + h * 0.22, width: w * 0.28, height: h * 0.36), tone.light.opacity(0.35))
    }

    private func drawVolumeLimb(
        _ context: GraphicsContext,
        from: CGPoint,
        to: CGPoint,
        thickness: CGFloat,
        tone: Tone
    ) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let length = max(hypot(dx, dy), 0.5)
        var ctx = context
        ctx.translateBy(x: from.x, y: from.y)
        ctx.rotate(by: .radians(atan2(dy, dx)))
        let rect = CGRect(x: -thickness * 0.2, y: -thickness / 2, width: length + thickness * 0.35, height: thickness)
        fillCapsule(ctx, rect, tone: tone, vertical: false)
        let streak = CGRect(x: rect.minX + thickness * 0.25, y: rect.minY + thickness * 0.16, width: max(length * 0.7, 1), height: thickness * 0.22)
        ctx.fill(Path(roundedRect: streak, cornerRadius: thickness * 0.11), with: .color(tone.light.opacity(0.45)))
    }

    private func drawShoe(_ context: GraphicsContext, at point: CGPoint, s: CGFloat, tone: Tone) {
        fillCapsule(context, CGRect(x: point.x, y: point.y - 2.2 * s, width: 9 * s, height: 4.6 * s), tone: tone, vertical: false)
    }

    private func castShadow(_ context: GraphicsContext, _ rect: CGRect) {
        fillOval(context, rect.insetBy(dx: -rect.width * 0.04, dy: 0), Color.black.opacity(0.10))
        fillOval(context, rect, Color.black.opacity(0.16))
    }

    private func stretcherSnapshotBox(s: CGFloat) -> (size: CGSize, anchor: CGPoint) {
        (CGSize(width: 140 * s, height: 96 * s), CGPoint(x: 52 * s, y: 82 * s))
    }

    private func prepareFrames(size: CGSize) {
        guard size.width > 8, size.height > 8 else { return }
        let s = min(size.width / 340, size.height / 230)
        let people = s * 0.68
        let length = ambulanceLength(width: size.width, height: size.height, groundY: size.height * 0.78)
        if frames.body != nil, abs(frames.bodyLength - length) < 0.5, abs(frames.people - people) < 0.5 {
            return
        }

        let top = length * 0.50
        let bodySize = CGSize(width: length, height: top + length * 0.10)
        frames.body = raster(bodySize) { context, _ in
            self.drawAmbulanceChassis(context: context, centerX: length / 2, groundY: top, length: length)
        }
        frames.bodyTop = top
        frames.bodyHeight = bodySize.height
        frames.bodyLength = length

        let radius = length * 0.078
        let wheelSize = CGSize(width: radius * 2, height: radius * 2)
        let wheelCenter = CGPoint(x: radius, y: radius)
        frames.wheelBase = raster(wheelSize) { context, _ in
            self.drawWheelBase(context: context, center: wheelCenter, radius: radius)
        }
        frames.wheelLugs = raster(wheelSize) { context, _ in
            self.drawWheelLugs(context: context, center: wheelCenter, radius: radius)
        }
        frames.wheelRadius = radius

        let box = stretcherSnapshotBox(s: people)
        frames.stretcherEmpty = raster(box.size) { context, _ in
            self.drawStretcher(context: context, at: box.anchor, withPatient: false, s: people)
        }
        frames.stretcherFull = raster(box.size) { context, _ in
            self.drawStretcher(context: context, at: box.anchor, withPatient: true, s: people)
        }
        frames.people = people
    }

    private func raster(_ size: CGSize, draw: @escaping (GraphicsContext, CGSize) -> Void) -> Image? {
        let canvas = Canvas(opaque: false, rendersAsynchronously: false) { context, canvasSize in
            draw(context, canvasSize)
        }
        .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = displayScale
        renderer.isOpaque = false
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        guard let uiImage = renderer.uiImage else { return nil }
        return Image(uiImage: uiImage)
    }

    private func easeOut(_ t: CGFloat) -> CGFloat { 1 - pow(1 - t, 3) }
    private func easeIn(_ t: CGFloat) -> CGFloat { t * t * t }
    private func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
    }
}

private final class RescueFrames {
    var body: Image?
    var bodyTop: CGFloat = 0
    var bodyHeight: CGFloat = 0
    var bodyLength: CGFloat = -1
    var wheelBase: Image?
    var wheelLugs: Image?
    var wheelRadius: CGFloat = -1
    var stretcherEmpty: Image?
    var stretcherFull: Image?
    var people: CGFloat = -1
}

#Preview {
    ZStack {
        SOSTheme.primaryRed.ignoresSafeArea()
        VStack {
            SOSBrandMark(size: .welcome, showsPlace: true, centered: true)
            AmbulanceRescueAnimation()
        }
    }
}
