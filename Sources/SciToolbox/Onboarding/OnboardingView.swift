import SwiftUI

// MARK: - OnboardingView（I1：首启引导）

/// 全屏 sheet 首启引导，3 页卡片。
/// `@AppStorage("onboardingDone")` 判转；设置页"重新查看引导"重置。
struct OnboardingView: View {
    @AppStorage("onboardingDone") private var onboardingDone = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var currentPage = 0

    private let totalPages = 3

    var body: some View {
        if !onboardingDone {
            ZStack {
                // 遮罩
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture { finish() }

                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        page1.tag(0)
                        page2.tag(1)
                        page3.tag(2)
                    }
                    .tabViewStyle(.automatic)
                    .frame(maxHeight: 400)

                    // 页面指示器 + 按钮
                    HStack(spacing: Theme.sp4) {
                        // 跳过
                        Button(action: finish) {
                            Text(L10n.t(.close))
                                .font(.system(size: Theme.fsSmall))
                                .foregroundColor(Theme.ink3)
                        }
                        .buttonStyle(PressableButtonStyle())

                        Spacer()

                        // 上一步
                        if currentPage > 0 {
                            Button(action: { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { currentPage -= 1 } }) {
                                Text(L10n.t(.back))
                                    .font(.system(size: Theme.fsSmall))
                                    .foregroundColor(Theme.accent)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }

                        // 下一步 / 完成
                        if currentPage < totalPages - 1 {
                            Button(action: { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { currentPage += 1 } }) {
                                Text(L10n.t(.done))
                                    .font(.system(size: Theme.fsSmall, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Theme.sp4)
                                    .padding(.vertical, Theme.sp2)
                                    .background(Theme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
                            }
                            .buttonStyle(PressableButtonStyle())
                        } else {
                            Button(action: finish) {
                                Text(L10n.t(.quickStart))
                                    .font(.system(size: Theme.fsSmall, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, Theme.sp4)
                                    .padding(.vertical, Theme.sp2)
                                    .background(Theme.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusSm))
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(.horizontal, Theme.sp5)
                    .padding(.bottom, Theme.sp4)
                }
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusLg)
                        .strokeBorder(Theme.lineStrong, lineWidth: 0.5)
                )
                .padding(.horizontal, Theme.sp8)
                .padding(.vertical, Theme.sp8)
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.3))
        }
    }

    // MARK: - Pages

    private var page1: some View {
        VStack(spacing: Theme.sp4) {
            Image(systemName: "flask.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.accent)
                .frame(height: 60)
            Text(L10n.t(.onboardingTitle1))
                .font(.system(size: Theme.fsLargeTitle, weight: .bold))
                .foregroundColor(Theme.ink)
            VStack(alignment: .leading, spacing: Theme.sp2) {
                onboardBullet(DT.t("15 个公开学术数据库，原生渲染零 WebView", "15 public academic databases, native rendering, zero WebView"))
                onboardBullet(DT.t("本地工具：序列计算、比对、蛋白分析——全部离线", "Local tools: sequence compute, alignment, protein analysis — all offline"))
                onboardBullet(DT.t("剪贴板智能识别、跨库互链、项目集合", "Clipboard smart detect, cross-database links, project collections"))
            }
            .padding(.horizontal, Theme.sp5)
        }
        .padding()
    }

    private var page2: some View {
        VStack(spacing: Theme.sp4) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.categoryColor(.localTools))
                .frame(height: 60)
            Text(L10n.t(.onboardingTitle2))
                .font(.system(size: Theme.fsLargeTitle, weight: .bold))
                .foregroundColor(Theme.ink)
            VStack(alignment: .leading, spacing: Theme.sp2) {
                onboardBullet(DT.t("断网也能用——序列反向互补、GC 含量、翻译", "Works offline — reverse complement, GC content, translation"))
                onboardBullet(DT.t("本地比对（全局/局部）与蛋白理化性质计算", "Local alignment (global/local) and protein property calculations"))
                onboardBullet(DT.t("收藏离线快照 + 本地全文搜索", "Offline favorite snapshots + local full-text search"))
            }
            .padding(.horizontal, Theme.sp5)
        }
        .padding()
    }

    private var page3: some View {
        VStack(spacing: Theme.sp4) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Theme.accent)
                .frame(height: 60)
            Text(L10n.t(.onboardingTitle3))
                .font(.system(size: Theme.fsLargeTitle, weight: .bold))
                .foregroundColor(Theme.ink)
            VStack(alignment: .leading, spacing: Theme.sp2) {
                onboardBullet(DT.t("收藏、集合、结果集——你的研究资产永不丢失", "Favorites, collections, result sets — your research assets persist"))
                onboardBullet(DT.t("一键备份/恢复，数据仅存本机", "One-click backup/restore, data stays on this Mac"))
                onboardBullet(DT.t("导入 FASTA/FASTQ/GenBank/GFF3 文件分析", "Import FASTA/FASTQ/GenBank/GFF3 files for analysis"))
            }
            .padding(.horizontal, Theme.sp5)
        }
        .padding()
    }

    private func onboardBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.sp2) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Theme.semanticSuccess)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: Theme.fsSmall))
                .foregroundColor(Theme.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func finish() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            onboardingDone = true
        }
    }
}
