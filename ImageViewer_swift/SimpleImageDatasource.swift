class SimpleImageDatasource: ImageDataSource {
  private(set) var imageItems: [ImageItem]

  init(imageItems: [ImageItem]) {
    self.imageItems = imageItems
  }

  func numberOfImages() -> Int {
    imageItems.count
  }

  func imageItem(at index: Int) -> ImageItem {
    imageItems[index]
  }
}
