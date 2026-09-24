import CrocoCrossCore
import SwiftUI

struct HowToView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    controlCard(right: false)
                    controlCard(right: true)
                }
                lesson("LAND IT", icon: "arrow.down.right", color: CrocoTheme.orange) {
                    Text("Match the slope. Land on your wheels to keep your speed — and bank your flips.")
                }
                lesson("MAKE IT COUNT", icon: "arrow.clockwise", color: CrocoTheme.lime) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("BACKFLIP", systemImage: "arrow.counterclockwise")
                            Spacer()
                            Label("FRONTFLIP", systemImage: "arrow.clockwise")
                        }.font(.system(size: 11, weight: .black, design: .rounded))
                        Text("Either direction. Same reward.")
                        HStack(spacing: 8) {
                            flipReward("SINGLE", count: 1)
                            flipReward("DOUBLE", count: 2)
                            flipReward("TRIPLE", count: 3)
                        }
                        Text("Link rotations in one jump. Points count after a safe landing.")
                        Label("Every metre = 10 points", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                            .foregroundStyle(CrocoTheme.lime).font(.subheadline.bold())
                    }
                }
                HStack(alignment: .top, spacing: 12) {
                    modeCard("WEEKLY", icon: "flag.checkered", text: "\(GameSession.weeklyDistanceText) m · 1 life\nCanyon for now. The exact same course for every player all week.\nA new shared course every Monday.\nFinish bonus: +1,000.")
                    modeCard("ENDLESS", icon: "infinity", text: "3 lives · No finish line\nA new random course on every ride, in your chosen world.\nSeparate records and Game Center leaderboards for each world.\nBoth modes work offline.")
                }
            }.padding(18).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(CrocoTheme.ink).accessibilityIdentifier("howToContent")
    }

    private func controlCard(right: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let image = GameAssets.image(named: right ? "control-throttle" : "control-brake") {
                Image(uiImage: image).resizable().scaledToFit().frame(height: 82).frame(maxWidth: .infinity)
            }
            Text(right ? "GO + LEAN BACK" : "BRAKE + LEAN FORWARD")
                .font(.custom("AvenirNextCondensed-HeavyItalic", size: 19)).fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(right ? CrocoTheme.lime : CrocoTheme.orange)
            Text(right ? "Hold anywhere in the lower-right control area to accelerate. In the air, rotate backward." : "Hold anywhere in the lower-left control area to brake. In the air, rotate forward.")
            Text("The button settles under your thumb until you lift. Short taps give finer control.").font(.caption.bold()).foregroundStyle(.white)
        }.font(.subheadline).foregroundStyle(CrocoTheme.muted)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(14).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
    }

    private func lesson<Content: View>(_ title: String, icon: String, color: Color,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.custom("AvenirNextCondensed-HeavyItalic", size: 25))
                .foregroundStyle(color)
            content().font(.subheadline).foregroundStyle(CrocoTheme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
    }

    private func flipReward(_ title: String, count: Int) -> some View {
        VStack(spacing: 4) {
            Text(GameSimulation.flipBonus(for: count).formatted()).font(.system(size: 20, weight: .black, design: .rounded))
            Text(title).font(.system(size: 8, weight: .heavy, design: .monospaced))
        }.foregroundStyle(CrocoTheme.lime).frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(CrocoTheme.lime.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func modeCard(_ title: String, icon: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.system(size: 14, weight: .black, design: .rounded)).foregroundStyle(.white)
            Text(text).font(.caption).foregroundStyle(CrocoTheme.muted).lineSpacing(5)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(14)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 18))
    }
}
