//
//  View+PreventScreenGrab.swift
//  PreventScreenGrab
//
//  Created by Daniel Bonates on 10/02/23.
//

import SwiftUI


public extension View {

    // MARK: - Private Properties

    private var snapshotBridge: SnaphotSafeViewSwiftUIBridge<Self> {
        SnaphotSafeViewSwiftUIBridge(content: self)
    }

    // MARK: - Public Methods

    /// Wrapped `View` in`ScreenshotProtectController`, will be hidden from system screenshots, during ``condition`` is true
    /// - Parameter condition: During condittion is true, return wrapped `View`
    /// - Returns: Wrapped `View` or just `Self`, depend at condition
    @ViewBuilder
    func hiddenFromSystemSnaphot(when condition: @autoclosure () -> Bool) -> some View {
        if condition() {
            snapshotBridge.hiddenFromSystemSnaphot()
        } else {
            self
        }
    }

    /// Wrapped `View` in`ScreenshotProtectController` with default padding, will be hidden from system screenshots, during ``condition`` is true
    /// - Parameter condition: During condittion is true, return wrapped `View`
    /// - Returns: Wrapped `View` or just `Self`, depend at condition
    @ViewBuilder
    func hiddenFromSystemSnaphotWithDefaultPadding(when condition: @autoclosure () -> Bool) -> some View {
        if condition() {
            snapshotBridge.hiddenFromSystemSnaphot()
                .padding(.vertical)
        } else {
            self
        }
    }

}

struct SnaphotSafeViewSwiftUIBridge<Content: View>: SnaphotSafeViewSwiftUIBridgeProtocol {

    // MARK: - Private Properties

    private let content: () -> Content

    // MARK: - Initialization

    init(content: @autoclosure @escaping () -> Content) {
        self.content = content
    }

    // MARK: - SnaphotSafeViewSwiftUIBridgeProtocol

    typealias ProtectedView = ProtectedViewRepresentable

    func hiddenFromSystemSnaphot() -> ProtectedView {
        let hostingController = UIHostingController(rootView: content())
        return ProtectedViewRepresentable(content: hostingController.view)
    }
    
    struct ProtectedViewRepresentable: UIViewRepresentable {

        // MARK: - Internal Properties

        let viewContent: UIView

        // MARK: - Initialization

        init(content: UIView) {
            self.viewContent = content
        }

        // MARK: - UIViewRepresentable

        func makeUIView(context: Context) -> UIView {
            let snapshotController = ScreenshotProtectController(content: viewContent)
            snapshotController.setupContentAsHiddenInScreenshotMode()
            snapshotController.container.setContentHuggingPriority(.required, for: .vertical)
            snapshotController.container.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
            return snapshotController.container
        }

        func updateUIView(_ uiView: UIView, context: Context) { }
        
    }

}

protocol SnaphotSafeViewSwiftUIBridgeProtocol {

    associatedtype ProtectedView: View

    func hiddenFromSystemSnaphot() -> ProtectedView
    
}

open class ScreenshotProtectController<Content: UIView>: ScreenshotProtectControllerProtocol {
    
    public typealias ProtectiveContainer = ScreenshotInvincibleContainerProtocol
    
    /// - View, which will be hidden on screenshots and screen recording
    /// - All operation with UI customization need perform at content
    public var content: Content
    
    /// - Container view, all operation with layout need perform at container
    public lazy var container: ProtectiveContainer = ScreenshotInvincibleContainer(content: content)
    
    public init(content: Content) {
        self.content = content
    }
    
    public func eraseOldAndAddnewContent(_ newContent: Content) {
        container.eraseOldAndAddnewContent(newContent)
    }
    
    public func setupContentAsHiddenInScreenshotMode() {
        container.setupContanerAsHideContentInScreenshots()
    }
    
    public func setupContentAsDisplayedInScreenshotMode() {
        container.setupContanerAsDisplayContentInScreenshots()
    }

}

public protocol ScreenshotProtectControllerProtocol {
    
    associatedtype Content
    associatedtype ProtectiveContainer
    
    var content: Content { get set }
    var container: ProtectiveContainer { get set }
    
    func eraseOldAndAddnewContent(_ newContent: Content)
    func setupContentAsHiddenInScreenshotMode()
    func setupContentAsDisplayedInScreenshotMode()
    
}

extension ScreenshotProtectControllerProtocol where Self: ScreenshotInvincibleContainerProtocol {
    
    func setupContentAsHiddenInScreenshotMode() {
        setupContentAsDisplayedInScreenshotMode()
    }
    
    func setupContentAsDisplayedInScreenshotMode() {
        setupContentAsDisplayedInScreenshotMode()
    }
    
}
public protocol ScreenshotInvincibleContainerProtocol: UIView {

    func eraseOldAndAddnewContent(_ newContent: UIView)
    func setupContanerAsHideContentInScreenshots()
    func setupContanerAsDisplayContentInScreenshots()
    
}

final class ScreenshotInvincibleContainer: UITextField {

    // MARK: - Private Properties

    private let hiddenContainerRecognizer = HiddenContainerRecognizer()
    private var container: UIView? {
        try? hiddenContainerRecognizer.getHiddenContainer(from: self)
    }

    // MARK: - Internal Properties

    /// - View, which will be hidden on screenshots and screen recording
    private(set) var content: UIView

    // MARK: - Initialization
    
    public init(content: UIView) {
        self.content = content
        super.init(frame: .zero)
        setupInitialState()
    }
    
    public required init?(coder: NSCoder) {
        self.content = UIView()
        super.init(coder: coder)
        setupInitialState()
    }

    // MARK: - UIView

    override var canBecomeFocused: Bool {
        false
    }

    override var canBecomeFirstResponder: Bool {
        false
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return container?.hitTest(point, with: event)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        isUserInteractionEnabled = content.isUserInteractionEnabled
    }
    
    // MARK: - Private methods
    
    private func setupInitialState() {
        appendContent(to: container)

        backgroundColor = .clear
        isUserInteractionEnabled = content.isUserInteractionEnabled
    }
    
    private func activateLayoutConstraintsOfContent(to view: UIView) {
        [
            content.topAnchor.constraint(equalTo: view.topAnchor),
            content.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.leftAnchor.constraint(equalTo: view.leftAnchor),
            content.rightAnchor.constraint(equalTo: view.rightAnchor)
        ].forEach { $0.isActive = true }
    }
    
    private func appendContent(to view: UIView?) {
        guard let view = view else {
            return
        }
        view.addSubview(content)
        view.isUserInteractionEnabled = true
        content.translatesAutoresizingMaskIntoConstraints = false
        activateLayoutConstraintsOfContent(to: view)
    }
    
}

// MARK: - ScreenshotInvincibleContainerProtocol

extension ScreenshotInvincibleContainer: ScreenshotInvincibleContainerProtocol {
    
    public func eraseOldAndAddnewContent(_ newContent: UIView) {
        content.removeFromSuperview()
        content = newContent
        appendContent(to: container)
    }
    
    public func setupContanerAsHideContentInScreenshots() {
        isSecureTextEntry = true
    }
    
    public func setupContanerAsDisplayContentInScreenshots() {
        isSecureTextEntry = false
    }
    
}

/// Recognize view, which can be hidden before system screenshot event did triggered, depend on `iOS version`
struct HiddenContainerRecognizer {

    // MARK: - Nested Types

    private enum Error: Swift.Error {
        case unsupportedIosVersion(version: Float)
        case desiredContainerWasNotFound(_ containerName: String)
    }

    // MARK: - Internal Methods

    func getHiddenContainer(from view: UIView) throws -> UIView {
        let containerName = try getHiddenContainerTypeInStringRepresentation()
        let containers = view.subviews.filter { subview in
            type(of: subview).description() == containerName
        }

        guard let container = containers.first else {
            throw Error.desiredContainerWasNotFound(containerName)
        }

        return container
    }

    func getHiddenContainerTypeInStringRepresentation() throws -> String {
        
        if #available(iOS 15, *) {
            return "_UITextLayoutCanvasView"
        }

        if #available(iOS 14, *) {
            return "_UITextFieldCanvasView"
        }

        if #available(iOS 13, *) {
            return "_UITextFieldCanvasView"
        }

        if #available(iOS 12, *) {
            return "_UITextFieldContentView"
        }

        let currentIOSVersion = (UIDevice.current.systemVersion as NSString).floatValue
        throw Error.unsupportedIosVersion(version: currentIOSVersion)
    }

    func viewIsAlreadyInHiddenContainer(_ view: UIView) -> Bool {
        guard
            let containerClassName = try? getHiddenContainerTypeInStringRepresentation(),
            let superViewInspectableView = view.superview
        else {
            return false
        }

        let typeOfClassContainer = type(of: superViewInspectableView)
        let stringRepresentationOfClassContainer = String(describing: typeOfClassContainer.self)

        return stringRepresentationOfClassContainer == containerClassName
    }

}

