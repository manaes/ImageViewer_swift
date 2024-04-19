import Foundation

public class SimpleImageDatasource: ImageDataSource {
  private(set) var imageItems: [ImageItem]

  public init(imageItems: [ImageItem]) {
    self.imageItems = imageItems
  }

  public func numberOfImages() -> Int {
    imageItems.count
  }

  public func imageItem(at index: Int) -> ImageItem {
    imageItems[index]
  }
}
