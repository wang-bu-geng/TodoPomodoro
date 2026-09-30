import SwiftUI

struct PomodoroView: View {
    @EnvironmentObject var vm: PomodoroViewModel
    @EnvironmentObject var settingsVM: SettingsViewModel
    @State private var showSettings = false
    @State private var ringTransitionScale: CGFloat = 1.0
    @State private var showParticleBurst = false
    @State private var particlePhase: PomodoroPhase = .focus
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let circleSize = min(size.width, size.height) * 0.65
            
            ZStack {
                // 主题背景（全屏统一渲染）
                BackgroundView(settings: settingsVM)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: vm.phase)
                
                // 半透明叠加层
                vm.phase.color.opacity(0.15)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.4), value: vm.phase)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 40)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("番茄钟")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("保持节奏，完成当前任务")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.48))
                            }
                            
                            Spacer()
                            
                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.78))
                                    .frame(width: 38, height: 38)
                                    .background(.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.bottom, 28)
                        
                        Label(vm.statusText, systemImage: vm.phase.icon)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(vm.phase.color)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(vm.phase.color.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .contentTransition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: vm.phase)
                            .padding(.bottom, 18)
                        
                        if !vm.focusTaskTitle.isEmpty {
                            Label(vm.focusTaskTitle, systemImage: "target")
                                .font(.footnote.weight(.medium))
                                .lineLimit(1)
                                .foregroundStyle(.white.opacity(0.78))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.bottom, 18)
                        }
                        
                        // 圆形计时器
                        ZStack {
                            // 粒子绽放层
                            if showParticleBurst {
                                ParticleBurstView(color: particlePhase.color)
                                    .transition(.opacity)
                            }
                            
                            // 背景圆环
                            Circle()
                                .stroke(.white.opacity(0.08), lineWidth: 10)
                                .frame(width: circleSize, height: circleSize)
                            
                            // 进度圆环
                            Circle()
                                .trim(from: 0, to: vm.progress)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [
                                            vm.phase.color.opacity(0.6),
                                            vm.phase.color,
                                            vm.phase.color.opacity(0.8)
                                        ]),
                                        center: .center,
                                        startAngle: .degrees(-90),
                                        endAngle: .degrees(270)
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: circleSize * ringTransitionScale,
                                       height: circleSize * ringTransitionScale)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: vm.progress)
                                .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 15), value: ringTransitionScale)
                            
                            // 时间显示
                            VStack(spacing: 6) {
                                Text(vm.timeString)
                                    .font(.system(size: circleSize * 0.24, weight: .light, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .shadow(color: vm.phase.color.opacity(0.28), radius: 16)
                                    .contentTransition(.numericText(countsDown: true))
                                    .animation(.easeInOut(duration: 0.2), value: vm.phase)
                                
                                Text(vm.phase == .focus ? "专注" : "休息")
                                    .font(.callout)
                                    .foregroundStyle(.white.opacity(0.42))
                                    .fontWeight(.light)
                                    .contentTransition(.opacity)
                                    .animation(.easeInOut(duration: 0.3), value: vm.phase)
                            }
                        }
                        .frame(height: circleSize + 40)
                        .padding(.bottom, 40)
                        
                        // 控制按钮
                        HStack(spacing: 28) {
                            controlButton(icon: "arrow.counterclockwise", action: vm.reset)
                                .disabled(vm.isRunning)
                                .opacity(vm.isRunning ? 0.3 : 1)
                            
                            Button(action: { vm.isRunning ? vm.pause() : vm.start() }) {
                                ZStack {
                                    Circle()
                                        .fill(vm.phase.color)
                                        .frame(width: 72, height: 72)
                                        .shadow(color: vm.phase.color.opacity(0.28), radius: 16, y: 8)
                                        .animation(.easeInOut(duration: 0.4), value: vm.phase)
                                    
                                    Image(systemName: vm.isRunning ? "pause.fill" : "play.fill")
                                        .font(.system(size: 26))
                                        .foregroundStyle(.white)
                                }
                            }
                            .transition(.opacity)
                            
                            controlButton(icon: "forward.fill", action: vm.skip)
                        }
                        .padding(.bottom, 28)
                        .animation(.easeInOut(duration: 0.3).delay(0.1), value: vm.phase)
                        
                        // 统计信息
                        HStack(spacing: 30) {
                            statItem(value: "\(vm.completedSessions)", label: "完成轮次", color: .orange)
                            statItem(value: "\(vm.totalFocusMinutes)", label: "专注分钟", color: .orange.opacity(0.7))
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .animation(.easeInOut(duration: 0.3).delay(0.2), value: vm.phase)
                        
                        // ④ UISegmentedControl 放底部
                        PhaseSegmentedControl(phase: Binding(
                            get: { vm.phase },
                            set: { newPhase in
                                withAnimation(.interpolatingSpring(mass: 0.8, stiffness: 200, damping: 12)) {
                                    vm.switchTo(newPhase)
                                }
                                triggerRingTransition(to: newPhase)
                            }
                        ))
                        .padding(.top, 16)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 30)
                    .frame(minHeight: geometry.size.height)
                }
            }
            // 左右滑动切换
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        if abs(horizontalAmount) > 60 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if horizontalAmount < 0 {
                                    vm.switchToNextPhase()
                                } else {
                                    vm.switchToPreviousPhase()
                                }
                            }
                            triggerRingTransition(to: vm.phase)
                        }
                    }
            )
        }
        .overlay(completionOverlay)
        // ⑤ 设置改成 Sheet
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settingsVM)
                .environmentObject(vm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: vm.phase) { _, newPhase in
            if !vm.showCompletionAnimation {
                triggerRingTransition(to: newPhase)
            }
        }
    }
    
    // MARK: - Ring Transition
    
    private func triggerRingTransition(to phase: PomodoroPhase) {
        particlePhase = phase
        
        withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 300, damping: 10)) {
            ringTransitionScale = 0.85
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 200, damping: 12)) {
                ringTransitionScale = 1.0
            }
            
            showParticleBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showParticleBurst = false
                }
            }
        }
    }
    
    // MARK: - Control Button
    
    private func controlButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(.white.opacity(0.08))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.7))
                )
        }
    }
    
    // MARK: - Stat Item
    
    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: value)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Completion Overlay
    
    @ViewBuilder
    private var completionOverlay: some View {
        if vm.showCompletionAnimation {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if #available(iOS 18.0, *) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce, options: .repeat(2))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.green)
                    }
                    
                    Text("已完成")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("休息一下，然后继续下一轮")
                        .foregroundStyle(.white.opacity(0.7))
                }
                .transition(.scale.combined(with: .opacity))
            }
            .transition(.opacity)
        }
    }
}

// MARK: - ④ 原生 UISegmentedControl（300pt 宽, 36pt 高, 圆角 10pt）

struct PhaseSegmentedControl: View {
    @Binding var phase: PomodoroPhase
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(PomodoroPhase.allCases, id: \.self) { p in
                Button(action: { phase = p }) {
                    Text(p.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(phase == p ? .black : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(phase == p ? .white : .clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: 300)
    }
}

// MARK: - 粒子绽放效果

struct ParticleBurstView: View {
    let color: Color
    @State private var particles: [(offset: CGSize, opacity: Double)] = []
    
    private let particleCount = 12
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { i in
                Circle()
                    .fill(color.opacity(particles[safe: i]?.opacity ?? 0))
                    .frame(width: 4, height: 4)
                    .offset(particles[safe: i]?.offset ?? .zero)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                particles = (0..<particleCount).map { i in
                    let angle = Double(i) / Double(particleCount) * .pi * 2
                    let distance: CGFloat = 30 + CGFloat.random(in: 10...40)
                    return (
                        offset: CGSize(
                            width: cos(angle) * distance,
                            height: sin(angle) * distance
                        ),
                        opacity: 0.8
                    )
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    for i in 0..<particles.count {
                        if i < particles.count {
                            let newOffset = CGSize(
                                width: particles[i].offset.width * 1.5,
                                height: particles[i].offset.height * 1.5
                            )
                            particles[i] = (offset: newOffset, opacity: 0)
                        }
                    }
                }
            }
        }
    }
}

// Safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}
