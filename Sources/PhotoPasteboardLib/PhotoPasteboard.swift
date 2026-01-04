import Cocoa
import Photos

// Photo information including image and metadata
public struct PhotoInfo {
  public let image: NSImage
  public let creationDate: Date?
  public let pixelWidth: Int
  public let pixelHeight: Int

  public init(image: NSImage, creationDate: Date?, pixelWidth: Int, pixelHeight: Int) {
    self.image = image
    self.creationDate = creationDate
    self.pixelWidth = pixelWidth
    self.pixelHeight = pixelHeight
  }
}

// Request Photos library access
public func requestPhotosAccess() async -> Bool {
  let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

  if status == .authorized {
    return true
  }

  let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
  return newStatus == .authorized
}

// Main function: Get full-resolution photos from pasteboard
// Returns array of NSImages if Photos.app photos are on the pasteboard, nil otherwise
public func getPhotosFromPasteboard() async -> [NSImage]? {
  // Request Photos library access
  guard await requestPhotosAccess() else {
    return nil
  }

  // Read pasteboard
  let pasteboard = NSPasteboard.general

  // Get all temp file URLs that Photos.app puts on the pasteboard
  guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
    !urls.isEmpty
  else {
    return nil
  }

  // Extract UUIDs from all filenames
  let uuidPattern = "([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})"
  guard let regex = try? NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive) else {
    return nil
  }

  var uuids: [String] = []
  for url in urls {
    let filename = url.lastPathComponent
    let nsString = filename as NSString
    if let match = regex.firstMatch(
      in: filename, range: NSRange(location: 0, length: nsString.length))
    {
      let uuid = nsString.substring(with: match.range(at: 1))
      uuids.append(uuid)
    }
  }

  guard !uuids.isEmpty else {
    return nil
  }

  // Fetch all assets from Photos library
  let fetchOptions = PHFetchOptions()
  let results = PHAsset.fetchAssets(withLocalIdentifiers: uuids, options: fetchOptions)

  guard results.count > 0 else {
    return nil
  }

  // Request full-resolution image data for all assets
  let imageManager = PHImageManager.default()
  let options = PHImageRequestOptions()
  options.isSynchronous = true
  options.deliveryMode = .highQualityFormat
  options.isNetworkAccessAllowed = true

  var images: [NSImage] = []

  results.enumerateObjects { asset, _, _ in
    imageManager.requestImageDataAndOrientation(for: asset, options: options) {
      data, uti, orientation, info in
      if let data = data, let image = NSImage(data: data) {
        images.append(image)
      }
    }
  }

  return images.isEmpty ? nil : images
}

// Get full-resolution photos with metadata from pasteboard
// Returns array of PhotoInfo if Photos.app photos are on the pasteboard, nil otherwise
public func getPhotosWithMetadataFromPasteboard() async -> [PhotoInfo]? {
  // Request Photos library access
  guard await requestPhotosAccess() else {
    return nil
  }

  // Read pasteboard
  let pasteboard = NSPasteboard.general

  // Get all temp file URLs that Photos.app puts on the pasteboard
  guard let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
    !urls.isEmpty
  else {
    return nil
  }

  // Extract UUIDs from all filenames
  let uuidPattern = "([0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12})"
  guard let regex = try? NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive) else {
    return nil
  }

  var uuids: [String] = []
  for url in urls {
    let filename = url.lastPathComponent
    let nsString = filename as NSString
    if let match = regex.firstMatch(
      in: filename, range: NSRange(location: 0, length: nsString.length))
    {
      let uuid = nsString.substring(with: match.range(at: 1))
      uuids.append(uuid)
    }
  }

  guard !uuids.isEmpty else {
    return nil
  }

  // Fetch all assets from Photos library
  let fetchOptions = PHFetchOptions()
  let results = PHAsset.fetchAssets(withLocalIdentifiers: uuids, options: fetchOptions)

  guard results.count > 0 else {
    return nil
  }

  // Request full-resolution image data for all assets
  let imageManager = PHImageManager.default()
  let options = PHImageRequestOptions()
  options.isSynchronous = true
  options.deliveryMode = .highQualityFormat
  options.isNetworkAccessAllowed = true

  var photoInfos: [PhotoInfo] = []

  results.enumerateObjects { asset, _, _ in
    imageManager.requestImageDataAndOrientation(for: asset, options: options) {
      data, uti, orientation, info in
      if let data = data, let image = NSImage(data: data) {
        let photoInfo = PhotoInfo(
          image: image,
          creationDate: asset.creationDate,
          pixelWidth: asset.pixelWidth,
          pixelHeight: asset.pixelHeight
        )
        photoInfos.append(photoInfo)
      }
    }
  }

  return photoInfos.isEmpty ? nil : photoInfos
}

// Resize an image to a maximum width while maintaining aspect ratio
// If the image is smaller than maxWidth, returns the original image
public func resizeImage(_ image: NSImage, maxWidth: CGFloat = 1600) -> NSImage {
  let originalSize = image.size

  if originalSize.width <= maxWidth {
    return image
  }

  let ratio = maxWidth / originalSize.width
  let newHeight = originalSize.height * ratio
  let newSize = NSSize(width: maxWidth, height: newHeight)

  guard
    let bitmapRep = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: Int(newSize.width),
      pixelsHigh: Int(newSize.height),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    )
  else {
    return image
  }

  bitmapRep.size = newSize

  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
  NSGraphicsContext.current?.imageInterpolation = .high

  image.draw(
    in: NSRect(origin: .zero, size: newSize),
    from: NSRect(origin: .zero, size: originalSize),
    operation: .copy,
    fraction: 1.0
  )

  NSGraphicsContext.restoreGraphicsState()

  let resizedImage = NSImage(size: newSize)
  resizedImage.addRepresentation(bitmapRep)

  return resizedImage
}

// Save an image as optimized JPEG to a file path
// Returns true if successful, false otherwise
public func saveImageAsJPEG(_ image: NSImage, to url: URL, quality: CGFloat = 0.85) -> Bool {
  guard let tiffData = image.tiffRepresentation,
    let bitmapImage = NSBitmapImageRep(data: tiffData),
    let jpegData = bitmapImage.representation(
      using: .jpeg, properties: [.compressionFactor: quality])
  else {
    return false
  }

  // Optimize with jpegoptim via stdin/stdout
  guard let optimizedData = optimizeJPEGData(jpegData) else {
    print("❌ Failed to optimize JPEG - not saving")
    return false
  }

  do {
    try optimizedData.write(to: url)
    return true
  } catch {
    print("❌ Failed to write optimized JPEG: \(error)")
    return false
  }
}

// Find jpegoptim in PATH
public func findJpegoptim() -> String? {
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
  process.arguments = ["jpegoptim"]

  let pipe = Pipe()
  process.standardOutput = pipe
  process.standardError = Pipe()

  do {
    try process.run()
    process.waitUntilExit()

    if process.terminationStatus == 0 {
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(
        in: .whitespacesAndNewlines),
        !path.isEmpty
      {
        return path
      }
    }
  } catch {
    // Silently fail
  }

  return nil
}

// Optimize JPEG data using jpegoptim
// Returns optimized data or nil if optimization fails
private func optimizeJPEGData(_ jpegData: Data) -> Data? {
  // Find jpegoptim executable
  guard let jpegoptimPath = findJpegoptim() else {
    print("⚠️  jpegoptim not found in PATH. Please install jpegoptim for better compression.")
    print("   Install with: brew install jpegoptim")
    return nil
  }

  let process = Process()
  process.executableURL = URL(fileURLWithPath: jpegoptimPath)

  // jpegoptim arguments:
  // --stdin = read from stdin
  // --stdout = write to stdout
  // --strip-all = remove all metadata
  // -m75 = maximum quality 70%
  process.arguments = ["--stdin", "--stdout", "--strip-all", "-m70"]

  let inputPipe = Pipe()
  let outputPipe = Pipe()
  let errorPipe = Pipe()

  process.standardInput = inputPipe
  process.standardOutput = outputPipe
  process.standardError = errorPipe

  do {
    try process.run()

    // Write JPEG data to stdin
    inputPipe.fileHandleForWriting.write(jpegData)
    try inputPipe.fileHandleForWriting.close()

    // Read optimized data from stdout
    let optimizedData = outputPipe.fileHandleForReading.readDataToEndOfFile()

    process.waitUntilExit()

    if process.terminationStatus == 0 && !optimizedData.isEmpty {
      return optimizedData
    } else {
      let errorOutput = String(
        data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
      print("jpegoptim failed: \(errorOutput ?? "unknown error")")
      return nil
    }
  } catch {
    print("Failed to run jpegoptim: \(error)")
    return nil
  }
}
