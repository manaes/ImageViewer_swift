import UIKit

public protocol ImageDataSource: AnyObject {
  func numberOfImages() -> Int
  func imageItem(at index: Int) -> ImageItem
}

public class ImageCarouselViewController: UIPageViewController, ImageTransitionViewControllerConvertible {
  unowned var initialSourceView: UIImageView?
  var sourceView: UIImageView? {
    guard let vc = viewControllers?.first as? ImageViewerSwiftController else {
      return nil
    }
    return initialIndex == vc.index ? initialSourceView : nil
  }

  var targetView: UIImageView? {
    guard let vc = viewControllers?.first as? ImageViewerSwiftController else {
      return nil
    }
    return vc.imageView
  }

  weak var imageDatasource: ImageDataSource?
  let imageLoader: ImageLoader

  var initialIndex = 0

  var theme: ImageViewerTheme = .light {
    didSet {
      navItem.leftBarButtonItem?.tintColor = theme.tintColor
      backgroundView?.backgroundColor = theme.color
    }
  }

  var imageContentMode: UIView.ContentMode = .scaleAspectFill
  var options: [ImageViewerOption] = []

  private var onRightNavBarTapped: ((Int) -> Void)?

  private(set) lazy var navBar: UINavigationBar = {
    let _navBar = UINavigationBar(frame: .zero)
    _navBar.isTranslucent = true
    _navBar.setBackgroundImage(UIImage(), for: .default)
    _navBar.shadowImage = UIImage()
    return _navBar
  }()

  private(set) lazy var backgroundView: UIView? = {
    let view = UIView()
    view.backgroundColor = theme.color
    view.alpha = 1.0
    return view
  }()

  private(set) lazy var navItem = UINavigationItem()

  private let imageViewerPresentationDelegate: ImageTransitionPresentationManager

  public init(
    sourceView: UIImageView,
    imageDataSource: ImageDataSource?,
    imageLoader: ImageLoader,
    options: [ImageViewerOption] = [],
    initialIndex: Int = 0
  ) {
    initialSourceView = sourceView
    self.initialIndex = initialIndex
    self.options = options
    imageDatasource = imageDataSource
    self.imageLoader = imageLoader
    let pageOptions = [UIPageViewController.OptionsKey.interPageSpacing: 20]

    var _imageContentMode = imageContentMode
    for option in options {
      switch option {
      case let .contentMode(contentMode):
        _imageContentMode = contentMode
      default:
        break
      }
    }
    imageContentMode = _imageContentMode

    imageViewerPresentationDelegate = ImageTransitionPresentationManager(imageContentMode: imageContentMode)
    super.init(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: pageOptions
    )

    transitioningDelegate = imageViewerPresentationDelegate
    modalPresentationStyle = .custom
    modalPresentationCapturesStatusBarAppearance = true
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder: ) has not been implemented")
  }

  private func addCloseBtn() {
    let closeBtn = UIButton(frame: .zero)
    closeBtn.addTarget(self, action: #selector(dismiss(_:)), for: .touchUpInside)
    closeBtn.setImage(.iconOptionClose, for: .normal)
    closeBtn.tintColor = .gray900
    closeBtn.accessibilityIdentifier = "closeBtn"
    view.addSubview(closeBtn)

    closeBtn.translatesAutoresizingMaskIntoConstraints = false
    let leadingConstraint = NSLayoutConstraint(item: closeBtn, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: -12)
    let topConstraint = NSLayoutConstraint(item: closeBtn, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 63)
    let widthConstraint = NSLayoutConstraint(item: closeBtn, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 40)
    let heightConstraint = NSLayoutConstraint(item: closeBtn, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 40)
    view.addConstraints([leadingConstraint, topConstraint, widthConstraint, heightConstraint])
  }

  private func addBackgroundView() {
    guard let backgroundView else { return }
    view.addSubview(backgroundView)
    backgroundView.bindFrameToSuperview()
    view.sendSubviewToBack(backgroundView)
  }

  private func applyOptions() {
    for option in options {
      switch option {
      case let .theme(theme):
        self.theme = theme

      case let .contentMode(contentMode):
        imageContentMode = contentMode

      case let .closeIcon(icon):
        navItem.leftBarButtonItem?.image = icon

      case let .rightNavItemTitle(title, onTap):
        navItem.rightBarButtonItem = UIBarButtonItem(
          title: title,
          style: .plain,
          target: self,
          action: #selector(diTapRightNavBarItem(_:))
        )
        onRightNavBarTapped = onTap

      case let .rightNavItemIcon(icon, onTap):
        navItem.rightBarButtonItem = UIBarButtonItem(
          image: icon,
          style: .plain,
          target: self,
          action: #selector(diTapRightNavBarItem(_:))
        )
        onRightNavBarTapped = onTap
      }
    }
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    addBackgroundView()
    addCloseBtn()
    applyOptions()

    dataSource = self

    if let imageDatasource {
      let initialVC: ImageViewerSwiftController = .init(
        index: initialIndex,
        imageItem: imageDatasource.imageItem(at: initialIndex),
        imageLoader: imageLoader
      )
      setViewControllers([initialVC], direction: .forward, animated: true)
    }
  }

  @objc
  private func dismiss(_: UIBarButtonItem) {
    dismiss(animated: true, completion: nil)
  }

  deinit {
    initialSourceView?.alpha = 1.0
  }

  @objc
  func diTapRightNavBarItem(_: UIBarButtonItem) {
    guard
      let onTap = onRightNavBarTapped,
      let _firstVC = viewControllers?.first as? ImageViewerSwiftController
    else { return }
    onTap(_firstVC.index)
  }

  override public var preferredStatusBarStyle: UIStatusBarStyle {
    if theme == .dark {
      return .lightContent
    }
    return .default
  }
}

extension ImageCarouselViewController: UIPageViewControllerDataSource {
  public func pageViewController(
    _: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard let vc = viewController as? ImageViewerSwiftController else { return nil }
    guard let imageDatasource else { return nil }
    guard vc.index > 0 else { return nil }

    let newIndex = vc.index - 1
    return ImageViewerSwiftController(
      index: newIndex,
      imageItem: imageDatasource.imageItem(at: newIndex),
      imageLoader: vc.imageLoader
    )
  }

  public func pageViewController(
    _: UIPageViewController,
    viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    guard let vc = viewController as? ImageViewerSwiftController else { return nil }
    guard let imageDatasource else { return nil }
    guard vc.index <= (imageDatasource.numberOfImages() - 2) else { return nil }

    let newIndex = vc.index + 1
    return ImageViewerSwiftController(
      index: newIndex,
      imageItem: imageDatasource.imageItem(at: newIndex),
      imageLoader: vc.imageLoader
    )
  }
}
