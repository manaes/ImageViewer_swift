import UIKit

// Data holder tap recognizer
public class TapWithDataRecognizer: UITapGestureRecognizer {
  public weak var from: UIViewController?
  public var imageDatasource: ImageDataSource?
  public var imageLoader: ImageLoader?
  public var initialIndex: Int = 0
  public var options: [ImageViewerOption] = []
}

public extension UIImageView {
  private var vc: UIViewController? {
    let keyWindow = UIApplication.shared.windows.first(where: \.isKeyWindow)
    guard let rootVC = keyWindow?.rootViewController
    else { return nil }
    return rootVC.presentedViewController != nil ? rootVC.presentedViewController : rootVC
  }

  func setupImageViewer(
    options: [ImageViewerOption] = [],
    from: UIViewController? = nil,
    imageLoader: ImageLoader? = nil
  ) {
    setup(
      datasource: SimpleImageDatasource(imageItems: [.image(image)]),
      options: options,
      from: from,
      imageLoader: imageLoader
    )
  }

  func setupImageViewer(
    url: URL,
    initialIndex: Int = 0,
    placeholder: UIImage? = nil,
    options: [ImageViewerOption] = [],
    from: UIViewController? = nil,
    imageLoader: ImageLoader? = nil
  ) {
    let datasource = SimpleImageDatasource(
      imageItems: [url].compactMap {
        ImageItem.url($0, placeholder: placeholder)
      })
    setup(
      datasource: datasource,
      initialIndex: initialIndex,
      options: options,
      from: from,
      imageLoader: imageLoader
    )
  }

  func setupImageViewer(
    images: [UIImage],
    initialIndex: Int = 0,
    options: [ImageViewerOption] = [],
    from: UIViewController? = nil,
    imageLoader: ImageLoader? = nil
  ) {
    let datasource = SimpleImageDatasource(
      imageItems: images.compactMap {
        ImageItem.image($0)
      })
    setup(
      datasource: datasource,
      initialIndex: initialIndex,
      options: options,
      from: from,
      imageLoader: imageLoader
    )
  }

  func setupImageViewer(
    urls: [URL],
    initialIndex: Int = 0,
    options: [ImageViewerOption] = [],
    placeholder: UIImage? = nil,
    from: UIViewController? = nil,
    imageLoader: ImageLoader? = nil
  ) {
    let datasource = SimpleImageDatasource(
      imageItems: urls.compactMap {
        ImageItem.url($0, placeholder: placeholder)
      })
    setup(
      datasource: datasource,
      initialIndex: initialIndex,
      options: options,
      from: from,
      imageLoader: imageLoader
    )
  }

  func setupImageViewer(
    datasource: ImageDataSource,
    initialIndex: Int = 0,
    options: [ImageViewerOption] = [],
    from: UIViewController? = nil,
    imageLoader: ImageLoader? = nil
  ) {
    setup(
      datasource: datasource,
      initialIndex: initialIndex,
      options: options,
      from: from,
      imageLoader: imageLoader
    )
  }

  private func setup(
    datasource: ImageDataSource?,
    initialIndex: Int = 0,
    options: [ImageViewerOption] = [],
    from: UIViewController? = nil,
    imageLoader: ImageLoader? = nil
  ) {
    var _tapRecognizer: TapWithDataRecognizer?
    gestureRecognizers?.forEach {
      if let _tr = $0 as? TapWithDataRecognizer {
        // if found, just use existing
        _tapRecognizer = _tr
      }
    }

    isUserInteractionEnabled = true

    var imageContentMode: UIView.ContentMode = .scaleAspectFill
    for option in options {
      switch option {
      case let .contentMode(contentMode):
        imageContentMode = contentMode
      default:
        break
      }
    }
    contentMode = imageContentMode

    clipsToBounds = true

    if _tapRecognizer == nil {
      _tapRecognizer = TapWithDataRecognizer(
        target: self, action: #selector(showImageViewer(_:))
      )
      _tapRecognizer?.numberOfTouchesRequired = 1
      _tapRecognizer?.numberOfTapsRequired = 1
    }
    // Pass the Data
    _tapRecognizer?.imageDatasource = datasource
    _tapRecognizer?.imageLoader = imageLoader
    _tapRecognizer?.initialIndex = initialIndex
    _tapRecognizer?.options = options
    _tapRecognizer?.from = from

    if let tapRecognizer = _tapRecognizer {
      addGestureRecognizer(tapRecognizer)
    }
  }

  @objc
  private func showImageViewer(_ sender: TapWithDataRecognizer) {
    guard let sourceView = sender.view as? UIImageView else { return }
    let imageCarousel = ImageCarouselViewController(
      sourceView: sourceView,
      imageDataSource: sender.imageDatasource,
      imageLoader: sender.imageLoader ?? URLSessionImageLoader(),
      options: sender.options,
      initialIndex: sender.initialIndex
    )
    let presentFromVC = sender.from ?? vc
    presentFromVC?.present(imageCarousel, animated: true)
  }
}
