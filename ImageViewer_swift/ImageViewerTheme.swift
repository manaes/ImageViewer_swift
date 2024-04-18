import UIKit

public enum ImageViewerTheme {
  case light
  case dark

  var color: UIColor {
    .backgroundBase
  }

  var tintColor: UIColor {
    .gray800
  }
}
